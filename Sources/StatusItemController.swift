import AppKit

final class StatusItemController: NSObject, NSMenuDelegate {
    private let item: NSStatusItem
    private let manager: PetManager
    private let menu = NSMenu()

    init(manager: PetManager) {
        self.manager = manager
        self.item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        item.button?.title = "✳ 0"
        menu.delegate = self
        item.menu = menu
        manager.onCountChanged = { [weak self] n in
            self?.item.button?.title = "✳ \(n)"
        }
    }

    func refresh(_ sessions: [SessionInfo]) {
        item.button?.title = "✳ \(sessions.count)"
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let sessions = manager.lastSessions
        if sessions.isEmpty {
            menu.addItem(withTitle: "No Claude sessions", action: nil, keyEquivalent: "")
        }
        for s in sessions {
            let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            // cap-colored dot = the same identity color the crab wears
            let title = NSMutableAttributedString(string: "● ", attributes: [
                .foregroundColor: manager.capColors[s.sessionId] ?? PetView.capColor(for: s.name),
            ])
            var line = "\(s.name) — \(s.status)"
            let kind = ModelKind.parse(s.model)
            if kind != .unknown { line += " · \(kind.rawValue)" }
            title.append(NSAttributedString(string: line))
            item.attributedTitle = title
            item.isEnabled = false
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let installed = HooksInstaller.isInstalled()
        let hookItem = NSMenuItem(
            title: installed ? "Remove Claude Code hooks" : "Install Claude Code hooks (live reactions)",
            action: installed ? #selector(removeHooks) : #selector(installHooks),
            keyEquivalent: ""
        )
        hookItem.target = self
        menu.addItem(hookItem)

        let test = NSMenuItem(title: "Test celebration 🎉", action: #selector(testCelebrate), keyEquivalent: "")
        test.target = self
        menu.addItem(test)

        let beer = NSMenuItem(title: "Beer break 🍺", action: #selector(beerBreak), keyEquivalent: "")
        beer.target = self
        menu.addItem(beer)

        let trick = NSMenuItem(title: "Balloon ride 🎈", action: #selector(balloonRide), keyEquivalent: "")
        trick.target = self
        menu.addItem(trick)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit ClaudePet", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func installHooks() { runHookAction { try HooksInstaller.install() } }
    @objc private func removeHooks() { runHookAction { try HooksInstaller.remove() } }
    @objc private func testCelebrate() { manager.testCelebrate() }
    @objc private func beerBreak() { manager.testBeer() }
    @objc private func balloonRide() { manager.testTrick() }

    private func runHookAction(_ op: () throws -> Void) {
        do {
            try op()
        } catch {
            let alert = NSAlert()
            alert.messageText = "ClaudePet"
            alert.informativeText = "Could not update ~/.claude/settings.json: \(error)"
            alert.runModal()
        }
    }
}
