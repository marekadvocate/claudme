import AppKit
import QuartzCore

enum PetState: Equatable {
    case idle, working, waiting, sleeping, celebrating
}

/// Perimeter ring the pets crawl on (overlay-local coordinates, y-up).
struct RoamArea {
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

    // MARK: - Init

    init(info: SessionInfo, roamArea: RoamArea) {
        self.sessionId = info.sessionId
        self.info = info
        self.roamArea = roamArea
        super.init(frame: NSRect(origin: .zero, size: Self.viewSize))
        wantsLayer = true

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

        for l in [layer!, body, shell, legs, eyeLeft, eyeRight, glintLeft, glintRight] {
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
        setName(info.name)

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

    // MARK: - Registry updates

    func update(info newInfo: SessionInfo) {
        let oldStatus = info.status
        let nameChanged = newInfo.name != info.name
        info = newInfo
        if nameChanged { setName(newInfo.name) }
        if oldStatus == "busy" && newInfo.status == "idle" {
            hookWorkingUntil = 0
        }
        if state != .celebrating {
            let mapped = mappedState()
            if mapped != state { applyState(mapped, animated: true) }
        }
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

        let closed = (new == .sleeping)
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        let eyeTransform = closed ? CATransform3DMakeScale(1, 0.15, 1) : CATransform3DIdentity
        eyeLeft.transform = eyeTransform
        eyeRight.transform = eyeTransform
        glintLeft.opacity = closed ? 0 : 1
        glintRight.opacity = closed ? 0 : 1
        CATransaction.commit()

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
        currentScale = s
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
        }
    }

    private func decide(now: CFTimeInterval) {
        let shouldMove = state == .working ? true : Double.random(in: 0...1) < 0.55
        if shouldMove {
            slideDir = Bool.random() ? 1 : -1
            slideRemaining = state == .working ? CGFloat.random(in: 260...700)
                                               : CGFloat.random(in: 80...260)
            speed = state == .working ? CGFloat.random(in: 90...130) : CGFloat.random(in: 24...40)
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
            // legs point at the edge: bottom 0°, right -90°, top 180°, left +90°
            let angles: [CGFloat] = [0, -.pi / 2, .pi, .pi / 2]
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
        namePill.setFrameOrigin(NSPoint(x: pillCenterX - w / 2, y: 2))
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

    private func setName(_ name: String) {
        namePill.stringValue = name
        namePill.sizeToFit()
        let w = namePill.frame.width + 12
        let h = namePill.frame.height + 3
        namePill.frame = NSRect(x: pillCenterX - w / 2, y: 2, width: w, height: h)
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
