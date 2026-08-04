import AppKit
import QuartzCore

enum PetState: Equatable {
    case idle, working, waiting, sleeping, celebrating
}

/// Full-screen roaming area (overlay-local coordinates, y-up).
struct RoamArea {
    var minX: CGFloat
    var maxX: CGFloat
    var minY: CGFloat
    var maxY: CGFloat
}

final class PetView: NSView {
    // Claude brand "Crail"
    static let claudeOrange = NSColor(srgbRed: 217/255, green: 119/255, blue: 87/255, alpha: 1)
    static let inkColor = NSColor(srgbRed: 38/255, green: 38/255, blue: 36/255, alpha: 1)
    static let viewSize = NSSize(width: 150, height: 170)

    let sessionId: String
    private(set) var info: SessionInfo
    var roamArea: RoamArea
    var onConfetti: ((PetView) -> Void)?

    private(set) var state: PetState = .idle
    private var celebrateUntil: CFTimeInterval = 0
    private var hookWorkingUntil: CFTimeInterval = 0

    // layers — body floats; burst spins behind an upright face
    private let body = CALayer()
    private let burst = CAShapeLayer()
    private let centerDisc = CAShapeLayer()
    private let eyeLeft = CALayer()
    private let eyeRight = CALayer()
    private let glintLeft = CALayer()
    private let glintRight = CALayer()
    private let mouth = CAShapeLayer()
    private let namePill = NSTextField(labelWithString: "")
    private let bubble = BubbleView()

    // behavior
    private var moving = false
    private var target = CGPoint.zero
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

        // floating body with a soft drop shadow (they fly — no ground shadow)
        body.bounds = CGRect(x: 0, y: 0, width: 80, height: 80)
        body.position = CGPoint(x: 75, y: 60)
        body.shadowColor = NSColor.black.cgColor
        body.shadowOpacity = 0.14
        body.shadowRadius = 3
        body.shadowOffset = CGSize(width: 0, height: -2)
        layer!.addSublayer(body)

        // the spark — 12 chisel-tipped wedge rays, filled (matches the real mark)
        burst.frame = body.bounds
        burst.path = Self.sparkPath(radius: 30, center: CGPoint(x: 40, y: 40))
        burst.fillColor = Self.claudeOrange.cgColor
        burst.strokeColor = nil
        body.addSublayer(burst)

        // solid center so the face has a home
        let discPath = CGMutablePath()
        discPath.addEllipse(in: CGRect(x: 40 - 13.5, y: 40 - 13.5, width: 27, height: 27))
        centerDisc.frame = body.bounds
        centerDisc.path = discPath
        centerDisc.fillColor = Self.claudeOrange.cgColor
        body.addSublayer(centerDisc)

        // face (upright — only the burst spins)
        for (eye, glint, dx) in [(eyeLeft, glintLeft, CGFloat(-6.4)), (eyeRight, glintRight, CGFloat(6.4))] {
            eye.backgroundColor = Self.inkColor.cgColor
            eye.bounds = CGRect(x: 0, y: 0, width: 5.6, height: 10)
            eye.cornerRadius = 2.8
            eye.position = CGPoint(x: 40 + dx, y: 43)
            body.addSublayer(eye)
            glint.backgroundColor = NSColor(white: 1, alpha: 0.9).cgColor
            glint.bounds = CGRect(x: 0, y: 0, width: 2, height: 2)
            glint.cornerRadius = 1
            glint.position = CGPoint(x: 40 + dx + 1.4, y: 45.6)
            body.addSublayer(glint)
        }

        let mouthPath = CGMutablePath()
        mouthPath.addArc(center: CGPoint(x: 40, y: 36.5), radius: 4.6,
                         startAngle: 205 * .pi / 180, endAngle: 335 * .pi / 180, clockwise: false)
        mouth.path = mouthPath
        mouth.strokeColor = Self.inkColor.cgColor
        mouth.fillColor = nil
        mouth.lineWidth = 1.7
        mouth.lineCap = .round
        body.addSublayer(mouth)

