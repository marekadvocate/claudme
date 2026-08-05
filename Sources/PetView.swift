import AppKit
import QuartzCore

enum PetState: Equatable {
    case idle, working, waiting, sleeping, celebrating
}

/// which Claude model the session runs — read from the transcript tail
enum ModelKind: String {
    case fable, opus, sonnet, haiku, unknown

    static func parse(_ s: String?) -> ModelKind {
        guard let s = s?.lowercased(), !s.isEmpty else { return .unknown }
        if s.contains("fable") { return .fable }
        if s.contains("opus") { return .opus }
        if s.contains("sonnet") { return .sonnet }
        if s.contains("haiku") { return .haiku }
        return .unknown
    }

    /// bigger model → bigger crab
    var sizeFactor: CGFloat {
        switch self {
        case .fable: return 1.12
        case .opus: return 1.07
        case .haiku: return 0.85
        default: return 1.0
        }
    }

    /// bigger model → deeper terracotta
    var bodyColor: NSColor {
        switch self {
        case .fable: return NSColor(srgbRed: 0.72, green: 0.33, blue: 0.20, alpha: 1)
        case .opus: return NSColor(srgbRed: 0.79, green: 0.41, blue: 0.26, alpha: 1)
        case .haiku: return NSColor(srgbRed: 0.93, green: 0.63, blue: 0.50, alpha: 1)
        default: return PetView.claudeOrange
        }
    }
}

/// Perimeter ring the pets crawl on (overlay-local coordinates, y-up).
struct RoamArea: Equatable {
    var minX: CGFloat
    var maxX: CGFloat
    var minY: CGFloat
    var maxY: CGFloat
}

/// Pixel-art Clawd — geometry extracted from Claude Code's own TUI welcome art:
///  █████████
/// ██▄█████▄██
/// █ █   █ █
final class PetView: NSView {
    static let claudeOrange = NSColor(srgbRed: 217/255, green: 119/255, blue: 87/255, alpha: 1)
    static let inkColor = NSColor(srgbRed: 30/255, green: 30/255, blue: 28/255, alpha: 1)
    static let viewSize = NSSize(width: 150, height: 170)

    // pixel grid: 11 × 6, pixel size 7 → content 77 × 42 centered in an 80×80 body box
    static let px: CGFloat = 7
    static let gridW = 11, gridH = 6

    let sessionId: String
    private(set) var info: SessionInfo
    var roamArea: RoamArea
    var onConfetti: ((PetView) -> Void)?

    private(set) var state: PetState = .idle
    private var celebrateUntil: CFTimeInterval = 0
    private var hookWorkingUntil: CFTimeInterval = 0

    // layers — body container rotates to the edge it crawls on; pill/bubble stay upright
    private let body = CALayer()
    private let shell = CAShapeLayer()      // Clawd's body pixels
    private let legs = CAShapeLayer()       // two-frame scuttle
    private let cap = CAShapeLayer()        // colored cap = stable session identity
    private let eyeLeft = CALayer()
    private let eyeRight = CALayer()
    private let glintLeft = CALayer()
    private let glintRight = CALayer()
    private let namePill = NSTextField(labelWithString: "")
    private let bubble = BubbleView()

    private static let legsFrameA = pixelPath(cells: legCellsA)
    private static let legsFrameB = pixelPath(cells: legCellsB)
    private var legPhase = 0
    private var currentAngle: CGFloat = 0
    private var currentScale: CGFloat = 1
    private var currentSegment = -1

    // behavior — crawl along the screen edge ring
    private var perimT: CGFloat = -1
    private var slideDir: CGFloat = 1
    private var slideRemaining: CGFloat = 0
    private var speed: CGFloat = 40
    private var nextDecisionAt: CFTimeInterval = 0
    private var nextHopAt: CFTimeInterval = 0
    private var nextChatterAt: CFTimeInterval = 0
    private var blinkTimer: Timer?

    // beer break
    private var beerUntil: CFTimeInterval = 0
    private var nextBeerAt: CFTimeInterval = CACurrentMediaTime() + Double.random(in: 90...300)
    private var beerMug: CALayer?
    var onBeerStarted: ((PetView) -> Void)?   // manager checks for a clink partner

    // rare tricks + idle mumbles + hover pokes
    private var trickUntil: CFTimeInterval = 0
    private var nextTrickAt: CFTimeInterval = CACurrentMediaTime() + Double.random(in: 300...900)
    private var nextMumbleAt: CFTimeInterval = CACurrentMediaTime() + Double.random(in: 180...480)
    private var lastPokeAt: CFTimeInterval = 0
    private static let mumbles = ["🦀", "hmm…", "☕", "šup šup", "42", "vibe"]

    // model + effort ("how wired is this crab")
    private var modelKind: ModelKind = .unknown
    private var effortLevel: String?
    private var steamLayer: CALayer?

    /// 0 chill … 3 full tweak
    private func wiredness() -> Int {
        switch effortLevel {
        case "max": return 3
        case "xhigh": return 2
        case "high": return 1
        default: return 0
        }
    }

    private var mumblePool: [String] {
        switch wiredness() {
        case 3: return ["🚀", "!!!", "brrr", "MAX"]
        case 2: return ["🔥", "⚡️", "hmm!"]
        default: return Self.mumbles
        }
    }

    // CC feature states: permission mode (glasses), remote (satellite), compaction
    private var permissionMode: String?
    private var accessoryLayer: CAShapeLayer?
    private var satelliteLayer: CALayer?
    private var compactUntil: CFTimeInterval = 0

    // MARK: - Royal names (George Fable V)

    private static let royalFirstNames = [
        "George", "Henrich", "Ludovít", "Karol", "Maximilián", "Rudolf",
        "Leopold", "Ferdinand", "Albrecht", "Václav", "Otakar", "Kazimír",
        "Boleslav", "Vratislav", "Svätopluk", "Mojmír", "Rastislav", "Pribina",
        "Žofia", "Mária", "Alžbeta", "Kunigunda", "Beatrix", "Hedviga",
    ]
    private static let romanNumerals = ["I", "II", "III", "IV", "V", "VI",
                                        "VII", "VIII", "IX", "X", "XI", "XII"]

