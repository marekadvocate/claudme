import AppKit

/// Claudme is distributed as source you build yourself, so an update is just
/// `git pull && ./build.sh`. This wraps that in a menubar button: it checks whether
/// the checkout is behind its remote, and if you agree, pulls, rebuilds and relaunches.
///
/// Everything is best-effort — a tarball download or a checkout with local changes
/// simply reports that it can't update rather than touching your work.
enum Updater {

    enum Status {
        case upToDate
        case behind(Int)
        case notAGitCheckout
        case dirty
        case failed(String)
    }

    /// The repo root, derived from the running bundle: <repo>/build/Claudme.app
    static var repoRoot: URL? {
        let app = Bundle.main.bundleURL          // …/build/Claudme.app
        let root = app.deletingLastPathComponent().deletingLastPathComponent()
        return FileManager.default.fileExists(atPath: root.appendingPathComponent(".git").path)
            ? root : nil
    }

    @discardableResult
    private static func git(_ args: [String], in dir: URL) -> (out: String, ok: Bool) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["git", "-C", dir.path] + args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return ("", false) }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines),
                p.terminationStatus == 0)
    }

    static func check() -> Status {
        guard let root = repoRoot else { return .notAGitCheckout }
        if !git(["diff", "--quiet"], in: root).ok { return .dirty }
        guard git(["fetch", "--quiet"], in: root).ok else {
            return .failed("Could not reach the remote.")
        }
        let counts = git(["rev-list", "--count", "HEAD..@{u}"], in: root)
        guard counts.ok, let behind = Int(counts.out) else {
            return .failed("No upstream branch is configured.")
        }
        return behind == 0 ? .upToDate : .behind(behind)
    }

    /// Pulls, rebuilds and relaunches. Returns an error string on failure.
    static func update() -> String? {
        guard let root = repoRoot else { return "Not a git checkout." }
        let pull = git(["pull", "--ff-only"], in: root)
        guard pull.ok else { return "git pull failed:\n\(pull.out)" }

        let build = Process()
        build.executableURL = URL(fileURLWithPath: "/bin/bash")
        build.arguments = [root.appendingPathComponent("build.sh").path]
        build.currentDirectoryURL = root
        let pipe = Pipe()
        build.standardOutput = pipe
        build.standardError = pipe
        do { try build.run() } catch { return "Could not start build.sh." }
        let out = pipe.fileHandleForReading.readDataToEndOfFile()
        build.waitUntilExit()
        guard build.terminationStatus == 0 else {
            let tail = String(decoding: out, as: UTF8.self).suffix(600)
            return "Build failed:\n\(tail)"
        }
        relaunch()
        return nil
    }

    private static func relaunch() {
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: cfg) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }

    // MARK: - UI

    /// Menubar entry point: check, then offer the update.
    static func checkAndPrompt() {
        let status = check()
        let alert = NSAlert()
        alert.messageText = "Claudme"

        switch status {
        case .upToDate:
            alert.informativeText = "You're on the latest version."
            alert.runModal()

        case .notAGitCheckout:
            alert.informativeText = """
                This copy wasn't cloned with git, so it can't update itself.

                Grab the latest with:
                git clone https://github.com/marekadvocate/claudme.git
                """
            alert.runModal()

        case .dirty:
            alert.informativeText = """
                You have uncommitted changes in the checkout, so nothing was touched.

                Commit or stash them, then check again.
                """
            alert.runModal()

        case .failed(let why):
            alert.informativeText = why
            alert.runModal()

        case .behind(let n):
            alert.informativeText = "\(n) new commit\(n == 1 ? "" : "s") available. "
                + "Update pulls, rebuilds and relaunches — takes a few seconds."
            alert.addButton(withTitle: "Update now")
            alert.addButton(withTitle: "Later")
            guard alert.runModal() == .alertFirstButtonReturn else { return }

            if let error = update() {
                let fail = NSAlert()
                fail.messageText = "Update failed"
                fail.informativeText = error
                fail.alertStyle = .warning
                fail.runModal()
            }
        }
    }
}