        // crisp on retina
        for l in [layer!, body, burst, centerDisc, eyeLeft, eyeRight, glintLeft, glintRight, mouth] {
            l.contentsScale = scaleFactor
        }

        // permanent gentle hover
        let hover = CABasicAnimation(keyPath: "transform.translation.y")
        hover.fromValue = -2.5
        hover.toValue = 2.5
        hover.duration = 2.2
        hover.autoreverses = true
        hover.repeatCount = .infinity
        hover.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        body.add(hover, forKey: "hover")

        // name pill
        namePill.font = .systemFont(ofSize: 9, weight: .semibold)
        namePill.textColor = NSColor(white: 1, alpha: 0.92)
        namePill.alignment = .center
        namePill.wantsLayer = true
        namePill.layer!.backgroundColor = NSColor(white: 0, alpha: 0.30).cgColor
        namePill.layer!.cornerRadius = 6.5
        namePill.alphaValue = 0.8
        addSubview(namePill)
        setName(info.name)

        // speech bubble
        bubble.setFrameOrigin(NSPoint(x: 45, y: 122))
        addSubview(bubble)

        startBlinking()
        applyState(mappedState(), animated: false)
        spawnPop()
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: - The spark path (replicated from the real mark: thin wedges,
    // slightly flared outward, chisel-cut tips, irregular lengths/angles)

    private static func sparkPath(radius r: CGFloat, center c: CGPoint) -> CGPath {
        let path = CGMutablePath()
        let lengths: [CGFloat] = [1.00, 0.74, 0.96, 0.66, 1.00, 0.72, 0.94, 0.68, 0.98, 0.75, 0.90, 0.70]
        let jitterDeg: [CGFloat] = [0, 4, -3, 5, -2, 3, -5, 2, -4, 1, 3, -2]
        let tipSkew: [CGFloat] = [0.06, 0.10, 0.04, 0.08, 0.05, 0.09, 0.03, 0.07, 0.06, 0.10, 0.04, 0.08]
        let rays = lengths.count
        let r0 = r * 0.12          // inner start
        let w0 = r * 0.07          // half-width at center
        let w1 = r * 0.105         // half-width at tip (slight flare)

        for i in 0..<rays {
            let a = (CGFloat(i) / CGFloat(rays)) * 2 * .pi + jitterDeg[i] * .pi / 180 + .pi / 2
            let dir = CGPoint(x: cos(a), y: sin(a))
            let perp = CGPoint(x: -sin(a), y: cos(a))
            let len = r * lengths[i]
            let lenShort = len * (1 - tipSkew[i])   // chisel cut

            func pt(_ d: CGFloat, _ w: CGFloat) -> CGPoint {
                CGPoint(x: c.x + dir.x * d + perp.x * w,
                        y: c.y + dir.y * d + perp.y * w)
            }
            path.move(to: pt(r0, w0))
            path.addLine(to: pt(len, w1))
            path.addLine(to: pt(lenShort, -w1))
            path.addLine(to: pt(r0, -w0))
            path.closeSubpath()
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

    /// burst rotation: spin speed = activity (like the Claude Code spinner)
    private func setSpin(duration: CFTimeInterval?) {
        let current = (burst.presentation() ?? burst).value(forKeyPath: "transform.rotation.z") as? CGFloat ?? 0
        burst.removeAnimation(forKey: "spin")
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        burst.setValue(current, forKeyPath: "transform.rotation.z")
        CATransaction.commit()
        guard let duration else { return }
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.byValue = 2 * CGFloat.pi
        spin.duration = duration
        spin.repeatCount = .infinity
        burst.add(spin, forKey: "spin")
    }

    private func applyState(_ new: PetState, animated: Bool) {
        let old = state
        state = new
        setBodyScale(Self.scale(for: new), animated: animated)

        let closed = (new == .sleeping)
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        let eyeTransform = closed ? CATransform3DMakeScale(1, 0.12, 1) : CATransform3DIdentity
        eyeLeft.transform = eyeTransform
        eyeRight.transform = eyeTransform
        glintLeft.opacity = closed ? 0 : 1
        glintRight.opacity = closed ? 0 : 1
        CATransaction.commit()

        switch new {
        case .idle: setSpin(duration: 16)
        case .working: setSpin(duration: 2.0)
        case .celebrating: setSpin(duration: 0.8)
        case .waiting, .sleeping: setSpin(duration: nil)
        }

        if (old == .waiting || old == .sleeping) && new != .waiting && new != .sleeping {
            bubble.hide()
        }
        switch new {
        case .waiting:
            moving = false
            bubble.show("!", for: nil)
            nextHopAt = CACurrentMediaTime() + 0.4
        case .sleeping:
            bubble.show("z Z", for: nil)
            // drift down and rest at the bottom
            target = CGPoint(x: min(max(frame.origin.x, roamArea.minX), roamArea.maxX), y: roamArea.minY)
            speed = 30
            moving = true
        case .working:
            nextChatterAt = CACurrentMediaTime() + Double.random(in: 8...20)
        default:
            break
        }
        nextDecisionAt = 0
    }

    private func setBodyScale(_ s: CGFloat, animated: Bool) {
        if animated {
            let spring = CASpringAnimation(keyPath: "transform.scale")
            spring.fromValue = (body.presentation() ?? body).value(forKeyPath: "transform.scale.x")
            spring.toValue = s
            spring.damping = 11
            spring.initialVelocity = 4
            spring.duration = spring.settlingDuration
            body.add(spring, forKey: "stateScale")
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        body.transform = CATransform3DMakeScale(s, s, 1)
        CATransaction.commit()
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
        if state == .celebrating && now > celebrateUntil {
            applyState(mappedState(), animated: true)
        }

        switch state {
        case .celebrating:
            moving = false
        case .waiting:
            moving = false
            if now >= nextHopAt {
                nextHopAt = now + Double.random(in: 2.2...3.4)
                smallHop()
            }
        case .sleeping:
            if moving { step(now: now) }   // finish descending, then rest
        case .idle, .working:
            if moving {
                step(now: now)
            } else if now >= nextDecisionAt {
                decide(now: now)
            }
            if state == .working && now >= nextChatterAt {
                nextChatterAt = now + Double.random(in: 12...25)
                bubble.show("…", for: 2.2)
            }
        }
    }

    /// pick a random destination anywhere on screen — full 360° roaming
    private func decide(now: CFTimeInterval) {
        guard roamArea.maxX - roamArea.minX > 40, roamArea.maxY - roamArea.minY > 40 else {
            nextDecisionAt = now + 2
            return
        }
        let shouldMove = state == .working ? true : Double.random(in: 0...1) < 0.55
        if shouldMove {
            target = CGPoint(x: CGFloat.random(in: roamArea.minX...roamArea.maxX),
                             y: CGFloat.random(in: roamArea.minY...roamArea.maxY))
            speed = state == .working ? CGFloat.random(in: 90...130) : CGFloat.random(in: 24...40)
            moving = true
        } else {
            nextDecisionAt = now + Double.random(in: 2...7)
        }
    }

    private func step(now: CFTimeInterval) {
        let dt: CGFloat = 1.0 / 30.0
        let dx = target.x - frame.origin.x
        let dy = target.y - frame.origin.y
        let dist = sqrt(dx * dx + dy * dy)
        if dist < 4 {
            setFrameOrigin(NSPoint(x: target.x, y: target.y))
            moving = false
            nextDecisionAt = now + (state == .working ? Double.random(in: 0.3...1.2)
                                                      : Double.random(in: 2...7))
            return
        }
        // ease in/out: slow down on approach
        let effective = min(speed, dist * 2.6 + 8)
        let stepLen = effective * dt
        setFrameOrigin(NSPoint(x: frame.origin.x + dx / dist * stepLen,
                               y: frame.origin.y + dy / dist * stepLen))
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
            blink.toValue = 0.12
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
        namePill.frame = NSRect(x: (bounds.width - w) / 2, y: 2, width: w, height: h)
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
