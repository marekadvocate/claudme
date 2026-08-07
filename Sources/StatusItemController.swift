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
        // macOS truncates the menubar from the right when it fills up and gives the app no
        // way to know it happened, so the only defence is to take less room — but dropping
        // the count entirely takes away the one number worth glancing at. Keep it, and buy
        // the space back by tightening the spacing and the font instead.
        let n = NSAttributedString(string: "\(count)", attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
        ])
        if item.button?.image == nil {
            item.button?.title = "🦀 \(count)"
        } else {
            item.button?.attributedTitle = n
            item.button?.imageHugsTitle = true
        }
        item.button?.toolTip = "Claudme — \(count) session\(count == 1 ? "" : "s")"
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        // we decide what's enabled; AppKit's auto-validation greys out anything it
        // can't reason about, which was dimming the whole Playground submenu
        menu.autoenablesItems = false
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
        langMenu.autoenablesItems = false
        for l in Lang.allCases {
            let li = NSMenuItem(title: l.displayName, action: #selector(pickLanguage(_:)), keyEquivalent: "")
            li.target = self
            li.representedObject = l.rawValue
            li.state = (Quips.language == l) ? .on : .off
            langMenu.addItem(li)
        }
        // The register lives inside Language: it's the same choice, one level down.
        langMenu.addItem(.separator())
        for r in Register.allCases {
            let ri = NSMenuItem(title: r.displayName, action: #selector(pickRegister(_:)), keyEquivalent: "")
            ri.target = self
            ri.representedObject = r.rawValue
            ri.state = (Quips.register == r) ? .on : .off
            ri.isEnabled = true
            langMenu.addItem(ri)
        }
        langMenu.item(withTitle: Register.street.displayName)?.toolTip =
            "Real underworld argot, and it swears — in every language"

        lang.isEnabled = true
        lang.submenu = langMenu
        menu.addItem(lang)

        // Crab size, as a percentage — on top of the per-state and per-model scales
        let size = NSMenuItem(title: "Crab size", action: nil, keyEquivalent: "")
        let sizeMenu = NSMenu()
        sizeMenu.autoenablesItems = false
        for pct in [50, 75, 100, 125, 150, 200, 300] {
            let si = NSMenuItem(title: "\(pct)%", action: #selector(pickScale(_:)), keyEquivalent: "")
            si.target = self
            si.representedObject = pct
            si.state = Int((PetView.userScale * 100).rounded()) == pct ? .on : .off
            si.isEnabled = true
            sizeMenu.addItem(si)
        }
        size.isEnabled = true
        size.submenu = sizeMenu
        menu.addItem(size)

        // Tempo — what shipped before is the fastest of the three
        let tempo = NSMenuItem(title: "Speed", action: nil, keyEquivalent: "")
        let tempoMenu = NSMenu()
        tempoMenu.autoenablesItems = false
        for t in PetView.Tempo.allCases {
            let ti = NSMenuItem(title: t.displayName, action: #selector(pickTempo(_:)), keyEquivalent: "")
            ti.target = self
            ti.representedObject = t.rawValue
            ti.state = (PetView.tempo == t) ? .on : .off
            ti.isEnabled = true
            tempoMenu.addItem(ti)
        }
        tempo.isEnabled = true
        tempo.submenu = tempoMenu
        menu.addItem(tempo)

        // Playground: fire any effect on demand instead of waiting out its timer
        let play = NSMenuItem(title: "Playground", action: nil, keyEquivalent: "")
        let playMenu = NSMenu()
        playMenu.autoenablesItems = false
        for effect in PetManager.Effect.allCases {
            let i = NSMenuItem(title: effect.label, action: #selector(runEffect(_:)), keyEquivalent: "")
            i.target = self
            i.representedObject = effect.rawValue
            i.isEnabled = !manager.pets.isEmpty
            playMenu.addItem(i)
        }
        play.isEnabled = true
        play.submenu = playMenu
        menu.addItem(play)

        let party = NSMenuItem(title: "Party mode", action: #selector(toggleParty), keyEquivalent: "")
        party.target = self
        party.state = PetManager.partyEnabled ? .on : .off
        party.toolTip = "Let the family dance whenever something is playing on this Mac"
        party.isEnabled = true
        menu.addItem(party)

        let dock = NSMenuItem(title: "Clickable over the Dock",
                              action: #selector(toggleDockClicks), keyEquivalent: "")
        dock.target = self
        dock.state = PetManager.clickableOnDock ? .on : .off
        dock.toolTip = "On: a crab on the Dock can still be clicked — they move aside anyway. "
            + "Off: clicks in the Dock always reach the icon underneath."
        dock.isEnabled = true
        menu.addItem(dock)

        let voxel = NSMenuItem(title: "3D crabs", action: #selector(toggleVoxel), keyEquivalent: "")
        voxel.target = self
        voxel.state = PetView.voxelMode ? .on : .off
        voxel.toolTip = "Render the family as isometric voxels, like the app icon"
        voxel.isEnabled = true
        menu.addItem(voxel)

        menu.addItem(.separator())

        let update = NSMenuItem(title: "Check for updates…", action: #selector(checkUpdates), keyEquivalent: "")
        update.target = self
        update.toolTip = "Pulls the latest source, rebuilds and relaunches"
        update.isEnabled = true
        menu.addItem(update)

        let contribute = NSMenuItem(title: "Contribute on GitHub", action: #selector(openRepo), keyEquivalent: "")
        contribute.target = self
        contribute.toolTip = "New languages, idle behaviours and era skins are all welcome"
        contribute.isEnabled = true
        menu.addItem(contribute)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Claudme", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.isEnabled = true
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

    @objc private func toggleDockClicks() {
        PetManager.setClickableOnDock(!PetManager.clickableOnDock)
    }

    @objc private func pickTempo(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let t = PetView.Tempo(rawValue: raw) else { return }
        PetView.setTempo(t)
    }

    @objc private func pickScale(_ sender: NSMenuItem) {
        guard let pct = sender.representedObject as? Int else { return }
        PetView.setUserScale(CGFloat(pct) / 100)
        manager.refreshScales()
    }

    @objc private func pickRegister(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let r = Register(rawValue: raw) else { return }
        Quips.setRegister(r)
    }

    @objc private func runEffect(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let effect = PetManager.Effect(rawValue: raw) else { return }
        manager.run(effect)
    }

    @objc private func checkUpdates() { Updater.checkAndPrompt() }

    @objc private func openRepo() {
        NSWorkspace.shared.open(URL(string: "https://github.com/marekadvocate/claudme")!)
    }

    @objc private func toggleParty() {
        manager.setPartyEnabled(!PetManager.partyEnabled)
    }

    @objc private func toggleVoxel() {
        PetView.setVoxelMode(!PetView.voxelMode)
        manager.refreshRenderMode()
    }

}
