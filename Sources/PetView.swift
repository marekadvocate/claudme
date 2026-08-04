import AppKit
import QuartzCore

enum PetState: Equatable {
    case idle, working, waiting, sleeping, celebrating
}

struct WalkArea {
    var minX: CGFloat
    var maxX: CGFloat
    var floorY: CGFloat
}

final class PetView: NSView {
    static let claudeOrange = NSColor(srgbRed: 217/255, green: 119/255, blue: 87/255, alpha: 1)
    static let viewSize = NSSize(width: 150, height: 170)

    let sessionId: String
    private(set) var info: SessionInfo
    var walkArea: WalkArea
    var onConfetti: ((PetView) -> Void)?

    private(set) var state: PetState = .idle
    private var celebrateUntil: CFTimeInterval = 0
    private var hookWorkingUntil: CFTimeInterval = 0

    // layers
    private let body = CALayer()
    private let burst = CAShapeLayer()
    private let eyeLeft = CALayer()
    private let eyeRight = CALayer()
    private let mouth = CAShapeLayer()
    private let groundShadow = CALayer()
    private let namePill = NSTextField(labelWithString: "")
    private let bubble = BubbleView()

    // behavior
    private var walking = false
    private var targetX: CGFloat = 0
    private var speed: CGFloat = 30
    private var nextDecisionAt: CFTimeInterval = 0
    private var nextHopAt: CFTimeInterval = 0
    private var nextChatterAt: CFTimeInterval = 0
    private var blinkTimer: Timer?

    init(info: SessionInfo, walkArea: WalkArea) {
        self.sessionId = info.sessionId
        self.info = info
        self.walkArea = walkArea
        super.init(frame: NSRect(origin: .zero, size: Self.viewSize))
        wantsLayer = true

        // ground shadow
        groundShadow.backgroundColor = NSColor(white: 0, alpha: 0.16).cgColor
        groundShadow.bounds = CGRect(x: 0, y: 0, width: 46, height: 9)
        groundShadow.cornerRadius = 4.5
        groundShadow.position = CGPoint(x: 75, y: 13)
        layer!.addSublayer(groundShadow)

        // body container
        body.bounds = CGRect(x: 0, y: 0, width: 80, height: 80)
        body.position = CGPoint(x: 75, y: 50)
        layer!.addSublayer(body)

        // starburst
        burst.frame = body.bounds
        burst.path = Self.starburstPath(radius: 27, center: CGPoint(x: 40, y: 40))
        burst.strokeColor = Self.claudeOrange.cgColor
        burst.fillColor = NSColor.clear.cgColor
        burst.lineWidth = 11.5
        burst.lineCap = .round
        body.addSublayer(burst)

        // breathing
        let breathe = CABasicAnimation(keyPath: "transform.scale")
        breathe.fromValue = 1.0
        breathe.toValue = 1.035
        breathe.duration = 1.6
        breathe.autoreverses = true
        breathe.repeatCount = .infinity
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        burst.add(breathe, forKey: "breathe")

        // eyes
        for (eye, dx) in [(eyeLeft, CGFloat(-9)), (eyeRight, CGFloat(9))] {
            eye.backgroundColor = NSColor(white: 0.12, alpha: 1).cgColor
            eye.bounds = CGRect(x: 0, y: 0, width: 7, height: 12)
            eye.cornerRadius = 3.5
            eye.position = CGPoint(x: 40 + dx, y: 44)
            body.addSublayer(eye)
        }

        // smile
        let mouthPath = CGMutablePath()
        mouthPath.addArc(center: CGPoint(x: 40, y: 36), radius: 6.5,
                         startAngle: 200 * .pi / 180, endAngle: 340 * .pi / 180, clockwise: false)
        mouth.path = mouthPath
        mouth.strokeColor = NSColor(white: 0.12, alpha: 1).cgColor
        mouth.fillColor = NSColor.clear.cgColor
        mouth.lineWidth = 2
        mouth.lineCap = .round
        body.addSublayer(mouth)

        // name pill
        namePill.font = .systemFont(ofSize: 9, weight: .semibold)
        namePill.textColor = NSColor(white: 1, alpha: 0.92)
        namePill.alignment = .center
        namePill.wantsLayer = true
        namePill.layer!.backgroundColor = NSColor(white: 0, alpha: 0.35).cgColor
        namePill.layer!.cornerRadius = 6.5
        addSubview(namePill)
        setName(info.name)

        // speech bubble
        bubble.setFrameOrigin(NSPoint(x: 45, y: 120))
        addSubview(bubble)

        startBlinking()
        applyState(mappedState(), animated: false)
        spawnPop()
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: - Registry updates

    func update(info newInfo: SessionInfo) {
        let oldStatus = info.status
        let nameChanged = newInfo.name != info.name
        info = newInfo
        if nameChanged { setName(newInfo.name) }
        // registry observed the turn end — drop the hook-driven working pulse
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
            return .working   // busy, compacting, anything unknown
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
        case .idle, .sleeping: return 0.72
        case .working: return 1.0
        case .waiting: return 1.02
        case .celebrating: return 1.3
        }
    }

