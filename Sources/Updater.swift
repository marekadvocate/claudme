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

    /// Runs a child process with a hard deadline. Without one, `git fetch` on a captive
    /// portal never returns — and since this app has no window, a hung main thread means
    /// force-quit is the only way out.
    private static func run(_ launch: String, _ args: [String],
                            in dir: URL, timeout: TimeInterval) -> (out: String, ok: Bool) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = args
        p.currentDirectoryURL = dir
        var env = ProcessInfo.processInfo.environment
        env["GIT_TERMINAL_PROMPT"] = "0"            // never sit waiting for credentials
        env["GIT_HTTP_LOW_SPEED_LIMIT"] = "1000"
        env["GIT_HTTP_LOW_SPEED_TIME"] = "15"
        p.environment = env

        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return ("", false) }

        let killer = DispatchWorkItem { if p.isRunning { p.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: killer)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        killer.cancel()

        return (String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines),
                p.terminationStatus == 0)
    }

    @discardableResult
    private static func git(_ args: [String], in dir: URL,
                            timeout: TimeInterval = 30) -> (out: String, ok: Bool) {
        run("git", ["git", "-C", dir.path] + args, in: dir, timeout: timeout)
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

        let build = run("bash", ["bash", root.appendingPathComponent("build.sh").path],
                        in: root, timeout: 300)
        guard build.ok else { return "Build failed:\n\(build.out.suffix(600))" }
        DispatchQueue.main.async { relaunch() }
        return nil
    }

    private static func relaunch() {
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: cfg) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }

    // MARK: - Background checks

    /// How many commits we are behind, as of the last background check. `nil` means we
    /// haven't looked yet or couldn't reach the remote.
    private(set) static var pendingCommits: Int?
    static var onPendingChanged: ((Int?) -> Void)?

    private static var timer: Timer?
    private static let autoKey = "ClaudmeAutoCheck"

    static var autoCheckEnabled: Bool {
        UserDefaults.standard.object(forKey: autoKey) as? Bool ?? true
    }

    static func setAutoCheckEnabled(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: autoKey)
        on ? startBackgroundChecks() : stopBackgroundChecks()
        if !on { pendingCommits = nil; onPendingChanged?(nil) }
    }

    /// Checks a few times a day, quietly. It never installs anything and never puts a
    /// dialog in front of you — pulling and rebuilding someone's checkout without asking is
    /// not a thing an app should do on its own. All it does is set a flag the menubar shows.
    ///
    /// Once a day, not once an hour: a fetch against this repo measures about five seconds
    /// of network round-trip, and nobody but the author sees it change more than once a
    /// day. Twenty-four of those would buy no extra news.
    static func startBackgroundChecks() {
        guard autoCheckEnabled, timer == nil, repoRoot != nil else { return }
        let t = Timer(timeInterval: 24 * 3600, repeats: true) { _ in checkQuietly() }
        t.tolerance = 1800                      // let the system batch it with other wakeups
        RunLoop.main.add(t, forMode: .common)
        timer = t
        // stagger the first one so it never lands during launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 90) { checkQuietly() }
    }

    static func stopBackgroundChecks() {
        timer?.invalidate()
        timer = nil
    }

    private static func checkQuietly() {
        DispatchQueue.global(qos: .background).async {
            let behind: Int?
            switch check() {
            case .behind(let n): behind = n
            case .upToDate:      behind = 0
            default:             behind = nil    // dirty tree, no remote, not a checkout
            }
            DispatchQueue.main.async {
                guard behind != pendingCommits else { return }
                pendingCommits = behind
                onPendingChanged?(behind)
            }
        }
    }

    // MARK: - UI

    /// Menubar entry point. Git and the build run off the main thread; only the alerts
    /// and the relaunch come back to it, so the crabs keep moving throughout.
    static func checkAndPrompt() {
        DispatchQueue.global(qos: .userInitiated).async {
            let status = check()
            DispatchQueue.main.async { present(status) }
        }
    }

    private static func present(_ status: Status) {
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

            DispatchQueue.global(qos: .userInitiated).async {
                let error = update()
                guard let error else { return }        // success relaunches itself
                DispatchQueue.main.async {
                    let fail = NSAlert()
                    fail.messageText = "Update failed"
                    fail.informativeText = error
                    fail.alertStyle = .warning
                    fail.runModal()
                }
            }
        }
    }
}
