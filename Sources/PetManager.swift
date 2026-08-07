import AppKit
import QuartzCore

/// One transparent, click-through overlay per display. Crabs are dealt out across
/// the displays and crawl the perimeter of whichever one they belong to.
private final class Overlay {
    let window: NSWindow
    var roamArea = RoamArea(minX: 0, maxX: 800, minY: 0, maxY: 600)
    var view: NSView { window.contentView! }

    init(screen: NSScreen) {
        window = NSWindow(contentRect: screen.frame, styleMask: .borderless,
                          backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        // one notch above the Dock so crabs walk in front of it, not behind its blur
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) + 1)
        window.ignoresMouseEvents = true    // click-through until a crab is hovered
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.contentView!.wantsLayer = true
        window.orderFrontRegardless()
    }

    /// Returns true if the ring changed and pets need re-seating.
    @discardableResult
    func layout(for screen: NSScreen) -> Bool {
        if window.frame != screen.frame {
            window.setFrame(screen.frame, display: true)
        }
        // Always the physical display edges — the overlay sits above the Dock, so no
        // need to dodge it, and this behaves identically in and out of fullscreen.
        // Only the top is inset: the menu bar strip (and the notch inside it) would
        // swallow anything drawn there. That inset equals a fullscreen window's top.
        let topInset = max(screen.safeAreaInsets.top, screen.frame.maxY - screen.visibleFrame.maxY)
        // offsets derived from the crab's body centre at (75,60), content half-extent ~21 px
        let area = RoamArea(minX: -52,
                            maxX: screen.frame.width - 98,
                            minY: -37,
                            maxY: screen.frame.height - topInset - 83)
        guard area != roamArea else { return false }
        roamArea = area
        return true
    }

    func close() {
        window.orderOut(nil)
        window.close()
    }
}

final class PetManager {
    private var overlays: [Overlay] = []
    private var petOverlay: [String: Int] = [:]     // sessionId -> overlay index
    private(set) var pets: [String: PetView] = [:]
    private(set) var lastSessions: [SessionInfo] = []
    private var tickTimer: Timer?
    private let audio = AudioSense()
    private(set) var musicPlaying = false

    /// Party mode: whether music makes the family dance at all. On unless turned off.
    private static let partyKey = "ClaudmePartyMode"
    private(set) static var partyEnabled: Bool = {
        UserDefaults.standard.object(forKey: partyKey) as? Bool ?? true
    }()

    func setPartyEnabled(_ on: Bool) {
        Self.partyEnabled = on
        UserDefaults.standard.set(on, forKey: Self.partyKey)
        let dancing = on && musicPlaying
        for pet in pets.values { pet.setMusicPlaying(dancing) }
    }

    var onCountChanged: ((Int) -> Void)?