    /// stable pompous identity: first name + numeral from the session-name hash,
    /// surname = the model; numeralShift resolves collisions among live crabs
    static func royalName(sessionName: String, model: ModelKind, numeralShift: Int = 0) -> String {
        var hash: UInt64 = 1469598103934665603
        for b in sessionName.utf8 { hash = (hash ^ UInt64(b)) &* 1099511628211 }
        let first = royalFirstNames[Int(hash % UInt64(royalFirstNames.count))]
        let idx = (Int((hash >> 8) % UInt64(romanNumerals.count)) + numeralShift) % romanNumerals.count
        let surname = model == .unknown ? "Clawd" : model.rawValue.capitalized
        return "\(first) \(surname) \(romanNumerals[idx])"
    }

    private var royalOverride: String?

    var royalName: String {
        royalOverride ?? Self.royalName(sessionName: info.name, model: modelKind)
    }

    func setRoyal(_ name: String) {
        guard name != royalOverride else { return }
        royalOverride = name
        refreshPill()
    }

    // MARK: - Init

    init(info: SessionInfo, roamArea: RoamArea) {
        self.sessionId = info.sessionId
        self.info = info
        self.roamArea = roamArea
        super.init(frame: NSRect(origin: .zero, size: Self.viewSize))
        wantsLayer = true
        modelKind = ModelKind.parse(info.model)

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2

        body.bounds = CGRect(x: 0, y: 0, width: 80, height: 80)
        body.position = CGPoint(x: 75, y: 60)
        body.shadowColor = NSColor.black.cgColor
        body.shadowOpacity = 0.14
        body.shadowRadius = 3
        body.shadowOffset = CGSize(width: 0, height: -2)
        layer!.addSublayer(body)

        shell.frame = body.bounds
        shell.path = Self.pixelPath(cells: Self.shellCells)
        shell.fillColor = Self.claudeOrange.cgColor
        body.addSublayer(shell)

        legs.frame = body.bounds
        legs.path = Self.legsFrameA
        legs.fillColor = Self.claudeOrange.cgColor
        body.addSublayer(legs)

        // pixel baseball cap on the head, in the session's identity color
        cap.frame = body.bounds
        cap.path = Self.pixelPath(cells: Self.capCells)
        cap.fillColor = Self.capColor(for: info.name).cgColor
        body.addSublayer(cap)

        // eyes = the two ▄ cells of the TUI art (grid row 3, cols 2 & 8)
        for (eye, glint, col) in [(eyeLeft, glintLeft, 2), (eyeRight, glintRight, 8)] {
            let r = Self.cellRect(col: col, row: 3)
            eye.backgroundColor = Self.inkColor.cgColor
            eye.bounds = CGRect(x: 0, y: 0, width: Self.px, height: Self.px)
            eye.position = CGPoint(x: r.midX, y: r.midY)
            body.addSublayer(eye)
            glint.backgroundColor = NSColor(white: 1, alpha: 0.9).cgColor
            glint.bounds = CGRect(x: 0, y: 0, width: 2.2, height: 2.2)
            glint.position = CGPoint(x: r.midX + 1.8, y: r.midY + 1.8)
            body.addSublayer(glint)
        }

        for l in [layer!, body, shell, legs, cap, eyeLeft, eyeRight, glintLeft, glintRight] {
            l.contentsScale = scaleFactor
        }

        // gentle breathing
        let breathe = CABasicAnimation(keyPath: "transform.scale")
        breathe.fromValue = 1.0
        breathe.toValue = 1.025
        breathe.duration = 1.8
        breathe.autoreverses = true
        breathe.repeatCount = .infinity
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shell.add(breathe, forKey: "breathe")

        namePill.font = .systemFont(ofSize: 9, weight: .semibold)
        namePill.textColor = NSColor(white: 1, alpha: 0.92)
        namePill.alignment = .center
        namePill.wantsLayer = true
        namePill.layer!.backgroundColor = NSColor(white: 0, alpha: 0.30).cgColor
        namePill.layer!.cornerRadius = 6.5
        namePill.alphaValue = 0.8
        addSubview(namePill)
        applyModelLook(animated: false)
        refreshPill()

        bubble.setFrameOrigin(NSPoint(x: 45, y: 90))
        addSubview(bubble)

        placeOnPerimeter()
        startBlinking()
        applyState(mappedState(), animated: false)
        spawnPop()
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: - Clawd pixel geometry (grid: x = col from left, y = row from TOP)

    private static let shellCells: [(Int, Int)] = {
        var c: [(Int, Int)] = []
        for x in 1...9 { c.append((x, 0)) }                 //  █████████
        for x in 1...9 { c.append((x, 1)) }                 //  (top row is 1 char = 2 px tall)
        for x in 0...10 { c.append((x, 2)) }                // ███████████
        for x in 0...10 where x != 2 && x != 8 { c.append((x, 3)) }  // ██▄█████▄██ (eyes cut out)
        return c
    }()

    /// baseball cap: crown on top of the head + visor sticking out to the right
    /// (negative rows extend above the TUI art's grid)
    private static let capCells: [(Int, Int)] = {
        var c: [(Int, Int)] = []
        for x in 3...7 { c.append((x, -2)) }     // crown top
        for x in 2...8 { c.append((x, -1)) }     // crown base
        c.append((9, -1))                        // visor
        c.append((10, -1))
        return c
    }()

    private static let legCellsA: [(Int, Int)] = [(1, 4), (3, 4), (7, 4), (9, 4),
                                                  (1, 5), (3, 5), (7, 5), (9, 5)]
    private static let legCellsB: [(Int, Int)] = [(2, 4), (4, 4), (6, 4), (8, 4),
                                                  (2, 5), (4, 5), (6, 5), (8, 5)]

    private static func cellRect(col: Int, row: Int) -> CGRect {
        let originX = (80 - CGFloat(gridW) * px) / 2
        let topY = 80 - (80 - CGFloat(gridH) * px) / 2
        return CGRect(x: originX + CGFloat(col) * px,
                      y: topY - CGFloat(row + 1) * px,
                      width: px, height: px)
    }

    private static func pixelPath(cells: [(Int, Int)]) -> CGPath {
        let path = CGMutablePath()
        for (col, row) in cells {
            path.addRect(cellRect(col: col, row: row))
        }
        return path
    }

    // MARK: - Cap colors (stable per session name → memorable identity)

    static let capPalette: [NSColor] = [
        NSColor(srgbRed: 0.12, green: 0.23, blue: 0.54, alpha: 1),   // navy
        NSColor(srgbRed: 0.05, green: 0.58, blue: 0.53, alpha: 1),   // teal
        NSColor(srgbRed: 0.98, green: 0.80, blue: 0.08, alpha: 1),   // yellow
        NSColor(srgbRed: 0.49, green: 0.23, blue: 0.93, alpha: 1),   // purple
        NSColor(srgbRed: 0.09, green: 0.64, blue: 0.29, alpha: 1),   // green
        NSColor(srgbRed: 0.93, green: 0.28, blue: 0.60, alpha: 1),   // pink
        NSColor(srgbRed: 0.05, green: 0.65, blue: 0.91, alpha: 1),   // sky
        NSColor(srgbRed: 0.86, green: 0.15, blue: 0.15, alpha: 1),   // red
        NSColor(srgbRed: 0.96, green: 0.94, blue: 0.91, alpha: 1),   // cream
        NSColor(srgbRed: 0.15, green: 0.15, blue: 0.14, alpha: 1),   // ink
    ]

    static func capIndex(for name: String) -> Int {
        var hash: UInt64 = 5381
        for b in name.utf8 { hash = hash &* 33 &+ UInt64(b) }
        return Int(hash % UInt64(capPalette.count))
    }

    static func capColor(for name: String) -> NSColor {
        capPalette[capIndex(for: name)]
    }

    func setCap(_ color: NSColor) {
        cap.fillColor = color.cgColor
    }

    // MARK: - Registry updates

    func update(info newInfo: SessionInfo) {
        let oldStatus = info.status
        let nameChanged = newInfo.name != info.name
        let modelChanged = newInfo.model != info.model
        info = newInfo
        if nameChanged {
            cap.fillColor = Self.capColor(for: newInfo.name).cgColor
        }
        if modelChanged {
            modelKind = ModelKind.parse(newInfo.model)
            applyModelLook(animated: true)
        }
        if nameChanged || modelChanged {
            refreshPill()
        }
        if oldStatus == "busy" && newInfo.status == "idle" {
            hookWorkingUntil = 0
        }
        if state != .celebrating {
            let mapped = mappedState()
            if mapped != state { applyState(mapped, animated: true) }
        }
    }

    /// hook events carry the session's effort level
    func setEffort(_ level: String) {
        let norm = level.lowercased()
        guard norm != effortLevel else { return }
        effortLevel = norm
        refreshPill()
        updateWired()
    }

    /// permission mode → eyewear: plan = scholar glasses, bypass = shades 😎
    func setPermissionMode(_ mode: String) {
        guard mode != permissionMode else { return }
        permissionMode = mode
        accessoryLayer?.removeFromSuperlayer()
        accessoryLayer = nil

        let left = Self.cellRect(col: 2, row: 3)
        let right = Self.cellRect(col: 8, row: 3)
        let layer = CAShapeLayer()
        layer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2

        switch mode {
        case "bypassPermissions":
            // black shades: lenses + bridge + arms
            let path = CGMutablePath()
            path.addRoundedRect(in: left.insetBy(dx: -2, dy: -1.5), cornerWidth: 2, cornerHeight: 2)
            path.addRoundedRect(in: right.insetBy(dx: -2, dy: -1.5), cornerWidth: 2, cornerHeight: 2)
            path.addRect(CGRect(x: left.maxX, y: left.midY, width: right.minX - left.maxX, height: 2))
            path.addRect(CGRect(x: left.minX - 6, y: left.midY, width: 5, height: 2))
            path.addRect(CGRect(x: right.maxX + 1, y: right.midY, width: 5, height: 2))
            layer.path = path
            layer.fillColor = NSColor(white: 0.05, alpha: 1).cgColor
        case "plan":
            // round scholar glasses
            let path = CGMutablePath()
            path.addEllipse(in: left.insetBy(dx: -2.5, dy: -2.5))
            path.addEllipse(in: right.insetBy(dx: -2.5, dy: -2.5))
            path.move(to: CGPoint(x: left.maxX + 2.5, y: left.midY + 2))
            path.addLine(to: CGPoint(x: right.minX - 2.5, y: right.midY + 2))
            layer.path = path
            layer.fillColor = nil
            layer.strokeColor = Self.inkColor.cgColor
            layer.lineWidth = 1.6
        default:
            return
        }
        body.addSublayer(layer)
        accessoryLayer = layer
    }

    /// remote connection → a little satellite on an elliptical orbit 🛰️
    func setRemote(_ on: Bool) {
        if on, satelliteLayer == nil {
            let squash = CALayer()
            squash.bounds = CGRect(x: 0, y: 0, width: 80, height: 80)
            squash.position = CGPoint(x: 40, y: 44)
            squash.transform = CATransform3DMakeScale(1, 0.45, 1)

            let spinner = CALayer()
            spinner.bounds = squash.bounds
            spinner.position = CGPoint(x: 40, y: 40)

            let sat = CALayer()
            sat.position = CGPoint(x: 92, y: 40)
            let core = CALayer()
            core.backgroundColor = NSColor(white: 0.78, alpha: 1).cgColor
            core.bounds = CGRect(x: 0, y: 0, width: 6, height: 6)
            core.cornerRadius = 1.5
            core.position = .zero
            let panelLeft = CALayer()
            panelLeft.backgroundColor = NSColor(srgbRed: 0.2, green: 0.45, blue: 0.85, alpha: 1).cgColor
            panelLeft.bounds = CGRect(x: 0, y: 0, width: 8, height: 3.4)
            panelLeft.position = CGPoint(x: -8, y: 0)
            let panelRight = CALayer()
            panelRight.backgroundColor = panelLeft.backgroundColor
            panelRight.bounds = panelLeft.bounds
            panelRight.position = CGPoint(x: 8, y: 0)
            sat.addSublayer(panelLeft)
            sat.addSublayer(panelRight)
            sat.addSublayer(core)
            for l in [core, panelLeft, panelRight] { l.contentsScale = NSScreen.main?.backingScaleFactor ?? 2 }

            spinner.addSublayer(sat)
            squash.addSublayer(spinner)
            body.addSublayer(squash)

            let orbit = CABasicAnimation(keyPath: "transform.rotation.z")
            orbit.byValue = -2 * CGFloat.pi
            orbit.duration = 7
            orbit.repeatCount = .infinity
            spinner.add(orbit, forKey: "orbit")
            satelliteLayer = squash
        } else if !on, let s = satelliteLayer {
            satelliteLayer = nil
            s.removeFromSuperlayer()
        }
    }

    // MARK: - Context compaction (the crab digests its context)

    func compactStart() {
        guard body.animation(forKey: "compacting") == nil else { return }
        compactUntil = CACurrentMediaTime() + 120   // safety timeout
        bubble.show("🗜️", for: nil)
        let chew = CABasicAnimation(keyPath: "transform.scale.y")
        chew.fromValue = 0.94
        chew.toValue = 1.06
        chew.duration = 0.4
        chew.autoreverses = true
        chew.repeatCount = .infinity
        body.add(chew, forKey: "compacting")
    }

    func compactEnd() {
        guard body.animation(forKey: "compacting") != nil else { return }
        compactUntil = 0
        body.removeAnimation(forKey: "compacting")
        bubble.show("grg 😮‍💨", for: 2.2)
    }

    private func applyModelLook(animated: Bool) {
        shell.fillColor = modelKind.bodyColor.cgColor
        legs.fillColor = modelKind.bodyColor.cgColor
        setBodyScale(Self.scale(for: state), animated: animated)
    }

    /// effort visuals: dilated eyes, vibration, steam from the head
    private func updateWired() {
        applyEyes()
        let w = wiredness()
        body.removeAnimation(forKey: "wiredJitter")
        if w >= 2 && state != .sleeping {
            let jitter = CAKeyframeAnimation(keyPath: "transform.translation.x")
            let amp: CGFloat = w == 3 ? 1.6 : 0.7
            jitter.values = [0, amp, -amp, amp * 0.6, -amp * 0.6, 0]
            jitter.duration = w == 3 ? 0.11 : 0.24
            jitter.repeatCount = .infinity
            body.add(jitter, forKey: "wiredJitter")
        }
        updateSteam()
    }

    private func updateSteam() {
        let active = state == .working && wiredness() >= 2
        if active, steamLayer == nil {
            let group = CALayer()
            for (i, dx) in [CGFloat(31), CGFloat(47)].enumerated() {
                let puff = CALayer()
                puff.backgroundColor = NSColor(white: 0.92, alpha: 0.85).cgColor
                puff.bounds = CGRect(x: 0, y: 0, width: 5, height: 5)
                puff.cornerRadius = 2.5
                puff.position = CGPoint(x: dx, y: 79)
                puff.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
                group.addSublayer(puff)
                let up = CABasicAnimation(keyPath: "transform.translation.y")
                up.fromValue = 0
                up.toValue = 14
                up.duration = 1.0
                up.repeatCount = .infinity
                up.timeOffset = Double(i) * 0.5
                puff.add(up, forKey: "up")
                let fade = CABasicAnimation(keyPath: "opacity")
                fade.fromValue = 0.9
                fade.toValue = 0
                fade.duration = 1.0
                fade.repeatCount = .infinity
                fade.timeOffset = Double(i) * 0.5
                puff.add(fade, forKey: "fade")
            }
            body.addSublayer(group)
            steamLayer = group
        } else if !active, let s = steamLayer {
            steamLayer = nil
            s.removeFromSuperlayer()
        }
    }

    /// eye look: closed when sleeping, dilated when wired
    private func applyEyes() {
        let closed = state == .sleeping
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let t: CATransform3D
        if closed {
            t = CATransform3DMakeScale(1, 0.15, 1)
        } else {
            let wide: CGFloat = [1, 1, 1.18, 1.42][wiredness()]
            t = CATransform3DMakeScale(wide, wide, 1)
        }
        eyeLeft.transform = t
        eyeRight.transform = t
        glintLeft.opacity = closed ? 0 : 1
        glintRight.opacity = closed ? 0 : 1
        CATransaction.commit()
    }

    private func mappedState() -> PetState {
        switch info.status {
        case "idle":
            if CACurrentMediaTime() < hookWorkingUntil { return .working }
            let ageMs = Date().timeIntervalSince1970 * 1000 - max(info.statusUpdatedAt, info.updatedAt)
            return ageMs > 10 * 60 * 1000 ? .sleeping : .idle
        case let s where s.hasPrefix("waiting") || s == "needs_input" || s == "blocked" || s == "paused":
            return .waiting
        default:
            return .working
        }
    }

    // MARK: - Hook-driven moments

    func workingPulse() {
        hookWorkingUntil = CACurrentMediaTime() + 120
        if state == .idle || state == .sleeping {
            applyState(.working, animated: true)
        }
    }

    func celebrate() {
        guard state != .celebrating else { return }
        hookWorkingUntil = 0
        applyState(.celebrating, animated: true)
        celebrateUntil = CACurrentMediaTime() + 3.2
        bubble.show("✓", for: 3.0)
        let hop = CAKeyframeAnimation(keyPath: "transform.translation.y")
        hop.values = [0, 30, 0, 20, 0]
        hop.keyTimes = [0, 0.28, 0.55, 0.78, 1]
        hop.duration = 0.85
        body.add(hop, forKey: "hop")
        onConfetti?(self)
    }

    func showNote(_ text: String) {
        bubble.show(text, for: 6)
        smallHop()
    }

    // MARK: - State

    private static func scale(for state: PetState) -> CGFloat {
        switch state {
        case .idle, .sleeping: return 0.8
        case .working: return 1.0
        case .waiting: return 1.02
        case .celebrating: return 1.3
        }
    }

    private func applyState(_ new: PetState, animated: Bool) {
        let old = state
        state = new
        setBodyScale(Self.scale(for: new), animated: animated)
        applyEyes()

        if (old == .waiting || old == .sleeping) && new != .waiting && new != .sleeping {
            bubble.hide()
        }
        switch new {
        case .waiting:
            slideRemaining = 0
            bubble.show("!", for: nil)
            nextHopAt = CACurrentMediaTime() + 0.4
        case .sleeping:
            slideRemaining = 0      // tick crawls us down to the bottom edge
            bubble.show("z Z", for: nil)
        case .working:
            nextChatterAt = CACurrentMediaTime() + Double.random(in: 8...20)
        default:
            break
        }
        nextDecisionAt = 0
        updateWired()
    }

    // MARK: - Body transform (scale + edge rotation)

    private func updateBodyTransform(animated: Bool, keyPath: String, from: Any?) {
        let t = CATransform3DRotate(CATransform3DMakeScale(currentScale, currentScale, 1),
                                    currentAngle, 0, 0, 1)
        if animated {
            let anim = CASpringAnimation(keyPath: keyPath)
            anim.fromValue = from
            anim.damping = 12
            anim.duration = anim.settlingDuration
            body.add(anim, forKey: keyPath)
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        body.transform = t
        CATransaction.commit()
    }

    private func setBodyScale(_ s: CGFloat, animated: Bool) {
        let from = (body.presentation() ?? body).value(forKeyPath: "transform.scale.x")
        currentScale = s * modelKind.sizeFactor   // bigger model → bigger crab
        updateBodyTransform(animated: animated, keyPath: "transform.scale", from: from)
    }

    private func setBodyAngle(_ a: CGFloat, animated: Bool) {
        let from = (body.presentation() ?? body).value(forKeyPath: "transform.rotation.z")
        currentAngle = a
        updateBodyTransform(animated: animated, keyPath: "transform.rotation.z", from: from)
    }

    private func spawnPop() {
        let spring = CASpringAnimation(keyPath: "transform.scale")
        spring.fromValue = 0.01
        spring.toValue = Self.scale(for: state)
        spring.damping = 10
        spring.initialVelocity = 5
        spring.duration = spring.settlingDuration
        body.add(spring, forKey: "spawn")
    }

    // MARK: - Behavior tick (30 fps)

    func tick(now: CFTimeInterval) {
        if perimT < 0 { placeOnPerimeter() }
        purgeExpiredBabies(now: now)
        if compactUntil > 0 && now > compactUntil { compactEnd() }

        if state == .celebrating && now > celebrateUntil {
            applyState(mappedState(), animated: true)
        }

        switch state {
        case .celebrating:
            break
        case .waiting:
            if now >= nextHopAt {
                nextHopAt = now + Double.random(in: 2.2...3.4)
                smallHop()
            }
        case .sleeping:
            crawlTowardBottom()
        case .idle, .working:
            if now < beerUntil || now < trickUntil {
                break   // enjoying a beer / mid-trick, no crawling
            }
            if now >= nextBeerAt {
                beerBreak(now: now)
                break
            }
            if state == .idle && now >= nextTrickAt {
                doTrick(now: now)
                break
            }
            if slideRemaining > 0 {
                crawl(by: speed / 30)
                if slideRemaining <= 0 {
                    legPhase = 0
                    legs.path = Self.legsFrameA
                    nextDecisionAt = now + (state == .working ? Double.random(in: 0.3...1.2)
                                                              : Double.random(in: 2...7))
                }
            } else if now >= nextDecisionAt {
                decide(now: now)
            }
            if state == .working && now >= nextChatterAt {
                nextChatterAt = now + Double.random(in: 12...25)
                bubble.show("…", for: 2.2)
            }
            if state == .idle && now >= nextMumbleAt {
                nextMumbleAt = now + Double.random(in: 180...480)
                bubble.show(mumblePool.randomElement()!, for: 2.4)
            }
        }
    }

    // MARK: - Social & ambient reactions

    /// staggered hop for the all-sessions-done stadium wave
    func waveHop() {
        smallHop()
    }

    /// cursor moved onto the crab — startled little jump (cooldown so it stays cute)
    func hoverPoke() {
        let now = CACurrentMediaTime()
        guard now - lastPokeAt > 8 else { return }
        lastPokeAt = now
        smallHop()
        blinkOnce()
    }

    /// beer buddy toast
    func showClink() {
        bubble.show("🍻", for: 2.2)
    }

    var perimeterPosition: CGFloat { perimT }

    /// crabs shouldn't pile up — slide away from a too-close neighbour
    func separate(from other: PetView) {
        let now = CACurrentMediaTime()
        guard state == .idle || state == .working,
              now >= beerUntil, now >= trickUntil else { return }
        let delta = Self.shortestDelta(from: other.perimeterPosition, to: perimT, length: perimeterLength)
        slideDir = delta >= 0 ? 1 : -1
        if slideRemaining < 50 { slideRemaining = 50 }
        speed = max(speed, 36)
    }

    // MARK: - Rare tricks (spin / balloon ride)

    func doTrick(now: CFTimeInterval = CACurrentMediaTime(), forced: Int? = nil) {
        guard beerMug == nil, now >= trickUntil else { return }
        nextTrickAt = now + Double.random(in: 600...1500)
        slideRemaining = 0
        legPhase = 0
        legs.path = Self.legsFrameA
        let kind = forced ?? Int.random(in: 0...1)
        if kind == 0 {
            spinTrick(now: now)
        } else {
            balloonTrick(now: now)
        }
    }

    private func spinTrick(now: CFTimeInterval) {
        trickUntil = now + 1.3
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.byValue = 2 * CGFloat.pi
        spin.duration = 0.9
        spin.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        body.add(spin, forKey: "trickSpin")
    }

    /// grabs a balloon, floats up off the edge, drifts back down
    private func balloonTrick(now: CFTimeInterval) {
        trickUntil = now + 5.0
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2

        let group = CALayer()
        let string = CAShapeLayer()
        let stringPath = CGMutablePath()
        stringPath.move(to: CGPoint(x: 40, y: 85))
        stringPath.addLine(to: CGPoint(x: 40, y: 75))
        string.path = stringPath
        string.strokeColor = NSColor(white: 0.25, alpha: 0.8).cgColor
        string.lineWidth = 1
        group.addSublayer(string)

        let balloon = CALayer()
        balloon.backgroundColor = NSColor(srgbRed: 0.88, green: 0.20, blue: 0.25, alpha: 1).cgColor
        balloon.bounds = CGRect(x: 0, y: 0, width: 13, height: 15)
        balloon.cornerRadius = 6.5
        balloon.position = CGPoint(x: 40, y: 92)
        group.addSublayer(balloon)

        for l in [group, balloon, string] { l.contentsScale = scaleFactor }
        body.addSublayer(group)

        let pop = CASpringAnimation(keyPath: "transform.scale")
        pop.fromValue = 0.01
        pop.toValue = 1
        pop.damping = 10
        pop.duration = pop.settlingDuration
        group.add(pop, forKey: "pop")

        // up, hover, back down — in body-local coords, so wall crabs float away from the wall
        let float = CAKeyframeAnimation(keyPath: "transform.translation.y")
        float.values = [0, 42, 42, 0]
        float.keyTimes = [0, 0.3, 0.72, 1]
        float.duration = 4.4
        body.add(float, forKey: "trickFloat")

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.4) { [weak self] in
            guard self != nil else { group.removeFromSuperlayer(); return }
            CATransaction.begin()
            CATransaction.setCompletionBlock { group.removeFromSuperlayer() }
            let out = CABasicAnimation(keyPath: "opacity")
            out.fromValue = 1
            out.toValue = 0
            out.duration = 0.25
            out.fillMode = .forwards
            out.isRemovedOnCompletion = false
            group.add(out, forKey: "out")
            CATransaction.commit()
        }
    }

    // MARK: - Beer break 🍺 (sem tam si daju pivo pocas prace)

    func beerBreak(now: CFTimeInterval = CACurrentMediaTime(), joining: Bool = false) {
        guard beerMug == nil, now >= trickUntil else { return }
        beerUntil = now + 4.6
        nextBeerAt = now + Double.random(in: 240...600)
        slideRemaining = 0
        legPhase = 0
        legs.path = Self.legsFrameA
        if !joining { onBeerStarted?(self) }

        let mug = Self.makeBeerMug()
        mug.position = CGPoint(x: 57, y: 33)   // held in front of the face
        body.addSublayer(mug)
        beerMug = mug

        let pop = CASpringAnimation(keyPath: "transform.scale")
        pop.fromValue = 0.01
        pop.toValue = 1
        pop.damping = 10
        pop.initialVelocity = 5
        pop.duration = pop.settlingDuration
        mug.add(pop, forKey: "pop")

        // three sips — the mug tips toward the mouth
        let sips = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        sips.values = [0, 0.5, 0.12, 0.55, 0.15, 0.6, 0]
        sips.keyTimes = [0, 0.18, 0.33, 0.5, 0.65, 0.85, 1]
        sips.duration = 3.4
        sips.beginTime = CACurrentMediaTime() + 0.5
        mug.add(sips, forKey: "sips")

        squint(true)   // happy eyes

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self else { return }
            self.squint(false)
            if let mug = self.beerMug {
                self.beerMug = nil
                CATransaction.begin()
                CATransaction.setCompletionBlock { mug.removeFromSuperlayer() }
                let out = CABasicAnimation(keyPath: "transform.scale")
                out.fromValue = 1
                out.toValue = 0.01
                out.duration = 0.22
                out.fillMode = .forwards
                out.isRemovedOnCompletion = false
                mug.add(out, forKey: "out")
                CATransaction.commit()
            }
            self.bubble.show("ahh~", for: 1.8)
        }
    }

