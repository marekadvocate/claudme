import Foundation
import Network

struct HookEvent {
    let name: String            // Stop, SessionStart, SessionEnd, Notification, UserPromptSubmit…
    let sessionId: String
    let payload: [String: Any]
}

/// Tiny loopback HTTP listener. Claude Code hooks POST their stdin JSON here via curl.
final class HookServer {
    static let defaultPort: UInt16 = 48291
    /// hook payloads are small; anything larger is a mistake or an attack
    static let maxBodyBytes = 4 << 20

    var onEvent: ((HookEvent) -> Void)?   // delivered on main thread
    /// Renders the overlay to a PNG. Only reachable when CLAUDME_DEBUG=1, so a normal
    /// install exposes nothing but the hook endpoint.
    var onSnapshot: (() -> Void)?
    var onEffect: ((String) -> Void)?

    private static var debugEnabled: Bool {
        ProcessInfo.processInfo.environment["CLAUDME_DEBUG"] == "1"
    }

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "claudme.hooks")

    func start() {
        guard listener == nil else { return }      // never bind twice
        startListener(fixed: true)
    }

    private func startListener(fixed: Bool) {
        let port: NWEndpoint.Port = fixed ? NWEndpoint.Port(rawValue: Self.defaultPort)! : .any
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: port)

        guard let l = try? NWListener(using: params) else {
            NSLog("Claudme: cannot create listener")
            return
        }
        listener?.cancel()                         // never leak the previous one
        listener = l
        l.newConnectionHandler = { [weak self] conn in self?.handle(conn) }
        l.stateUpdateHandler = { [weak self, weak l] state in
            guard let self else { return }
            switch state {
            case .ready:
                // read this listener's own port: self.listener may already point elsewhere,
                // and an unresolved .any port reports 0, which would be written to the file
                if let p = l?.port?.rawValue, p != 0 {
                    Self.writePortFile(p)
                    NSLog("Claudme: hook server on 127.0.0.1:\(p)")
                }
            case .failed(let error):
                NSLog("Claudme: listener failed: \(error)")
                self.listener?.cancel()
                if fixed { self.startListener(fixed: false) }
            default:
                break
            }
        }
        l.start(queue: queue)
    }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: queue)
        // a peer that opens a socket and never finishes a request would otherwise be
        // held until the app quits
        queue.asyncAfter(deadline: .now() + 5) { [weak conn] in conn?.cancel() }
        readRequest(conn, buffer: Data())
    }

    private func readRequest(_ conn: NWConnection, buffer: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 1 << 20) { [weak self] data, _, isComplete, error in
            guard let self else { conn.cancel(); return }
            var buf = buffer
            if let data { buf.append(data) }
            if buf.count > Self.maxBodyBytes + 65536 { conn.cancel(); return }
            if let request = Self.completeRequest(in: buf) {
                self.respond(conn)
                if request.head.hasPrefix("GET /snapshot") {
                    if Self.debugEnabled {
                        DispatchQueue.main.async { [weak self] in self?.onSnapshot?() }
                    }
                } else if request.head.hasPrefix("GET /effect/") {
                    // debug only: same entry point the Playground menu uses, so testing
                    // it from outside exercises the real code path
                    if Self.debugEnabled,
                       let line = request.head.components(separatedBy: "\r\n").first,
                       let path = line.components(separatedBy: " ").dropFirst().first {
                        let name = String(path.dropFirst("/effect/".count))
                            .components(separatedBy: "?").first ?? ""
                        DispatchQueue.main.async { [weak self] in self?.onEffect?(name) }
                    }
                } else {
                    self.dispatch(request.body, head: request.head)
                }
            } else if isComplete || error != nil {
                conn.cancel()
            } else {
                self.readRequest(conn, buffer: buf)
            }
        }
    }

    private func respond(_ conn: NWConnection) {
        let response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok"
        conn.send(content: Data(response.utf8), completion: .contentProcessed { _ in
            conn.cancel()
        })
    }

    /// Returns head+body once the buffered request is complete, nil if more bytes are needed.
    private static func completeRequest(in data: Data) -> (head: String, body: Data)? {
        guard let headerRange = data.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        guard let head = String(data: data.subdata(in: 0..<headerRange.lowerBound), encoding: .utf8)
        else { return nil }

        // Content-Length is attacker-controlled: this listener is unauthenticated and on a
        // known port, so a negative or absurd value must be rejected, not trusted. A
        // negative one used to build a reversed Range and trap the whole app.
        var contentLength = 0
        for line in head.components(separatedBy: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2,
                  parts[0].trimmingCharacters(in: .whitespaces).lowercased() == "content-length"
            else { continue }
            guard let n = Int(parts[1].trimmingCharacters(in: .whitespaces)),
                  n >= 0, n <= maxBodyBytes
            else { return nil }          // malformed length: refuse the request outright
            contentLength = n
        }
        let bodyStart = headerRange.upperBound
        guard data.count - bodyStart >= contentLength else { return nil }
        return (head, data.subdata(in: bodyStart..<(bodyStart + contentLength)))
    }

    private func dispatch(_ body: Data, head: String) {
        guard !body.isEmpty,
              var obj = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
              let name = obj["hook_event_name"] as? String
        else { return }
        // the hook command forwards the session's env as headers (remote detection)
        var remoteValue = ""
        var bridgeValue = ""
        for line in head.components(separatedBy: "\r\n") {
            let lower = line.lowercased()
            if lower.hasPrefix("x-cc-remote:") {
                remoteValue = String(line.dropFirst("x-cc-remote:".count)).trimmingCharacters(in: .whitespaces)
            } else if lower.hasPrefix("x-cc-bridge:") {
                bridgeValue = String(line.dropFirst("x-cc-bridge:".count)).trimmingCharacters(in: .whitespaces)
            }
        }
        obj["_remote"] = (remoteValue.lowercased() == "true") || !bridgeValue.isEmpty
        let event = HookEvent(
            name: name,
            sessionId: obj["session_id"] as? String ?? "",
            payload: obj
        )
        DispatchQueue.main.async { [weak self] in self?.onEvent?(event) }
    }

    private static func writePortFile(_ port: UInt16) {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Claudme", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? Data(String(port).utf8).write(to: dir.appendingPathComponent("port"))
    }
}
