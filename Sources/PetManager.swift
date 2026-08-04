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
        overlayWindow.setFrame(screen.frame, display: true)
        let visible = screen.visibleFrame
        roamArea = RoamArea(
            minX: visible.minX - screen.frame.minX + 10,
            maxX: visible.maxX - screen.frame.minX - PetView.viewSize.width - 10,
            minY: max(0, visible.minY - screen.frame.minY + 2),
            maxY: visible.maxY - screen.frame.minY - PetView.viewSize.height - 6
        )
        for pet in pets.values {
            pet.roamArea = roamArea
            let x = min(max(pet.frame.origin.x, roamArea.minX), roamArea.maxX)
            let y = min(max(pet.frame.origin.y, roamArea.minY), roamArea.maxY)
            pet.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    // MARK: - Registry sync

    func sync(_ sessions: [SessionInfo]) {
        lastSessions = sessions
        let ids = Set(sessions.map { $0.sessionId })
        for info in sessions {
            if let pet = pets[info.sessionId] {
                pet.update(info: info)
            } else {
                addPet(info)
            }
        }
        for (id, pet) in pets where !ids.contains(id) {
            pets.removeValue(forKey: id)
            despawn(pet)
        }
        onCountChanged?(pets.count)
    }

    private func addPet(_ info: SessionInfo) {
        let pet = PetView(info: info, roamArea: roamArea)
        pet.onConfetti = { [weak self] p in self?.confetti(over: p) }
        let x = CGFloat.random(in: roamArea.minX...max(roamArea.minX + 1, roamArea.maxX))
        let y = CGFloat.random(in: roamArea.minY...max(roamArea.minY + 1, roamArea.maxY))
        pet.setFrameOrigin(NSPoint(x: x, y: y))
        contentView.addSubview(pet)
        pets[info.sessionId] = pet
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
    }

    // MARK: - Hook events

    func handle(_ event: HookEvent) {
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
        default:
            break
        }
    }

    func testCelebrate() {
        pets.values.randomElement()?.celebrate()
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