    private func squint(_ on: Bool) {
        guard state != .sleeping else { return }
        if on {
            let t = CATransform3DMakeScale(1, 0.45, 1)
            eyeLeft.transform = t
            eyeRight.transform = t
        } else {
            applyEyes()
        }
    }

    /// pixel beer mug: white foam, amber body, handle on the right
    private static func makeBeerMug() -> CALayer {
        let px: CGFloat = 3
        let group = CALayer()
        group.bounds = CGRect(x: 0, y: 0, width: 6 * px, height: 6 * px)
        group.anchorPoint = CGPoint(x: 0.15, y: 0.1)   // tilt around the bottom-left

        func rect(_ col: Int, _ row: Int) -> CGRect {   // row 0 = top
            CGRect(x: CGFloat(col) * px, y: CGFloat(5 - row) * px, width: px, height: px)
        }

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2

        let beer = CAShapeLayer()
        let beerPath = CGMutablePath()
        for row in 1...5 { for col in 0...4 { beerPath.addRect(rect(col, row)) } }
        for row in 2...4 { beerPath.addRect(rect(5, row)) }   // handle
        beer.path = beerPath
        beer.fillColor = NSColor(srgbRed: 0.95, green: 0.66, blue: 0.12, alpha: 1).cgColor
        beer.contentsScale = scaleFactor
        group.addSublayer(beer)

        let foam = CAShapeLayer()
        let foamPath = CGMutablePath()
        for col in 0...4 { foamPath.addRect(rect(col, 0)) }
        foam.path = foamPath
        foam.fillColor = NSColor(white: 0.98, alpha: 1).cgColor
        foam.contentsScale = scaleFactor
        group.addSublayer(foam)

        // rising bubbles above the foam
        for (i, dx) in [CGFloat(4.5), CGFloat(10.5)].enumerated() {
            let dot = CALayer()
            dot.backgroundColor = NSColor(white: 1, alpha: 0.9).cgColor
            dot.bounds = CGRect(x: 0, y: 0, width: 2, height: 2)
            dot.cornerRadius = 1
            dot.position = CGPoint(x: dx, y: 19)
            group.addSublayer(dot)
            let up = CABasicAnimation(keyPath: "transform.translation.y")
            up.fromValue = 0
            up.toValue = 9
            up.duration = 1.1 + Double(i) * 0.3
            up.repeatCount = .infinity
            dot.add(up, forKey: "up")
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1
            fade.toValue = 0
            fade.duration = up.duration
            fade.repeatCount = .infinity
            dot.add(fade, forKey: "fade")
        }
        return group
    }

