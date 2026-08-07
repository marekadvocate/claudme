import Foundation

enum HooksInstallerError: Error, CustomStringConvertible {
    case malformedSettings
    case unreadableSettings
    case backupFailed

    var description: String {
        switch self {
        case .malformedSettings:
            return "~/.claude/settings.json is not valid JSON — refusing to touch it"
        case .unreadableSettings:
            return "~/.claude/settings.json exists but can't be read — refusing to touch it"
        case .backupFailed:
            return "Couldn't back up ~/.claude/settings.json — refusing to change it"
        }
    }
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
        var settings = try readSettings()   // throws rather than assuming empty

        // A backup we failed to take is worse than no backup, because the rest of this
        // function is about to edit a file we don't own. Refresh it every install so it
        // always reflects the state we're changing from.
        if FileManager.default.fileExists(atPath: settingsURL.path) {
            try? FileManager.default.removeItem(at: backupURL)
            do { try FileManager.default.copyItem(at: settingsURL.resolvingSymlinksInPath(),
                                                  to: backupURL) }
            catch { throw HooksInstallerError.backupFailed }
        }

        if settings["hooks"] != nil, !(settings["hooks"] is [String: Any]) {
            throw HooksInstallerError.malformedSettings   // never overwrite a shape we can't read
        }
        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        for (event, value) in hooks {
            hooks[event] = strippingOurs(value) ?? value
        }
        for event in events {
            // Element-wise, and anything we don't recognise is carried through untouched —
            // a single odd entry must never take the user's other hooks with it.
            //
            // If the value is not an array at all — a shape a hand-edited settings.json can
            // easily have — `as? [Any] ?? []` used to throw it away and write ours in its
            // place, silently, in a file we do not own. Leave it alone instead.
            let existing = strippingOurs(hooks[event])
            if existing != nil, !(existing is [Any]) { continue }
            var entries = (existing as? [Any]) ?? []
            entries.append(["hooks": [["type": "command", "command": hookCommand, "timeout": 5]]])
            hooks[event] = entries
        }
        settings["hooks"] = hooks
        try write(settings)
    }

    /// Removes only our own entries from an event's array, preserving everything else
    /// exactly as found — including elements that aren't the shape we expect.
    private static func strippingOurs(_ value: Any?) -> Any? {
        guard let array = value as? [Any] else { return value }
        return array.filter { element in
            guard let entry = element as? [String: Any] else { return true }  // keep unknowns
            return !entryIsOurs(entry)
        }
    }

    static func remove() throws {
        var settings = try readSettings()
        guard var hooks = settings["hooks"] as? [String: Any] else { return }
        for (event, value) in hooks {
            let kept = strippingOurs(value)
            if let array = kept as? [Any], array.isEmpty {
                hooks.removeValue(forKey: event)
            } else {
                hooks[event] = kept
            }
        }
        // leave no empty "hooks": {} behind — the README promises a clean uninstall
        if hooks.isEmpty {
            settings.removeValue(forKey: "hooks")
        } else {
            settings["hooks"] = hooks
        }
        try write(settings)

        try? FileManager.default.removeItem(at: backupURL)
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Claudme", isDirectory: true)
        try? FileManager.default.removeItem(at: support)
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

    /// Missing is fine — we'll create it. Present-but-unreadable is NOT: treating that as
    /// an empty dict would make install() replace the user's real settings with a file
    /// containing nothing but our hooks.
    private static func readSettings() throws -> [String: Any] {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: settingsURL.path, isDirectory: &isDir)
        // lstat semantics: a dangling symlink still counts as "there is something here"
        let linkExists = (try? FileManager.default.attributesOfItem(atPath: settingsURL.path)) != nil
        guard exists || linkExists else { return [:] }

        guard let data = try? Data(contentsOf: settingsURL) else {
            throw HooksInstallerError.unreadableSettings
        }
        if data.isEmpty { return [:] }
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
        // Atomic writes replace the path itself, which would turn a settings.json that is
        // symlinked into a dotfiles repo into a plain file and orphan the real one. Resolve
        // the link first so we always write through to the actual target.
        let target = settingsURL.resolvingSymlinksInPath()
        // On a machine where Claude Code has run but never written settings, ~/.claude may
        // not exist yet and the atomic write fails with no useful error.
        try? FileManager.default.createDirectory(at: target.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try data.write(to: target, options: .atomic)
        // an atomic write creates a fresh inode with default perms; this file can carry
        // tokens, so keep it owner-only
        try? FileManager.default.setAttributes([.posixPermissions: 0o600],
                                               ofItemAtPath: target.path)
    }
}
