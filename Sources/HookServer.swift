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

    var onEvent: ((HookEvent) -> Void)?   // delivered on main thread
    var onSnapshot: (() -> Void)?         // debug: GET /snapshot renders overlay to PNG
    var onBeer: (() -> Void)?             // debug: GET /beer → random crab has a beer
    var onTrick: (() -> Void)?            // debug: GET /trick → random crab balloon ride

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "claudepet.hooks")

    func start() {
        startListener(fixed: true)
    }

    private func startListener(fixed: Bool) {
        let port: NWEndpoint.Port = fixed ? NWEndpoint.Port(rawValue: Self.defaultPort)! : .any
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: port)

        guard let l = try? NWListener(using: params) else {
            NSLog("ClaudePet: cannot create listener")
            return
        }
        listener = l
        l.newConnectionHandler = { [weak self] conn in self?.handle(conn) }
        l.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                if let p = self.listener?.port?.rawValue {
                    Self.writePortFile(p)
                    NSLog("ClaudePet: hook server on 127.0.0.1:\(p)")
                }
            case .failed(let error):
                NSLog("ClaudePet: listener failed: \(error)")
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
        readRequest(conn, buffer: Data())
    }

    private func readRequest(_ conn: NWConnection, buffer: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 1 << 20) { [weak self] data, _, isComplete, error in
            guard let self else { conn.cancel(); return }
            var buf = buffer
            if let data { buf.append(data) }
            if buf.count > (8 << 20) { conn.cancel(); return }
            if let request = Self.completeRequest(in: buf) {
                self.respond(conn)
                if request.head.hasPrefix("GET /snapshot") {
                    DispatchQueue.main.async { [weak self] in self?.onSnapshot?() }
                } else if request.head.hasPrefix("GET /beer") {
                    DispatchQueue.main.async { [weak self] in self?.onBeer?() }
                } else if request.head.hasPrefix("GET /trick") {
                    DispatchQueue.main.async { [weak self] in self?.onTrick?() }
                } else {
                    self.dispatch(request.body)
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

        var contentLength = 0
        for line in head.components(separatedBy: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2,
               parts[0].trimmingCharacters(in: .whitespaces).lowercased() == "content-length" {
                contentLength = Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0
            }
        }
        let bodyStart = headerRange.upperBound
        guard data.count - bodyStart >= contentLength else { return nil }
        return (head, data.subdata(in: bodyStart..<(bodyStart + contentLength)))
    }

    private func dispatch(_ body: Data) {
        guard !body.isEmpty,
              let obj = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
              let name = obj["hook_event_name"] as? String
        else { return }
        let event = HookEvent(
            name: name,
            sessionId: obj["session_id"] as? String ?? "",
            payload: obj
        )
        DispatchQueue.main.async { [weak self] in self?.onEvent?(event) }
    }

    private static func writePortFile(_ port: UInt16) {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClaudePet", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? Data(String(port).utf8).write(to: dir.appendingPathComponent("port"))
    }
}
