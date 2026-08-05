import Foundation

enum HooksInstallerError: Error, CustomStringConvertible {
    case malformedSettings
    var description: String { "~/.claude/settings.json is not valid JSON — refusing to touch it" }
}

/// Merges/removes Claudme command hooks in ~/.claude/settings.json.
/// Recognizes its own entries by the "Claudme" marker in the command string.
enum HooksInstaller {
    static let events = ["SessionStart", "UserPromptSubmit", "Stop", "Notification", "SessionEnd",
                         "SubagentStart", "SubagentStop", "StopFailure", "PreCompact", "PostCompact"]
    static let marker = "Claudme"
    /// pre-rename marker, still recognised so an upgrade cleans up after itself
    static let legacyMarker = "ClaudePet"

    static var settingsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/settings.json")
    }
    static var backupURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/settings.json.bak-claudme")
    }

    // Posts the hook's stdin JSON to the app; always exits 0 so it can never block Claude.
    // "$(" is literal in Swift strings (only "\(" interpolates).
    static var hookCommand: String {
        "PF=\"$HOME/Library/Application Support/Claudme/port\"; curl -s -m 2 -H 'Expect:' -H \"X-CC-Remote: ${CLAUDE_CODE_REMOTE:-}\" -H \"X-CC-Bridge: ${CLAUDE_CODE_BRIDGE_SESSION_ID:-}\" --data-binary @- \"http://127.0.0.1:$(cat \"$PF\" 2>/dev/null || echo 48291)/hook\" >/dev/null 2>&1; exit 0"
    }

    static func isInstalled() -> Bool {
        guard let data = try? Data(contentsOf: settingsURL),
              let text = String(data: data, encoding: .utf8) else { return false }
        return text.contains("Application Support/Claudme")
    }

    static func install() throws {
        var settings = try readSettings()

        if FileManager.default.fileExists(atPath: settingsURL.path),
           !FileManager.default.fileExists(atPath: backupURL.path) {
            try? FileManager.default.copyItem(at: settingsURL, to: backupURL)
        }

        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        // drop our old entries first (the command may have changed), then add fresh
        for (event, value) in hooks {
            guard var entries = value as? [[String: Any]] else { continue }
            entries.removeAll { entryIsOurs($0) }
            if entries.isEmpty {
                hooks.removeValue(forKey: event)
            } else {
                hooks[event] = entries
            }
        }
        for event in events {
            var entries = hooks[event] as? [[String: Any]] ?? []
            entries.append(["hooks": [["type": "command", "command": hookCommand, "timeout": 5]]])
            hooks[event] = entries
        }
        settings["hooks"] = hooks
        try write(settings)
    }

    static func remove() throws {
        var settings = try readSettings()
        guard var hooks = settings["hooks"] as? [String: Any] else { return }
        for (event, value) in hooks {
            guard var entries = value as? [[String: Any]] else { continue }
            entries.removeAll { entryIsOurs($0) }
            if entries.isEmpty {
                hooks.removeValue(forKey: event)
            } else {
                hooks[event] = entries
            }
        }
        settings["hooks"] = hooks
        try write(settings)
    }

    private static func containsOurs(_ entries: [[String: Any]]) -> Bool {
        entries.contains { entryIsOurs($0) }
    }

    private static func entryIsOurs(_ entry: [String: Any]) -> Bool {
        ((entry["hooks"] as? [[String: Any]]) ?? []).contains { h in
            let cmd = h["command"] as? String ?? ""
            return cmd.contains(marker) || cmd.contains(legacyMarker)
        }
    }

    private static func readSettings() throws -> [String: Any] {
        guard let data = try? Data(contentsOf: settingsURL) else { return [:] }
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw HooksInstallerError.malformedSettings
        }
        return obj
    }

    private static func write(_ settings: [String: Any]) throws {
        let data = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        try data.write(to: settingsURL, options: .atomic)
    }
}