    private func decide(now: CFTimeInterval) {
        let shouldMove = state == .working ? true : Double.random(in: 0...1) < 0.55
        if shouldMove {
            slideDir = Bool.random() ? 1 : -1
            slideRemaining = state == .working ? CGFloat.random(in: 260...700)
                                               : CGFloat.random(in: 80...260)
            let base = state == .working ? CGFloat.random(in: 90...130) : CGFloat.random(in: 24...40)
            speed = base * (1 + CGFloat(wiredness()) * 0.22)   // wired crabs scuttle faster
        } else {
            nextDecisionAt = now + Double.random(in: 2...7)
        }
    }

    private func crawl(by distance: CGFloat) {
        perimT = Self.wrap(perimT + slideDir * distance, length: perimeterLength)
        slideRemaining -= distance
        applyPerimeterPosition()
        // scuttle: legs alternate every ~7 px of travelled distance
        let phase = Int(perimT / 7) & 1
        if phase != legPhase {
            legPhase = phase
            legs.path = phase == 0 ? Self.legsFrameA : Self.legsFrameB
        }
    }

    /// sleeping pets crawl the shortest way around the ring down to the bottom edge
    private func crawlTowardBottom() {
        let delta = Self.shortestDelta(from: perimT, to: nearestBottomT, length: perimeterLength)
        guard abs(delta) > 3 else { return }   // resting
        slideDir = delta > 0 ? 1 : -1
        crawl(by: min(70.0 / 30.0, abs(delta)))
    }

