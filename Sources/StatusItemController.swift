import AppKit

final class StatusItemController: NSObject, NSMenuDelegate {
    private let item: NSStatusItem
    private let manager: PetManager
    private let menu = NSMenu()

    init(manager: PetManager) {
        self.manager = manager
        self.item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        // The bare mark, not the app icon — the icon carries a dark rounded plate that
        // reads as a black sticker against the menubar.
        if let url = Bundle.main.url(forResource: "menubar", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            img.size = NSSize(width: 17, height: 17)
            img.isTemplate = false
            item.button?.image = img
            item.button?.imagePosition = .imageLeading
        }
        setTitle(0)
        menu.delegate = self
        item.menu = menu
        manager.onCountChanged = { [weak self] n in self?.setTitle(n) }
    }

    func refresh(_ sessions: [SessionInfo]) {
        setTitle(sessions.count)
    }

    private func setTitle(_ count: Int) {
        // no emoji when the mark is already there; fall back to it if the icon is missing
        item.button?.title = item.button?.image == nil ? "🦀 \(count)" : " \(count)"
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let sessions = manager.lastSessions

        menu.addItem(header(sessions.isEmpty
            ? "No sessions in the family"
            : "The family — \(sessions.count) made \(sessions.count == 1 ? "man" : "men")"))

        for s in sessions.sorted(by: { $0.ageSeconds > $1.ageSeconds }) {
            menu.addItem(sessionRow(s))
        }

        menu.addItem(.separator())

        // Language submenu
        let lang = NSMenuItem(title: "Language", action: nil, keyEquivalent: "")
        let langMenu = NSMenu()
        for l in Lang.allCases {
            let li = NSMenuItem(title: l.displayName, action: #selector(pickLanguage(_:)), keyEquivalent: "")
            li.target = self
            li.representedObject = l.rawValue
            li.state = (Quips.language == l) ? .on : .off
            langMenu.addItem(li)
        }
        lang.submenu = langMenu
        menu.addItem(lang)

        let voxel = NSMenuItem(title: "3D crabs", action: #selector(toggleVoxel), keyEquivalent: "")
        voxel.target = self
        voxel.state = PetView.voxelMode ? .on : .off
        voxel.toolTip = "Render the family as isometric voxels, like the app icon"
        menu.addItem(voxel)

        // Hooks
        let installed = HooksInstaller.isInstalled()
        let hooks = NSMenuItem(title: "Live reactions",
                               action: installed ? #selector(removeHooks) : #selector(installHooks),
                               keyEquivalent: "")
        hooks.target = self
        hooks.state = installed ? .on : .off
        hooks.toolTip = installed
            ? "Claude Code hooks are installed — click to remove them"
            : "Install Claude Code hooks so crabs react the instant a turn ends"
        menu.addItem(hooks)

        menu.addItem(.separator())

        let update = NSMenuItem(title: "Check for updates…", action: #selector(checkUpdates), keyEquivalent: "")
        update.target = self
        update.toolTip = "Pulls the latest source, rebuilds and relaunches"
        menu.addItem(update)

        let contribute = NSMenuItem(title: "Contribute on GitHub", action: #selector(openRepo), keyEquivalent: "")
        contribute.target = self
        contribute.toolTip = "New languages, idle behaviours and era skins are all welcome"
        menu.addItem(contribute)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Claudme", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    /// dimmed small-caps section title
    private func header(_ text: String) -> NSMenuItem {
        let i = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        i.attributedTitle = NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor,
        ])
        i.isEnabled = false
        return i
    }

    /// "● Don Vito Opus            working"  — dot in the crab's own colour
    private func sessionRow(_ s: SessionInfo) -> NSMenuItem {
        let i = NSMenuItem(title: "", action: #selector(focusSession(_:)), keyEquivalent: "")
        i.target = self
        i.representedObject = s.pid

        let made = manager.madeNames[s.sessionId]
            ?? Naming.name(sessionName: s.name, model: ModelKind.parse(s.model), ageSeconds: s.ageSeconds)
        let colour = manager.capColors[s.sessionId] ?? PetView.capColor(for: s.name)

        let line = NSMutableAttributedString(string: "● ", attributes: [.foregroundColor: colour])
        line.append(NSAttributedString(string: made.full, attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
        ]))
        line.append(NSAttributedString(string: "   \(statusGlyph(s.status)) \(s.status)", attributes: [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]))
        i.attributedTitle = line
        i.toolTip = "\(s.name) · \(made.era.label) · \((s.cwd as NSString).abbreviatingWithTildeInPath)\nClick to show its terminal"
        return i
    }

    private func statusGlyph(_ status: String) -> String {
        switch status {
        case "busy": return "▶"
        case "idle": return "○"
        default: return "◐"
        }
    }

    // MARK: - Actions

    @objc private func focusSession(_ sender: NSMenuItem) {
        guard let pid = sender.representedObject as? Int32 else { return }
        TerminalFocus.focusApp(forSessionPID: pid)
    }

    @objc private func pickLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let l = Lang(rawValue: raw) else { return }
        Quips.setLanguage(l)
    }

    @objc private func checkUpdates() { Updater.checkAndPrompt() }

    @objc private func openRepo() {
        NSWorkspace.shared.open(URL(string: "https://github.com/marekadvocate/claudme")!)
    }

    @objc private func toggleVoxel() {
        PetView.setVoxelMode(!PetView.voxelMode)
        manager.refreshRenderMode()
    }

    @objc private func installHooks() { runHookAction { try HooksInstaller.install() } }
    @objc private func removeHooks() { runHookAction { try HooksInstaller.remove() } }

    private func runHookAction(_ op: () throws -> Void) {
        do {
            try op()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Claudme"
            alert.informativeText = "Could not update ~/.claude/settings.json: \(error)"
            alert.runModal()
        }
    }
}