    private func applyState(_ new: PetState, animated: Bool) {
        let old = state
        state = new
        setBodyScale(Self.scale(for: new), animated: animated)

        // eyes open/closed
        let closed = (new == .sleeping)
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        let eyeTransform = closed ? CATransform3DMakeScale(1, 0.12, 1) : CATransform3DIdentity
        eyeLeft.transform = eyeTransform
        eyeRight.transform = eyeTransform
        CATransaction.commit()

        if (old == .waiting || old == .sleeping) && new != .waiting && new != .sleeping {
            bubble.hide()
        }
        switch new {
        case .waiting:
            bubble.show("!", for: nil)
            nextHopAt = CACurrentMediaTime() + 0.4
        case .sleeping:
            stopWalking()
            bubble.show("z Z", for: nil)
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

    // MARK: - Behavior tick (30 fps, driven by PetManager)

    func tick(now: CFTimeInterval) {
        if state == .celebrating && now > celebrateUntil {
            applyState(mappedState(), animated: true)
        }

        switch state {
        case .sleeping, .celebrating:
            if walking { stopWalking() }
        case .waiting:
            if walking { stopWalking() }
            if now >= nextHopAt {
                nextHopAt = now + Double.random(in: 2.2...3.4)
                smallHop()
            }
        case .idle, .working:
            if walking {
                stepToward(now: now)
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
        guard walkArea.maxX - walkArea.minX > 40 else {
            nextDecisionAt = now + 2
            return
        }
        let shouldWalk = state == .working ? true : Bool.random()
        if shouldWalk {
            let span: CGFloat = state == .working ? 240 : 120
            var t = frame.origin.x + CGFloat.random(in: -span...span)
            t = min(max(t, walkArea.minX), walkArea.maxX)
            targetX = t
            speed = state == .working ? CGFloat.random(in: 70...100) : CGFloat.random(in: 22...36)
            startWalking()
        } else {
            nextDecisionAt = now + Double.random(in: 1.5...5)
        }
    }

    private func stepToward(now: CFTimeInterval) {
        let dt: CGFloat = 1.0 / 30.0
        let dx = targetX - frame.origin.x
        let step = speed * dt
        if abs(dx) <= step {
            setFrameOrigin(NSPoint(x: targetX, y: walkArea.floorY))
            stopWalking()
            nextDecisionAt = now + (state == .working ? Double.random(in: 0.4...1.6)
                                                      : Double.random(in: 2...6))
        } else {
            setFrameOrigin(NSPoint(x: frame.origin.x + (dx > 0 ? step : -step), y: walkArea.floorY))
        }
    }

    private func startWalking() {
        guard !walking else { return }
        walking = true
        let bob = CABasicAnimation(keyPath: "transform.translation.y")
        bob.fromValue = 0
        bob.toValue = 5
        bob.duration = 0.16
        bob.autoreverses = true
        bob.repeatCount = .infinity
        body.add(bob, forKey: "bob")
        let wobble = CABasicAnimation(keyPath: "transform.rotation.z")
        wobble.fromValue = -0.07
        wobble.toValue = 0.07
        wobble.duration = 0.22
        wobble.autoreverses = true
        wobble.repeatCount = .infinity
        body.add(wobble, forKey: "wobble")
    }

    private func stopWalking() {
        guard walking else { return }
        walking = false
        body.removeAnimation(forKey: "bob")
        body.removeAnimation(forKey: "wobble")
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

    private static func starburstPath(radius r: CGFloat, center c: CGPoint) -> CGPath {
        let path = CGMutablePath()
        let lengths: [CGFloat] = [1.0, 0.84, 0.96, 0.8, 1.0, 0.86, 0.97, 0.82, 0.93, 0.87]
        let angleJitter: [CGFloat] = [0, 5, -4, 3, -2, 4, -5, 2, -3, 1]
        let rays = lengths.count
        for i in 0..<rays {
            let a = (CGFloat(i) / CGFloat(rays)) * 2 * .pi + angleJitter[i] * .pi / 180 + .pi / 2
            let len = r * lengths[i]
            path.move(to: CGPoint(x: c.x + cos(a) * r * 0.08, y: c.y + sin(a) * r * 0.08))
            path.addLine(to: CGPoint(x: c.x + cos(a) * len, y: c.y + sin(a) * len))
        }
        return path
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