    // MARK: - Perimeter geometry

    private var perimeterLength: CGFloat {
        let w = max(1, roamArea.maxX - roamArea.minX)
        let h = max(1, roamArea.maxY - roamArea.minY)
        return 2 * (w + h)
    }

    private var nearestBottomT: CGFloat {
        let w = max(1, roamArea.maxX - roamArea.minX)
        return min(max(frame.origin.x - roamArea.minX, 0), w)
    }

    private func placeOnPerimeter() {
        guard roamArea.maxX > roamArea.minX, roamArea.maxY > roamArea.minY else { return }
        perimT = CGFloat.random(in: 0..<perimeterLength)
        applyPerimeterPosition()
    }

    private func applyPerimeterPosition() {
        let (p, seg) = Self.positionAndSegment(for: perimT, in: roamArea)
        if abs(p.x - frame.origin.x) > 0.4 || abs(p.y - frame.origin.y) > 0.4 {
            setFrameOrigin(p)
        }
        if seg != currentSegment {
            let firstTime = currentSegment < 0
            currentSegment = seg
            // legs point at the edge: local -y rotated by θ lands at (sin θ, -cos θ)
            // bottom → 0, right wall → +90° CCW, ceiling → 180°, left wall → -90°
            let angles: [CGFloat] = [0, .pi / 2, .pi, -.pi / 2]
            setBodyAngle(angles[seg], animated: !firstTime)
            // bubble goes below the pet when crawling on the ceiling
            bubble.setFrameOrigin(NSPoint(x: bubble.frame.origin.x, y: seg == 2 ? 22 : 90))
            positionPill()
        }
    }

