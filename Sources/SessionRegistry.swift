import Foundation

struct SessionInfo: Equatable {
    let pid: Int32
    let sessionId: String
    let name: String
    let cwd: String
    let status: String        // observed: idle | busy | waiting (defensive: anything)
    let updatedAt: Double     // ms since epoch
    let statusUpdatedAt: Double
}

/// Polls Claude Code's own per-session registry: ~/.claude/sessions/<pid>.json
final class SessionRegistry {
    var onChange: (([SessionInfo]) -> Void)?   // delivered on main thread

    private let queue = DispatchQueue(label: "claudepet.registry", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var last: [SessionInfo]?

    private var dir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/sessions", isDirectory: true)
    }

    func start() {
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + 0.1, repeating: 1.0)
        t.setEventHandler { [weak self] in self?.poll() }
        t.resume()
        timer = t
    }

    func pollNow() {
        queue.async { [weak self] in self?.poll() }
    }

    private func poll() {
        var result: [SessionInfo] = []
        if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "json" {
                if let session = Self.parse(file) {
                    result.append(session)
                }
            }
        }
        result.sort { $0.pid < $1.pid }
        if result != last {
            last = result
            let snapshot = result
            DispatchQueue.main.async { [weak self] in self?.onChange?(snapshot) }
        }
    }

    private static func parse(_ url: URL) -> SessionInfo? {
        // Claude Code itself only treats ^\d+\.json$ as session records
        guard let pidFromName = Int32(url.deletingPathExtension().lastPathComponent),
              let data = try? Data(contentsOf: url),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else { return nil }

        let pid = (obj["pid"] as? NSNumber)?.int32Value ?? pidFromName
        guard alive(pid) else { return nil }

        let cwd = obj["cwd"] as? String ?? ""
        let fallbackName = cwd.isEmpty ? "claude-\(pid)" : URL(fileURLWithPath: cwd).lastPathComponent
        let name = (obj["name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? fallbackName

        return SessionInfo(
            pid: pid,
            sessionId: obj["sessionId"] as? String ?? "pid-\(pid)",
            name: name,
            cwd: cwd,
            status: ((obj["status"] as? String) ?? "idle").lowercased(),
            updatedAt: (obj["updatedAt"] as? NSNumber)?.doubleValue ?? 0,
            statusUpdatedAt: (obj["statusUpdatedAt"] as? NSNumber)?.doubleValue ?? 0
        )
    }

    private static func alive(_ pid: Int32) -> Bool {
        guard pid > 0 else { return false }
        if kill(pid, 0) == 0 { return true }
        return errno == EPERM
    }
}
