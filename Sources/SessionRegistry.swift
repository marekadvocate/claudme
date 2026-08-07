import Foundation

struct SessionInfo: Equatable {
    let pid: Int32
    let sessionId: String
    let name: String
    let cwd: String
    let status: String        // observed: idle | busy | waiting (defensive: anything)
    let updatedAt: Double     // ms since epoch
    let statusUpdatedAt: Double
    let startedAt: Double     // ms since epoch — drives the crab's rank
    let model: String?        // e.g. claude-fable-5, read from the transcript tail

    /// how long this session has been alive, in seconds
    var ageSeconds: Double {
        guard startedAt > 0 else { return 0 }
        return max(0, Date().timeIntervalSince1970 - startedAt / 1000)
    }
}

/// Polls Claude Code's own per-session registry: ~/.claude/sessions/<pid>.json
final class SessionRegistry {
    var onChange: (([SessionInfo]) -> Void)?   // delivered on main thread

    private let queue = DispatchQueue(label: "claudme.registry", qos: .utility)
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
                if let session = parse(file) {
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

    private func parse(_ url: URL) -> SessionInfo? {
        // Claude Code itself only treats ^\d+\.json$ as session records
        guard let pidFromName = Int32(url.deletingPathExtension().lastPathComponent),
              let data = try? Data(contentsOf: url),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else { return nil }

        let pid = (obj["pid"] as? NSNumber)?.int32Value ?? pidFromName
        guard Self.alive(pid) else { return nil }

        // kill(pid, 0) only says "some process has this id". PIDs get recycled, so a stale
        // session file whose number has been handed to an unrelated process would keep
        // resurrecting a crab for a session that ended days ago. A live session rewrites
        // its file constantly; treat a long-untouched one as gone.
        let updated = (obj["updatedAt"] as? NSNumber)?.doubleValue ?? 0
        if updated > 0 {
            let ageSeconds = Date().timeIntervalSince1970 - updated / 1000
            guard ageSeconds < 48 * 3600 else { return nil }
        }

        let cwd = obj["cwd"] as? String ?? ""
        let fallbackName = cwd.isEmpty ? "claude-\(pid)" : URL(fileURLWithPath: cwd).lastPathComponent
        let name = (obj["name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? fallbackName
        let sessionId = obj["sessionId"] as? String ?? "pid-\(pid)"

        return SessionInfo(
            pid: pid,
            sessionId: sessionId,
            name: name,
            cwd: cwd,
            status: ((obj["status"] as? String) ?? "idle").lowercased(),
            updatedAt: (obj["updatedAt"] as? NSNumber)?.doubleValue ?? 0,
            statusUpdatedAt: (obj["statusUpdatedAt"] as? NSNumber)?.doubleValue ?? 0,
            startedAt: (obj["startedAt"] as? NSNumber)?.doubleValue ?? 0,
            model: transcriptModel(cwd: cwd, sessionId: sessionId)
        )
    }

    // MARK: - Model detection from the transcript tail (cached by file stamp)

    private var modelCache: [String: (stamp: String, model: String?)] = [:]

    private func transcriptModel(cwd: String, sessionId: String) -> String? {
        guard !cwd.isEmpty else { return nil }
        // Claude Code replaces every character outside [A-Za-z0-9] with "-", not just the
        // separators, so a project directory containing a dot or a space had no transcript
        // path at all and silently lost its model detection.
        let munged = String(cwd.map { $0.isLetter || $0.isNumber ? $0 : "-" })
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects/\(munged)/\(sessionId).jsonl")
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = (attrs[.size] as? NSNumber)?.uint64Value else { return nil }
        let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
        let stamp = "\(size)-\(mtime)"
        if let cached = modelCache[sessionId], cached.stamp == stamp { return cached.model }

        // Grepping for the last `"model":"` was wrong: transcripts also contain that string
        // in <synthetic> records, subagent-spawn entries and even MCP tool arguments, so the
        // crab's surname would flip to the fallback mid-session. Parse real records instead.
        var model: String?
        for window in [UInt64(65536), 262144, 1 << 20] where model == nil {
            guard let fh = try? FileHandle(forReadingFrom: url) else { break }
            defer { try? fh.close() }
            if size > window { try? fh.seek(toOffset: size - window) }
            guard let data = try? fh.readToEnd() else { break }
            model = Self.lastAssistantModel(in: String(decoding: data, as: UTF8.self))
            if window >= size { break }          // already read the whole file
        }

        // Never let a transient miss downgrade a name we already resolved.
        if model == nil, let previous = modelCache[sessionId]?.model { model = previous }
        modelCache[sessionId] = (stamp, model)
        return model
    }

    /// Walks JSONL backwards and returns the model of the newest genuine assistant record.
    private static func lastAssistantModel(in text: String) -> String? {
        for line in text.split(separator: "\n", omittingEmptySubsequences: true).reversed() {
            guard line.first == "{",
                  let obj = (try? JSONSerialization.jsonObject(with: Data(line.utf8))) as? [String: Any],
                  obj["type"] as? String == "assistant",
                  let message = obj["message"] as? [String: Any],
                  let name = message["model"] as? String,
                  name.hasPrefix("claude-")      // rejects <synthetic> and tool arguments
            else { continue }
            return name
        }
        return nil
    }

    private static func alive(_ pid: Int32) -> Bool {
        guard pid > 0 else { return false }
        if kill(pid, 0) == 0 { return true }
        return errno == EPERM
    }
}