    /// keep the name pill on-screen: shift it inward on the side edges
    private var pillCenterX: CGFloat {
        switch currentSegment {
        case 1: return 42    // right wall → pill toward screen center
        case 3: return 108   // left wall
        default: return 75
        }
    }

    private func positionPill() {
        let w = namePill.frame.width
        var x = pillCenterX - w / 2
        x = min(max(x, 0), bounds.width - w)
        namePill.setFrameOrigin(NSPoint(x: x, y: 2))
    }

    /// bottom → right → top → left, wrapping
    private static func positionAndSegment(for t: CGFloat, in area: RoamArea) -> (NSPoint, Int) {
        let w = max(1, area.maxX - area.minX)
        let h = max(1, area.maxY - area.minY)
        var v = wrap(t, length: 2 * (w + h))
        if v < w { return (NSPoint(x: area.minX + v, y: area.minY), 0) }
        v -= w
        if v < h { return (NSPoint(x: area.maxX, y: area.minY + v), 1) }
        v -= h
        if v < w { return (NSPoint(x: area.maxX - v, y: area.maxY), 2) }
        v -= w
        return (NSPoint(x: area.minX, y: area.maxY - v), 3)
    }

    private static func wrap(_ t: CGFloat, length: CGFloat) -> CGFloat {
        guard length > 0 else { return 0 }
        var v = t.truncatingRemainder(dividingBy: length)
        if v < 0 { v += length }
        return v
    }

