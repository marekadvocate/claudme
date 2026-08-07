import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    /// Hooks make the crabs react the instant a turn ends. They edit the user's
    /// settings.json, so we ask once rather than doing it silently — and never ask again,
    /// whatever the answer. Afterwards it's `--install-hooks` / `--remove-hooks`.
    private func offerHooksOnce() {
        let key = "ClaudmeAskedAboutHooks"
        guard !UserDefaults.standard.bool(forKey: key), !HooksInstaller.isInstalled() else { return }
        UserDefaults.standard.set(true, forKey: key)

        let alert = NSAlert()
        alert.messageText = "Turn on live reactions?"
        alert.informativeText = """
            Claudme can react the instant a Claude Code turn ends — celebrations, \
            subagents, warnings — by adding a one-line hook to ~/.claude/settings.json.

            The hook only ever talks to 127.0.0.1 and always exits 0, so it can't block \
            or slow down Claude Code. Your settings are backed up first.

            Without it the crabs still work, just up to a second behind.
            """
        alert.addButton(withTitle: "Turn on")
        alert.addButton(withTitle: "Not now")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do {
            try HooksInstaller.install()
        } catch {
            let fail = NSAlert()
            fail.messageText = "Claudme"
            fail.informativeText = "Could not update ~/.claude/settings.json: \(error)"
            fail.runModal()
        }
    }
    private var manager: PetManager!
    private var registry: SessionRegistry?
    private var hookServer: HookServer!
    private var statusController: StatusItemController!

    /// The port file tells hooks where to send payloads — including prompt text. Leaving
    /// it behind after we quit points them at whatever binds the port next.
    func applicationWillTerminate(_ notification: Notification) {
        let f = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Claudme/port")
        try? FileManager.default.removeItem(at: f)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // single instance guard (when running as a bundle)
        if let bid = Bundle.main.bundleIdentifier {
            let others = NSRunningApplication.runningApplications(withBundleIdentifier: bid)
                .filter { $0.processIdentifier != NSRunningApplication.current.processIdentifier }
            if !others.isEmpty {
                NSApp.terminate(nil)
                return
            }
        }

        manager = PetManager()
        manager.start()

        statusController = StatusItemController(manager: manager)

        hookServer = HookServer()
        hookServer.onSnapshot = { [weak self] in self?.manager.saveSnapshot() }
        hookServer.onEffect = { [weak self] name in
            guard let e = PetManager.Effect(rawValue: name) else { return }
            self?.manager.run(e)
        }
        hookServer.onEvent = { [weak self] event in
            self?.manager.handle(event)
            if event.name == "SessionStart" || event.name == "SessionEnd" {
                self?.registry?.pollNow()
            }
        }

        offerHooksOnce()

        registry = SessionRegistry()
        registry?.onChange = { [weak self] sessions in
            self?.manager.sync(sessions)
            self?.statusController?.refresh(sessions)
        }
        registry?.start()

        // last, so a hook can never arrive before the things it drives exist
        hookServer.start()
        Updater.startBackgroundChecks()
    }
}