    func start() {
        rebuildOverlays()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.rebuildOverlays()
        }
        // fullscreen apps live on their own Space — re-derive the ring when it changes
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.layoutOverlays()
        }
        let t = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        t.tolerance = 0.008                     // let the scheduler coalesce our wakeups
        RunLoop.main.add(t, forMode: .common)
        tickTimer = t

        // when music starts anywhere on the Mac, the whole family dances
        audio.onChange = { [weak self] playing in
            guard let self else { return }
            self.musicPlaying = playing
            let dance = playing && Self.partyEnabled
            for pet in self.pets.values { pet.setMusicPlaying(dance) }
        }
        audio.start()
    }

    // MARK: - Overlays

    private func rebuildOverlays() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        while overlays.count > screens.count { overlays.removeLast().close() }
        while overlays.count < screens.count { overlays.append(Overlay(screen: screens[overlays.count])) }

        for (i, screen) in screens.enumerated() {
            overlays[i].layout(for: screen)
        }
        reseatAllPets()
    }

    private func layoutOverlays() {
        let screens = NSScreen.screens
        guard screens.count == overlays.count else { rebuildOverlays(); return }
        var changed = false
        for (i, screen) in screens.enumerated() {
            if overlays[i].layout(for: screen) { changed = true }
        }
        if changed { reseatAllPets() }
    }

    /// Deal a session to a display — stable, so a crab keeps its screen across restarts.
    private func overlayIndex(for sessionId: String) -> Int {
        guard overlays.count > 1 else { return 0 }
        return Int(Naming.hash(sessionId) % UInt64(overlays.count))
    }

    private func reseatAllPets() {
        for (id, pet) in pets {
            let idx = overlayIndex(for: id)
            guard idx < overlays.count else { continue }
            let overlay = overlays[idx]
            if pet.superview !== overlay.view {
                pet.removeFromSuperview()
                overlay.view.addSubview(pet)
                pet.resetPlacement()
            }
            petOverlay[id] = idx
            pet.setRoamArea(overlay.roamArea)   // re-seats even a crab that isn't crawling
        }
    }

    // MARK: - Identity assignment

    /// stable cap colour per session name, with deterministic collision probing
    /// so all live crabs wear distinct caps
    private(set) var capColors: [String: NSColor] = [:]

    private func assignCapColors(_ sessions: [SessionInfo]) {
        var used = Set<Int>()
        var colors: [String: NSColor] = [:]
        for s in sessions.sorted(by: { $0.name < $1.name }) {
            var idx = PetView.capIndex(for: s.name)
            var probe = 0
            while used.contains(idx) && probe < PetView.capPalette.count {
                idx = (idx + 1) % PetView.capPalette.count
                probe += 1
            }
            used.insert(idx)
            colors[s.sessionId] = PetView.capPalette[idx]
        }
        capColors = colors
    }

    /// unique made names among live crabs (given name shifts on collision)
    private(set) var madeNames: [String: MadeName] = [:]

    private func assignMadeNames(_ sessions: [SessionInfo]) {
        var used = Set<String>()
        var out: [String: MadeName] = [:]
        for s in sessions.sorted(by: { $0.name < $1.name }) {
            let kind = ModelKind.parse(s.model)
            var variant = 0
            var name = Naming.name(sessionName: s.name, model: kind, ageSeconds: s.ageSeconds)
            while used.contains(name.full) && variant < 10 {
                variant += 1
                name = Naming.name(sessionName: s.name, model: kind,
                                   ageSeconds: s.ageSeconds, variant: variant)
            }
            used.insert(name.full)
            out[s.sessionId] = name
        }
        madeNames = out
    }

    // MARK: - Registry sync

    private var prevBusyCount = 0
    private var lastWaveAt: CFTimeInterval = 0

    func sync(_ sessions: [SessionInfo]) {
        lastSessions = sessions
        assignCapColors(sessions)
        assignMadeNames(sessions)

        // stadium wave when the last busy session finishes
        let busyCount = sessions.filter { $0.status == "busy" }.count
        if prevBusyCount > 0, busyCount == 0, pets.count >= 2,
           CACurrentMediaTime() - lastWaveAt > 120 {
            lastWaveAt = CACurrentMediaTime()
            let sorted = pets.values.sorted { $0.frame.origin.x < $1.frame.origin.x }
            for (i, pet) in sorted.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.13) { [weak pet] in
                    pet?.waveHop()
                }
            }
        }
        prevBusyCount = busyCount

        let ids = Set(sessions.map { $0.sessionId })
        for info in sessions {
            if let pet = pets[info.sessionId] {
                pet.update(info: info)
            } else {
                addPet(info)
            }
            if let color = capColors[info.sessionId] {
                pets[info.sessionId]?.setCap(color)
            }
            if let made = madeNames[info.sessionId] {
                pets[info.sessionId]?.setMadeName(made)
            }
        }
        for (id, pet) in pets where !ids.contains(id) {
            pets.removeValue(forKey: id)
            petOverlay.removeValue(forKey: id)
            despawn(pet)
        }
        onCountChanged?(pets.count)
    }

    private func addPet(_ info: SessionInfo) {
        let idx = overlayIndex(for: info.sessionId)
        guard idx < overlays.count else { return }
        let overlay = overlays[idx]
        let pet = PetView(info: info, roamArea: overlay.roamArea)   // places itself on the perimeter
        pet.onConfetti = { [weak self] p in self?.confetti(over: p) }
        pet.onBeerStarted = { [weak self] p in self?.maybeClink(around: p) }
        overlay.view.addSubview(pet)
        pets[info.sessionId] = pet
        petOverlay[info.sessionId] = idx
        if musicPlaying && Self.partyEnabled {
            pet.setMusicPlaying(true)      // joins a party already in progress
        }
    }

    private func despawn(_ pet: PetView) {
        pet.cleanup()
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.35
            pet.animator().alphaValue = 0
        }, completionHandler: {
            pet.removeFromSuperview()
        })
    }

    /// crabs sharing a display, so distance comparisons are in one coordinate space
    private func petsByOverlay() -> [Int: [PetView]] {
        var out: [Int: [PetView]] = [:]
        for (id, pet) in pets {
            out[petOverlay[id] ?? 0, default: []].append(pet)
        }
        return out
    }

    // MARK: - Tick

    private var tickCount = 0

    private func tick() {
        guard !pets.isEmpty else { return }     // nothing to animate, don't burn the CPU
        let now = CACurrentMediaTime()
        for pet in pets.values {
            pet.tick(now: now)
        }
        updateMouseInteractivity()
        tickCount += 1
        if tickCount % 45 == 0 { checkGreetings(now: now) }
        if tickCount % 6 == 0 { clearTheDock() }
        if tickCount % 20 == 0 { checkSeparation() }
        if tickCount % 60 == 0 { layoutOverlays() }   // catch Dock / resolution changes
    }

    /// crabs shouldn't stack — too-close pairs on the same display get nudged apart
    private func checkSeparation() {
        for (_, list) in petsByOverlay() where list.count > 1 {
            for i in 0..<list.count {
                for j in (i + 1)..<list.count {
                    let a = list[i], b = list[j]
                    let dx = a.frame.midX - b.frame.midX
                    let dy = a.frame.midY - b.frame.midY
                    // wide enough that the name pills stop overlapping too
                    if dx * dx + dy * dy < 105 * 105 {
                        a.separate(from: b)
                    }
                }
            }
        }
    }

    // MARK: - Mouse

    /// Overlays stay click-through except when the cursor is over a crab's body —
    /// then that one accepts the click (PetView.mouseDown shows the session's terminal).
    private var lastHoveredId: String?

    /// Whether a crab standing on the Dock can still be clicked.
    ///
    /// On (the default): they stay clickable everywhere, and the Dock is kept usable by
    /// the fact that they move aside as your cursor comes down. Off: inside the Dock's
    /// band the overlay never takes the mouse at all, so an icon click can never be
    /// swallowed — at the cost of not being able to click a crab that is standing there.
    static var clickableOnDock: Bool = {
        UserDefaults.standard.object(forKey: "ClaudmeClickableOnDock") as? Bool ?? true
    }()

    static func setClickableOnDock(_ v: Bool) {
        clickableOnDock = v
        UserDefaults.standard.set(v, forKey: "ClaudmeClickableOnDock")
    }

    private func updateMouseInteractivity() {
        let mouse = NSEvent.mouseLocation
        var hoveredPet: PetView?
        var hoveredOverlay = -1

        for (idx, overlay) in overlays.enumerated() {
            let f = overlay.window.frame
            guard f.contains(mouse) else { continue }
            // The overlay sits a level above the Dock so the crabs walk in front of it,
            // which means a crab parked on an icon can swallow the click that was meant
            // for the icon. Unless they are allowed to stay clickable there, we simply
            // never take the mouse inside the Dock's band.
            if !Self.clickableOnDock, let screen = overlay.window.screen {
                let dockDepth = screen.visibleFrame.minY - screen.frame.minY
                if dockDepth > 4, mouse.y < screen.frame.minY + dockDepth { continue }
            }
            let local = NSPoint(x: mouse.x - f.origin.x, y: mouse.y - f.origin.y)
            for pet in overlay.view.subviews.compactMap({ $0 as? PetView }) {
                let r = pet.bodyHitRect.offsetBy(dx: pet.frame.origin.x, dy: pet.frame.origin.y)
                if r.contains(local) { hoveredPet = pet; hoveredOverlay = idx; break }
            }
            if hoveredPet != nil { break }
        }

        for (idx, overlay) in overlays.enumerated() {
            let shouldAccept = (idx == hoveredOverlay)
            if overlay.window.ignoresMouseEvents == shouldAccept {
                overlay.window.ignoresMouseEvents = !shouldAccept
            }
        }

        if let pet = hoveredPet, pet.sessionId != lastHoveredId {
            pet.hoverPoke()   // startled little jump when the cursor arrives
        }
        lastHoveredId = hoveredPet?.sessionId
    }

    // MARK: - Hook events

    /// Re-render every crab after the flat/voxel switch is flipped.
    func refreshRenderMode() {
        for pet in pets.values { pet.applyRenderMode() }
    }

    // MARK: - Playground
    //
    // Every effect on demand, so you can see what the crabs can do without waiting
    // out the timers that normally gate them.

    enum Effect: String, CaseIterable {
        case celebrate, needsYou, trouble, beer, clink, spin, balloon, rope, rocket
        case babies, wave, compact
        case friday, saturday, monday

        var label: String {
            switch self {
            case .celebrate: return "Finished a task 🎉"
            case .needsYou:  return "Needs you ✋"
            case .trouble:   return "Rate limited ⚠️"
            case .beer:      return "Beer break 🍺"
            case .clink:     return "Clink glasses 🍻"
            case .spin:      return "Spin 🌀"
            case .balloon:   return "Balloon ride 🎈"
            case .rope:      return "Rappel down a rope 🪢"
            case .rocket:    return "Rocket across 🚀"
            case .babies:    return "Spawn subagents 👶"
            case .wave:      return "Stadium wave 🌊"
            case .compact:   return "Compact context 🗜️"
            case .friday:    return "Friday — deckchair 🌴"
            case .saturday:  return "Saturday — hangover 🥴"
            case .monday:    return "Monday — fed up 😒"
            }
        }
    }

    func run(_ effect: Effect) {
        guard let pet = pets.values.randomElement() else { return }
        switch effect {
        case .celebrate: pet.celebrate()
        case .needsYou:  pet.showNote(Quips.random(.waiting))
        case .trouble:   pet.showNote(Quips.random(.trouble))
        case .beer:      pet.beerBreak()
        case .clink:     pet.beerBreak(); maybeClink(around: pet)
        case .spin:      pet.doTrick(forced: 0)
        case .balloon:   pet.doTrick(forced: 1)
        case .rope:
            // only a crab on the ceiling can rappel, so pick one that's there
            (pets.values.first { $0.onCeiling } ?? pet).doTrick(forced: 2)
        case .rocket:
            (pets.values.first { $0.onSideWall } ?? pet).doTrick(forced: 3)
        case .babies:
            for i in 0..<3 { pet.addBaby(agentId: "playground-\(i)") }
        case .wave:
            for (i, p) in pets.values.sorted(by: { $0.frame.origin.x < $1.frame.origin.x }).enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.13) { [weak p] in
                    p?.waveHop()
                }
            }
        case .friday, .saturday, .monday:
            pet.dayMoodBreak(forced: effect == .friday ? .fridayChill
                                   : effect == .saturday ? .saturdayHangover : .mondayDisgust)
        case .compact:
            pet.compactStart()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak pet] in pet?.compactEnd() }
        }
    }

    func handle(_ event: HookEvent) {
        // every hook event carries session context — keep the crab's look fresh
        if !event.sessionId.isEmpty, let pet = pets[event.sessionId] {
            if let effortDict = event.payload["effort"] as? [String: Any],
               let level = effortDict["level"] as? String {
                pet.setEffort(level)
            }
            if let mode = event.payload["permission_mode"] as? String {
                pet.setPermissionMode(mode)
            }
            if let remote = event.payload["_remote"] as? Bool {
                pet.setRemote(remote)
            }
        }
        switch event.name {
        case "Stop":
            pets[event.sessionId]?.celebrate()
        case "UserPromptSubmit":
            pets[event.sessionId]?.workingPulse()
        case "SessionEnd":
            if let pet = pets.removeValue(forKey: event.sessionId) {
                petOverlay.removeValue(forKey: event.sessionId)
                despawn(pet)
                onCountChanged?(pets.count)
            }
        case "Notification":
            pets[event.sessionId]?.showNote(Quips.random(.waiting))
        case "SubagentStart":
            if let agentId = event.payload["agent_id"] as? String {
                pets[event.sessionId]?.addBaby(agentId: agentId)
            }
        case "SubagentStop":
            if let agentId = event.payload["agent_id"] as? String {
                pets[event.sessionId]?.removeBaby(agentId: agentId)
            }
        case "StopFailure":
            pets[event.sessionId]?.showNote(Quips.random(.trouble))
        case "PreCompact":
            pets[event.sessionId]?.compactStart()
        case "PostCompact":
            pets[event.sessionId]?.compactEnd()
        default:
            break
        }
    }

    // MARK: - Ambient social behaviour

    private var greetCooldown: [String: CFTimeInterval] = [:]

    /// A crab standing on the Dock is in the way of something you actually want to click.
    /// When the cursor comes down into the Dock's band, anyone loitering there scurries
    /// sideways — they keep to the same edge, they just get out of the doorway.
    /// Re-applies the crab scale to everyone, after the menubar preference changes.
    func refreshScales() {
        for pet in pets.values { pet.refreshScale() }
    }

    private func clearTheDock() {
        let mouse = NSEvent.mouseLocation
        for overlay in overlays {
            guard let screen = overlay.window.screen else { continue }
            let dockDepth = screen.visibleFrame.minY - screen.frame.minY
            guard dockDepth > 4 else { continue }                    // Dock is hidden or not at the bottom
            let band = screen.frame.minY + dockDepth + 30
            guard mouse.y < band, screen.frame.contains(mouse) else { continue }

            for pet in overlay.view.subviews.compactMap({ $0 as? PetView }) where pet.onFloor {
                let petX = overlay.window.frame.origin.x + pet.frame.midX
                guard abs(petX - mouse.x) < 130 else { continue }
                pet.scurry(away: petX < mouse.x ? -1 : 1)
            }
        }
    }

    private func checkGreetings(now: CFTimeInterval) {
        for (_, list) in petsByOverlay() where list.count > 1 {
            for i in 0..<list.count {
                for j in (i + 1)..<list.count {
                    let a = list[i], b = list[j]
                    guard a.state == .idle || a.state == .working,
                          b.state == .idle || b.state == .working else { continue }
                    let dx = a.frame.midX - b.frame.midX
                    let dy = a.frame.midY - b.frame.midY
                    guard dx * dx + dy * dy < 80 * 80 else { continue }
                    let key = a.sessionId < b.sessionId ? a.sessionId + b.sessionId
                                                        : b.sessionId + a.sessionId
                    if now - (greetCooldown[key] ?? 0) > 90 {
                        greetCooldown[key] = now
                        let line = Quips.random(.greeting)
                        a.showNote(line)
                        b.showNote(line)
                    }
                }
            }
        }
    }

    /// a nearby crab on the same display joins the beer for a toast 🍻
    private func maybeClink(around pet: PetView) {
        let idx = petOverlay[pet.sessionId] ?? 0
        for (other, otherIdx) in pets.values.map({ ($0, petOverlay[$0.sessionId] ?? 0) })
        where other !== pet && otherIdx == idx {
            guard other.state == .idle || other.state == .working else { continue }
            let dx = pet.frame.midX - other.frame.midX
            let dy = pet.frame.midY - other.frame.midY
            if dx * dx + dy * dy < 140 * 140 {
                other.beerBreak(joining: true)
                pet.showClink()
                other.showClink()
                break
            }
        }
    }

    // MARK: - Confetti

    private func confetti(over pet: PetView) {
        guard let layer = pet.superview?.layer else { return }
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: pet.frame.midX, y: pet.frame.minY + 70)
        emitter.emitterShape = .point
        let colors: [NSColor] = [PetView.claudeOrange, .systemYellow, .systemTeal, .systemPink, .white]
        emitter.emitterCells = colors.compactMap { color in
            guard let image = Self.particleImage(color) else { return nil }
            let cell = CAEmitterCell()
            cell.contents = image
            cell.birthRate = 30
            cell.lifetime = 1.6
            cell.velocity = 240
            cell.velocityRange = 100
            cell.emissionLongitude = .pi / 2      // up (y-up layer space)
            cell.emissionRange = .pi / 2.4
            cell.yAcceleration = -420             // gravity
            cell.spin = 5
            cell.spinRange = 8
            cell.scale = 0.5
            cell.scaleRange = 0.25
            cell.alphaSpeed = -0.55
            return cell
        }
        layer.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { emitter.birthRate = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { emitter.removeFromSuperlayer() }
    }

    private static func particleImage(_ color: NSColor) -> CGImage? {
        let size = 10
        guard let ctx = CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.setFillColor((color.usingColorSpace(.sRGB) ?? color).cgColor)
        ctx.fill(CGRect(x: 1, y: 1, width: size - 2, height: size - 2))
        return ctx.makeImage()
    }

    // MARK: - Debug (only reachable with CLAUDME_DEBUG=1)

    /// Renders every overlay's layer tree into one PNG, stacked vertically.
    /// Needs no screen-recording permission — we only draw our own layers.
    func saveSnapshot() {
        let views = overlays.map { $0.view }
        guard !views.isEmpty else { return }
        let width = Int(views.map { $0.bounds.width }.max() ?? 0)
        let height = Int(views.reduce(0) { $0 + $1.bounds.height })
        guard width > 0, height > 0,
              let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let gctx = NSGraphicsContext(bitmapImageRep: rep)
        else { return }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = gctx
        var y: CGFloat = 0
        for view in views {
            if let root = view.layer {
                gctx.cgContext.saveGState()
                gctx.cgContext.translateBy(x: 0, y: y)
                root.render(in: gctx.cgContext)
                gctx.cgContext.restoreGState()
            }
            y += view.bounds.height
        }
        NSGraphicsContext.restoreGraphicsState()

        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Claudme", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: dir.appendingPathComponent("snapshot.png"))
        }
    }
}