    private static func shortestDelta(from: CGFloat, to: CGFloat, length: CGFloat) -> CGFloat {
        var d = wrap(to - from, length: length)
        if d > length / 2 { d -= length }
        return d
    }

    private func smallHop() {
        let hop = CAKeyframeAnimation(keyPath: "transform.translation.y")
        hop.values = [0, 14, 0]
        hop.keyTimes = [0, 0.5, 1]
        hop.duration = 0.4
        body.add(hop, forKey: "hop")
    }

    // MARK: - Subagent babies (mini crabs around the parent)

    private var babyLayers: [String: CALayer] = [:]
    private var babyAddedAt: [String: CFTimeInterval] = [:]
    private static let babySlots: [CGFloat] = [-56, 56, -94, 94, -132, 132, -170, 170]

    func addBaby(agentId: String) {
        guard babyLayers[agentId] == nil, babyLayers.count < Self.babySlots.count else { return }
        let slot = Self.babySlots[babyLayers.count]
        let baby = Self.makeBaby(capColor: cap.fillColor)
        baby.position = CGPoint(x: 40 + slot, y: 31)   // feet on the parent's leg line
        body.addSublayer(baby)
        babyLayers[agentId] = baby
        babyAddedAt[agentId] = CACurrentMediaTime()
        let spring = CASpringAnimation(keyPath: "transform.scale")
        spring.fromValue = 0.01
        spring.toValue = 1
        spring.damping = 9
        spring.initialVelocity = 6
        spring.duration = spring.settlingDuration
        baby.add(spring, forKey: "spawn")
    }

    func removeBaby(agentId: String) {
        guard let baby = babyLayers.removeValue(forKey: agentId) else { return }
        babyAddedAt.removeValue(forKey: agentId)
        CATransaction.begin()
        CATransaction.setCompletionBlock { baby.removeFromSuperlayer() }
        let out = CABasicAnimation(keyPath: "transform.scale")
        out.fromValue = 1
        out.toValue = 0.01
        out.duration = 0.25
        out.fillMode = .forwards
        out.isRemovedOnCompletion = false
        baby.add(out, forKey: "out")
        CATransaction.commit()
    }

    /// orphan cleanup for missed SubagentStop events
    private func purgeExpiredBabies(now: CFTimeInterval) {
        guard !babyLayers.isEmpty else { return }
        for (id, t) in babyAddedAt where now - t > 30 * 60 {
            removeBaby(agentId: id)
        }
    }

