import AppKit
import QuartzCore

final class PetManager {
    private var overlayWindow: NSWindow!
    private var contentView: NSView { overlayWindow.contentView! }
    private(set) var pets: [String: PetView] = [:]
    private(set) var lastSessions: [SessionInfo] = []
    private var roamArea = RoamArea(minX: 0, maxX: 800, minY: 0, maxY: 600)
    private var tickTimer: Timer?

    var onCountChanged: ((Int) -> Void)?

    func start() {
        buildOverlay()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.layoutOverlay()
        }
        // fullscreen apps live on their own Space — re-derive the floor when it changes
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.layoutOverlay()
        }
        let t = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        tickTimer = t
    }

    // MARK: - Overlay window

    private func buildOverlay() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let w = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = .floating
        w.ignoresMouseEvents = true    // fully click-through, pets never steal input
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        w.isReleasedWhenClosed = false
        w.contentView!.wantsLayer = true
        overlayWindow = w
        layoutOverlay()
        w.orderFrontRegardless()
    }

    private func layoutOverlay() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        if overlayWindow.frame != screen.frame {
            overlayWindow.setFrame(screen.frame, display: true)
        }
        // On a fullscreen Space the Dock/menubar are gone. Use the fullscreen window's
        // own rect rather than screen.frame — on notched displays it stops below the
        // notch strip (e.g. 949 pt tall on a 982 pt screen).
        let visible = Self.fullscreenRect(on: screen) ?? screen.visibleFrame
        // perimeter ring the pets crawl on — legs touch the visible-frame edges
        // (offsets derived from body center at (75,60), content half-extent ~21 px)
        let area = RoamArea(
            minX: visible.minX - screen.frame.minX - 52,
            maxX: visible.maxX - screen.frame.minX - 98,
            minY: visible.minY - screen.frame.minY - 37,
            maxY: visible.maxY - screen.frame.minY - 83
        )
        guard area != roamArea else { return }
        roamArea = area
        for pet in pets.values {
            pet.roamArea = roamArea   // pets re-derive their edge position next tick
        }
    }

    /// AppKit rect of a window filling the screen on a fullscreen Space, if one is active.
    /// A fullscreen window spans the full width and runs past the Dock to the screen's
    /// bottom edge — that's what separates it from a merely zoomed window.
    /// Only bounds/layer/PID are read, so no screen-recording permission is needed.
    private static func fullscreenRect(on screen: NSScreen) -> NSRect? {
        guard let list = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] else { return nil }

        let myPid = ProcessInfo.processInfo.processIdentifier
        let frame = screen.frame
        let minHeight = screen.visibleFrame.height + 1        // taller than a zoomed window
        let flipHeight = NSScreen.screens.first?.frame.height ?? frame.height
        var best: NSRect?

        for w in list {
            guard let layer = (w[kCGWindowLayer as String] as? NSNumber)?.intValue, layer == 0,
                  let pid = (w[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value, pid != myPid,
                  let bounds = w[kCGWindowBounds as String] as? [String: Any],
                  let cgX = (bounds["X"] as? NSNumber)?.doubleValue,
                  let cgY = (bounds["Y"] as? NSNumber)?.doubleValue,
                  let width = (bounds["Width"] as? NSNumber)?.doubleValue,
                  let height = (bounds["Height"] as? NSNumber)?.doubleValue,
                  CGFloat(width) >= frame.width - 1,
                  CGFloat(height) >= minHeight,
                  CGFloat(cgY + height) >= flipHeight - 1     // runs to the screen bottom
            else { continue }

            // CG coordinates are y-down from the top of the primary display
            let rect = NSRect(x: CGFloat(cgX),
                              y: flipHeight - CGFloat(cgY + height),
                              width: CGFloat(width),
                              height: CGFloat(height))
            if best == nil || rect.height > best!.height { best = rect }
        }
        return best
    }

    // MARK: - Registry sync

    /// stable cap color per session name, with deterministic collision probing
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

    private var prevBusyCount = 0
    private var lastWaveAt: CFTimeInterval = 0

    /// unique royal names among live crabs (numeral bumps on collision)
    private(set) var royalNames: [String: String] = [:]

    private func assignRoyalNames(_ sessions: [SessionInfo]) {
        var used = Set<String>()
        var out: [String: String] = [:]
        for s in sessions.sorted(by: { $0.name < $1.name }) {
            let kind = ModelKind.parse(s.model)
            var shift = 0
            var royal = PetView.royalName(sessionName: s.name, model: kind)
            while used.contains(royal) && shift < 12 {
                shift += 1
                royal = PetView.royalName(sessionName: s.name, model: kind, numeralShift: shift)
            }
            used.insert(royal)
            out[s.sessionId] = royal
        }
        royalNames = out
    }

    func sync(_ sessions: [SessionInfo]) {
        lastSessions = sessions
        assignCapColors(sessions)
        assignRoyalNames(sessions)

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
            if let royal = royalNames[info.sessionId] {
                pets[info.sessionId]?.setRoyal(royal)
            }
        }
        for (id, pet) in pets where !ids.contains(id) {
            pets.removeValue(forKey: id)
            despawn(pet)
        }
        onCountChanged?(pets.count)
    }

    private func addPet(_ info: SessionInfo) {
        let pet = PetView(info: info, roamArea: roamArea)   // places itself on the perimeter
        pet.onConfetti = { [weak self] p in self?.confetti(over: p) }
        pet.onBeerStarted = { [weak self] p in self?.maybeClink(around: p) }
        contentView.addSubview(pet)
        pets[info.sessionId] = pet
    }

    /// a nearby crab joins the beer for a toast 🍻
    private func maybeClink(around pet: PetView) {
        for other in pets.values where other !== pet {
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

    private func despawn(_ pet: PetView) {
        pet.cleanup()
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.35
            pet.animator().alphaValue = 0
        }, completionHandler: {
            pet.removeFromSuperview()
        })
    }

    private func tick() {
        let now = CACurrentMediaTime()
        for pet in pets.values {
            pet.tick(now: now)
        }
        updateMouseInteractivity()
        tickCount += 1
        if tickCount % 45 == 0 { checkGreetings(now: now) }
        if tickCount % 20 == 0 { checkSeparation() }
        if tickCount % 60 == 0 { layoutOverlay() }   // catch fullscreen/Dock changes
    }

    /// crabs shouldn't stack — too-close pairs get nudged apart
    private func checkSeparation() {
        let list = Array(pets.values)
        guard list.count > 1 else { return }
        for i in 0..<list.count {
            for j in (i + 1)..<list.count {
                let a = list[i], b = list[j]
                let dx = a.frame.midX - b.frame.midX
                let dy = a.frame.midY - b.frame.midY
                // wide enough that the royal-name pills stop overlapping too
                if dx * dx + dy * dy < 105 * 105 {
                    a.separate(from: b)
                }
            }
        }
    }

    /// The overlay is click-through except when the cursor is over a crab's body —
    /// then it accepts the click (PetView.mouseDown focuses that session's terminal).
    private var lastHoveredId: String?

    private func updateMouseInteractivity() {
        let mouse = NSEvent.mouseLocation
        let local = NSPoint(x: mouse.x - overlayWindow.frame.origin.x,
                            y: mouse.y - overlayWindow.frame.origin.y)
        var hoveredPet: PetView?
        for pet in pets.values {
            let r = pet.bodyHitRect.offsetBy(dx: pet.frame.origin.x, dy: pet.frame.origin.y)
            if r.contains(local) { hoveredPet = pet; break }
        }
        let hover = hoveredPet != nil
        if overlayWindow.ignoresMouseEvents == hover {
            overlayWindow.ignoresMouseEvents = !hover
        }
        if let pet = hoveredPet, pet.sessionId != lastHoveredId {
            pet.hoverPoke()   // startled little jump when the cursor arrives
        }
        lastHoveredId = hoveredPet?.sessionId
    }

    // MARK: - Hook events

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
                despawn(pet)
                onCountChanged?(pets.count)
            }
        case "Notification":
            let msg = (event.payload["message"] as? String) ?? "needs you!"
            pets[event.sessionId]?.showNote(String(msg.prefix(38)))
        case "SubagentStart":
            if let agentId = event.payload["agent_id"] as? String {
                pets[event.sessionId]?.addBaby(agentId: agentId)
            }
        case "SubagentStop":
            if let agentId = event.payload["agent_id"] as? String {
                pets[event.sessionId]?.removeBaby(agentId: agentId)
            }
        case "StopFailure":
            pets[event.sessionId]?.showNote("⚠️")
        case "PreCompact":
            pets[event.sessionId]?.compactStart()
        case "PostCompact":
            pets[event.sessionId]?.compactEnd()
        default:
            break
        }
    }

    // MARK: - Crab greetings (ambient: nearby crabs wave at each other)

    private var greetCooldown: [String: CFTimeInterval] = [:]
    private var tickCount = 0

    private func checkGreetings(now: CFTimeInterval) {
        let list = Array(pets.values)
        guard list.count > 1 else { return }
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
                    a.showNote("👋")
                    b.showNote("👋")
                }
            }
        }
    }

    func testCelebrate() {
        pets.values.randomElement()?.celebrate()
    }

    func testBeer() {
        pets.values.randomElement()?.beerBreak()
    }

    func testTrick() {
        pets.values.randomElement()?.doTrick(forced: 1)   // balloon
    }

    /// Debug: renders the overlay's layer tree to App Support/ClaudePet/snapshot.png.
    /// Needs no screen-recording permission (we only render our own layers).
    func saveSnapshot() {
        guard let view = overlayWindow.contentView, let rootLayer = view.layer else { return }
        let w = Int(view.bounds.width), h = Int(view.bounds.height)
        guard w > 0, h > 0,
              let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let gctx = NSGraphicsContext(bitmapImageRep: rep)
        else { return }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = gctx
        rootLayer.render(in: gctx.cgContext)
        NSGraphicsContext.restoreGraphicsState()
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClaudePet", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: dir.appendingPathComponent("snapshot.png"))
        }
    }

    // MARK: - Confetti

    private func confetti(over pet: PetView) {
        guard let layer = contentView.layer else { return }
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
}
