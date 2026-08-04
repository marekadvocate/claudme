import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var manager: PetManager!
    private var registry: SessionRegistry!
    private var hookServer: HookServer!
    private var statusController: StatusItemController!

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
        hookServer.onEvent = { [weak self] event in
            self?.manager.handle(event)
            if event.name == "SessionStart" || event.name == "SessionEnd" {
                self?.registry.pollNow()
            }
        }
        hookServer.start()

        registry = SessionRegistry()
        registry.onChange = { [weak self] sessions in
            self?.manager.sync(sessions)
            self?.statusController?.refresh(sessions)
        }
        registry.start()
    }
}