    private static func makeBaby(capColor: CGColor?) -> CALayer {
        let px: CGFloat = 3
        let group = CALayer()
        func shape(_ cells: [(Int, Int)], _ color: CGColor?) -> CAShapeLayer {
            let l = CAShapeLayer()
            l.path = miniPath(cells: cells, px: px)
            l.fillColor = color
            l.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
            return l
        }
        group.addSublayer(shape(shellCells, claudeOrange.cgColor))
        group.addSublayer(shape(legCellsA, claudeOrange.cgColor))
        group.addSublayer(shape(capCells, capColor ?? claudeOrange.cgColor))
        group.addSublayer(shape([(2, 3), (8, 3)], inkColor.cgColor))   // eyes
        // excited toddler bob + wiggle
        let bob = CABasicAnimation(keyPath: "transform.translation.y")
        bob.fromValue = 0
        bob.toValue = 2.5
        bob.duration = 0.28
        bob.autoreverses = true
        bob.repeatCount = .infinity
        group.add(bob, forKey: "bob")
        let wiggle = CABasicAnimation(keyPath: "transform.translation.x")
        wiggle.fromValue = -5
        wiggle.toValue = 5
        wiggle.duration = Double.random(in: 1.1...2.0)
        wiggle.autoreverses = true
        wiggle.repeatCount = .infinity
        group.add(wiggle, forKey: "wiggle")
        return group
    }

    /// mini clawd path centered on (0,0), rows -2…5 (cap included)
    private static func miniPath(cells: [(Int, Int)], px: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let w = CGFloat(gridW) * px
        let h = CGFloat(8) * px
        for (col, row) in cells {
            path.addRect(CGRect(x: -w / 2 + CGFloat(col) * px,
                                y: h / 2 - CGFloat(row + 3) * px,
                                width: px, height: px))
        }
        return path
    }

    // MARK: - Blinking

    private func startBlinking() {
        scheduleBlink()
    }

    private func scheduleBlink() {
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 2.4...6.5), repeats: false) { [weak self] _ in
            guard let self else { return }
            if self.state != .sleeping { self.blinkOnce() }
            self.scheduleBlink()
        }
    }

    private func blinkOnce() {
        for eye in [eyeLeft, eyeRight] {
            let blink = CABasicAnimation(keyPath: "transform.scale.y")
            blink.fromValue = 1
            blink.toValue = 0.15
            blink.duration = 0.07
            blink.autoreverses = true
            eye.add(blink, forKey: "blink")
        }
    }

    // MARK: - Misc

    /// pill: royal name (surname = model) · effort when it's worth bragging about
    private func refreshPill() {
        var text = royalName
        if let e = effortLevel, e == "xhigh" || e == "max" { text += " · \(e)" }
        namePill.stringValue = text
        namePill.sizeToFit()
        let w = namePill.frame.width + 12
        let h = namePill.frame.height + 3
        var x = pillCenterX - w / 2
        x = min(max(x, 0), bounds.width - w)   // keep long pills inside the view
        namePill.frame = NSRect(x: x, y: 2, width: w, height: h)
    }

    // MARK: - Click interaction: jump to the session's terminal

    /// clickable area around the crab's body (local coords)
    var bodyHitRect: NSRect { NSRect(x: 25, y: 18, width: 100, height: 84) }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let p = convert(point, from: superview)
        return bodyHitRect.contains(p) ? self : nil
    }

    override func resetCursorRects() {
        addCursorRect(bodyHitRect, cursor: .pointingHand)
    }

    override func mouseDown(with event: NSEvent) {
        clickSquash()
        focusTerminal()
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let title = NSMenuItem(title: "\(royalName)  (\(info.name) — \(info.status))", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        if !info.cwd.isEmpty {
            let cwd = NSMenuItem(title: (info.cwd as NSString).abbreviatingWithTildeInPath,
                                 action: nil, keyEquivalent: "")
            cwd.isEnabled = false
            menu.addItem(cwd)
        }
        menu.addItem(.separator())
        let focus = NSMenuItem(title: "Show terminal", action: #selector(menuFocus), keyEquivalent: "")
        focus.target = self
        focus.isEnabled = true
        menu.addItem(focus)
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func menuFocus() {
        focusTerminal()
    }

    private func clickSquash() {
        let squash = CAKeyframeAnimation(keyPath: "transform.scale")
        squash.values = [currentScale, currentScale * 0.78, currentScale * 1.12, currentScale]
        squash.keyTimes = [0, 0.3, 0.7, 1]
        squash.duration = 0.35
        body.add(squash, forKey: "squash")
        smallHop()
        blinkOnce()
    }

    private func focusTerminal() {
        if let appName = TerminalFocus.focusApp(forSessionPID: info.pid) {
            bubble.show("→ \(appName)", for: 1.6)
        } else {
            bubble.show("?", for: 1.2)
        }
    }

    func cleanup() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        bubble.cleanup()
    }
}

// MARK: - Speech bubble

final class BubbleView: NSView {
    private let label = NSTextField(labelWithString: "")
    private var hideTimer: Timer?

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 60, height: 26))
        wantsLayer = true
        layer!.backgroundColor = NSColor(white: 1, alpha: 0.95).cgColor
        layer!.cornerRadius = 9
        layer!.borderWidth = 1
        layer!.borderColor = NSColor(white: 0, alpha: 0.08).cgColor
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = NSColor(white: 0.15, alpha: 1)
        label.alignment = .center
        addSubview(label)
        alphaValue = 0
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    /// duration nil = stay until hide()
    func show(_ text: String, for duration: TimeInterval?) {
        label.stringValue = text
        label.sizeToFit()
        let w = max(28, label.frame.width + 16)
        let h = label.frame.height + 10
        setFrameSize(NSSize(width: w, height: h))
        label.setFrameOrigin(NSPoint(x: (w - label.frame.width) / 2, y: (h - label.frame.height) / 2))
        if let sv = superview {
            setFrameOrigin(NSPoint(x: (sv.bounds.width - w) / 2, y: frame.origin.y))
        }
        hideTimer?.invalidate()
        hideTimer = nil
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            animator().alphaValue = 1
        }
        if let duration {
            hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.hide()
            }
        }
    }

    func hide() {
        hideTimer?.invalidate()
        hideTimer = nil
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            animator().alphaValue = 0
        }
    }

    func cleanup() {
        hideTimer?.invalidate()
        hideTimer = nil
    }
}
