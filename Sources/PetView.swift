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

    /// the family a crab belongs to — the model it runs on
    var familyName: String {
        switch self {
        case .fable: return "Fable"
        case .opus: return "Opus"
        case .sonnet: return "Sonnet"
        case .haiku: return "Haiku"
        case .unknown: return "Ombra"
        }
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
    private let cap = CAShapeLayer()        // colored headwear = stable session identity
    private let accent = CAShapeLayer()     // era markings on the shell
    private let voxel = CALayer()           // 3D mode: the whole crab as one iso sprite
    /// Holds only the crab's own parts. `body` owns position, edge rotation and model
    /// scale; `rig` owns dance deformation. Keeping them on separate layers means the
    /// two never overwrite each other's transform.
    private let rig = CALayer()
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
    /// how long the crab has been settled in its sleeping spot, 0 while it is walking
    private var restingSince: CFTimeInterval = 0
    /// nil until the first shift; then the floor position it has chosen for itself
    private var sleepBed: CGFloat?

    // behavior — crawl along the screen edge ring
    private var perimT: CGFloat = -1
    private var slideDir: CGFloat = 1
    private var slideRemaining: CGFloat = 0
    private var speed: CGFloat = 40
    private var nextDecisionAt: CFTimeInterval = 0
    private var nextHopAt: CFTimeInterval = 0
    private var nextChatterAt: CFTimeInterval = 0
    private var blinkTimer: Timer?
    private var stateRecheck = 0

    // beer break
    private var beerUntil: CFTimeInterval = 0
    private var nextBeerAt: CFTimeInterval = CACurrentMediaTime() + Double.random(in: 90...300)
    private var beerMug: CALayer?
    var onBeerStarted: ((PetView) -> Void)?   // manager checks for a clink partner

    // rare tricks + idle mumbles + hover pokes
    private var trickUntil: CFTimeInterval = 0
    private var nextTrickAt: CFTimeInterval = CACurrentMediaTime() + Double.random(in: 300...900)
    /// separate clock for rope/rocket — see the traversal branch in tick()
    private var nextTraversalAt: CFTimeInterval = CACurrentMediaTime() + Double.random(in: 45...120)
    private var nextMumbleAt: CFTimeInterval = CACurrentMediaTime() + Double.random(in: 180...480)
    /// Friday and Saturday earn a deckchair; Monday earns a scowl. Checked live rather than
    /// cached, so a crab left running over midnight changes its tune with the calendar.
    private var nextMoodAt: CFTimeInterval = CACurrentMediaTime() + Double.random(in: 120...400)
    private var loungerLayer: CALayer?
    private var moodUntil: CFTimeInterval = 0
    private var lastPokeAt: CFTimeInterval = 0

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

    /// wired crabs mumble in symbols, calm ones in their mother tongue
    private func mumble() -> String {
        switch wiredness() {
        case 3: return ["🚀", "!!!", "brrr", "MAX"].randomElement()!
        case 2: return ["🔥", "⚡️", "hmm!"].randomElement()!
        default: return Quips.random(.idle)
        }
    }

    // CC feature states: permission mode (glasses), remote (satellite), compaction
    private var permissionMode: String?
    private var accessoryLayer: CAShapeLayer?
    private var satelliteLayer: CALayer?
    private var compactUntil: CFTimeInterval = 0

    // MARK: - Render mode (flat pixels vs isometric voxels)

    private static let voxelKey = "ClaudmeVoxelMode"
    private(set) static var voxelMode = UserDefaults.standard.bool(forKey: voxelKey)

    static func setVoxelMode(_ on: Bool) {
        voxelMode = on
        UserDefaults.standard.set(on, forKey: voxelKey)
    }

    /// Swaps between the flat pixel layers and the single voxel sprite.
    func applyRenderMode() {
        teardownDanceCubes()          // never leave one mode's pieces over the other's
        let on = Self.voxelMode
        for l in [shell, legs, accent, cap] { l.isHidden = on }
        for l in [eyeLeft, eyeRight, glintLeft, glintRight] { l.isHidden = on }
        voxel.isHidden = !on
        accessoryLayer?.isHidden = on     // 3D bakes eyewear into the sprite
        // the voxel crab is drawn from above, so it needs no ground shadow of its own
        body.shadowOpacity = on ? 0.26 : 0.14
        currentSegment = -1          // forces the edge angle to be re-derived next tick
        if on { refreshVoxel() }
        if dancing { applyDance() }   // rebuild the dance for the mode we just switched to
    }

    private func refreshVoxel() {
        guard Self.voxelMode else { return }
        let capNS = cap.fillColor.map { NSColor(cgColor: $0) ?? Self.claudeOrange } ?? Self.claudeOrange
        guard let img = VoxelSprite.image(bodyColor: modelKind.bodyColor,
                                          capColor: capNS,
                                          era: era,
                                          legPhase: legPhase,
                                          sleeping: state == .sleeping,
                                          eyewear: Self.eyewearCells(for: permissionMode),
                                          pixel: 4.5)
        else { return }
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        voxel.contents = img
        voxel.contentsScale = scale
        voxel.bounds = CGRect(x: 0, y: 0,
                              width: CGFloat(img.width) / scale,
                              height: CGFloat(img.height) / scale)
        voxel.position = CGPoint(x: 40, y: 42)
        CATransaction.commit()
    }

    // MARK: - Made name ("Don Vito Opus")

    private var made: MadeName?

    /// The manager assigns these so no two living crabs share a name.
    func setMadeName(_ name: MadeName) {
        guard name.full != made?.full else { return }
        made = name
        refreshPill()
    }

    var madeName: MadeName {
        made ?? Naming.name(sessionName: info.name, model: modelKind, ageSeconds: info.ageSeconds)
    }

    var era: Era { madeName.era }

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

        rig.frame = body.bounds
        rig.bounds = body.bounds
        rig.position = CGPoint(x: 40, y: 40)
        body.addSublayer(rig)

        shell.frame = body.bounds
        shell.path = Self.pixelPath(cells: Self.shellCells)
        shell.fillColor = Self.claudeOrange.cgColor
        rig.addSublayer(shell)

        legs.frame = body.bounds
        legs.path = Self.legsFrameA
        legs.fillColor = Self.claudeOrange.cgColor
        rig.addSublayer(legs)

        // era markings on the shell, under the hat
        accent.frame = body.bounds
        accent.path = Self.pixelPath(cells: Self.accentCells(for: Naming.era(for: info.name)))
        accent.fillColor = NSColor(white: 1, alpha: 0.22).cgColor
        rig.addSublayer(accent)

        // headwear for this crab's era, in the session's identity colour
        cap.frame = body.bounds
        cap.path = Self.pixelPath(cells: Self.hatCells(for: Naming.era(for: info.name)))
        cap.fillColor = Self.capColor(for: info.name).cgColor
        rig.addSublayer(cap)

        // eyes = the two ▄ cells of the TUI art (grid row 3, cols 2 & 8)
        for (eye, glint, col) in [(eyeLeft, glintLeft, 2), (eyeRight, glintRight, 8)] {
            let r = Self.cellRect(col: col, row: 3)
            eye.backgroundColor = Self.inkColor.cgColor
            eye.bounds = CGRect(x: 0, y: 0, width: Self.px, height: Self.px)
            eye.position = CGPoint(x: r.midX, y: r.midY)
            rig.addSublayer(eye)
            glint.backgroundColor = NSColor(white: 1, alpha: 0.9).cgColor
            glint.bounds = CGRect(x: 0, y: 0, width: 2.2, height: 2.2)
            glint.position = CGPoint(x: r.midX + 1.8, y: r.midY + 1.8)
            rig.addSublayer(glint)
        }

        for l in [layer!, body, shell, legs, accent, cap, eyeLeft, eyeRight, glintLeft, glintRight] {
            l.contentsScale = scaleFactor
        }

        // 3D mode draws the whole crab as one isometric sprite laid over the flat parts
        voxel.frame = body.bounds
        voxel.contentsGravity = .center
        voxel.isHidden = true
        rig.addSublayer(voxel)

        cubeHolder.frame = body.bounds
        cubeHolder.isHidden = true
        rig.addSublayer(cubeHolder)

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
        applyRenderMode()
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

    /// Markings on the shell itself, so an era still reads when the hat is hidden by
    /// a bubble or clipped at a corner. Drawn in a lighter tint of the body.
    static func accentCells(for era: Era) -> [(Int, Int)] {
        switch era {
        case .roman:        return [(1, 2), (2, 2), (3, 3), (4, 3)]          // toga sash
        case .medieval:     return [(1, 2), (3, 2), (5, 2), (7, 2), (9, 2),  // chainmail
                                    (4, 3), (6, 3)]
        case .renaissance:  return [(0, 2), (1, 2), (9, 2), (10, 2)]         // ruff collar
        case .prohibition:  return [(1, 2), (1, 3), (4, 2), (4, 3),          // pinstripes
                                    (7, 2), (7, 3)]
        case .yakuza:       return [(0, 2), (0, 3), (10, 2), (10, 3)]        // irezumi sleeves
        case .syndicate:    return [(3, 2), (4, 2), (6, 2), (7, 2), (5, 3)]  // circuit trace
        }
    }

    /// Headwear, one shape per era. Negative rows sit above the body grid.
    ///
    /// The *shape* carries the era; the *colour* stays the crab's own identity colour,
    /// so you can still tell two crabs apart at a glance even in the same era.
    static func hatCells(for era: Era) -> [(Int, Int)] {
        var c: [(Int, Int)] = []
        switch era {
        case .roman:            // laurel wreath: two leaf clusters, open at the top
            for x in [1, 2, 3, 7, 8, 9] { c.append((x, -1)) }
            c.append((0, -1)); c.append((10, -1))
            c.append((2, -2)); c.append((8, -2))

        case .medieval:         // spiked crown on a band
            for x in 2...8 { c.append((x, -1)) }
            for x in [2, 4, 6, 8] { c.append((x, -2)) }
            c.append((4, -3)); c.append((6, -3))

        case .renaissance:      // flat cap tilted up at the back, with a plume
            for x in 2...8 { c.append((x, -1)) }
            for x in 5...7 { c.append((x, -2)) }
            c.append((8, -3))

        case .prohibition:      // the classic fedora: pinched crown, wide brim
            c.append((4, -3)); c.append((6, -3))
            for x in 3...7 { c.append((x, -2)) }
            for x in 1...9 { c.append((x, -1)) }

        case .yakuza:           // hachimaki headband, knot trailing to one side
            for x in 1...9 { c.append((x, -1)) }
            c.append((10, -1)); c.append((10, -2))

        case .syndicate:        // cyber visor with a single antenna
            for x in 1...9 { c.append((x, -1)) }
            c.append((5, -2)); c.append((5, -3)); c.append((6, -3))
        }
        return c
    }

    // exposed so VoxelSprite can extrude the same geometry into 3D
    static var shellCellsPublic: [(Int, Int)] { shellCells }
    static var legCellsAPublic: [(Int, Int)] { legCellsA }
    static var legCellsBPublic: [(Int, Int)] { legCellsB }

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
            // the era is hashed from the name, so the skin has to follow it
            let e = Naming.era(for: newInfo.name)
            cap.path = Self.pixelPath(cells: Self.hatCells(for: e))
            accent.path = Self.pixelPath(cells: Self.accentCells(for: e))
            refreshVoxel()
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
        // Must live in the rig, not the body: the eyes are in the rig, so eyewear parked
        // on the body would stay put while the face rippled out from under it.
        rig.addSublayer(layer)
        accessoryLayer = layer
        layer.isHidden = Self.voxelMode      // 3D draws eyewear into the sprite instead
        if dancing { applyEyewearWave() }
    }

    /// Keeps the glasses riding the same wave as the eye cubes underneath them.
    private func applyEyewearWave() {
        guard let layer = accessoryLayer else { return }
        layer.removeAnimation(forKey: "cubeLift")
        guard dancing, !Self.voxelMode else { return }
        let lift = CABasicAnimation(keyPath: "transform.translation.y")
        lift.fromValue = -1.5
        lift.toValue = 3.5
        lift.duration = danceBeat / 2
        lift.autoreverses = true
        lift.repeatCount = .infinity
        lift.timeOffset = 5 * 0.055 + 3 * 0.045     // the eye row, averaged across the face
        lift.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(lift, forKey: "cubeLift")
    }

    /// Eyewear as grid cells, for the voxel renderer.
    static func eyewearCells(for mode: String?) -> [(Int, Int)] {
        switch mode {
        case "bypassPermissions":                        // wraparound shades
            return [(1, 3), (2, 3), (3, 3), (7, 3), (8, 3), (9, 3), (5, 3)]
        case "plan":                                     // round rims, open bridge
            return [(1, 3), (3, 3), (7, 3), (9, 3), (2, 2), (8, 2)]
        default:
            return []
        }
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
        bubble.show(Quips.random(.compacting), for: nil)
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
        bubble.show(Quips.random(.compacted), for: 2.6)
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
        bubble.show(Quips.random(.done), for: 3.0)
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
            bubble.show(Quips.random(.waiting), for: nil)
            nextHopAt = CACurrentMediaTime() + 0.4
        case .sleeping:
            slideRemaining = 0      // tick crawls us down to the bottom edge
            bubble.show(Quips.random(.sleeping), for: nil)
        case .working:
            nextChatterAt = CACurrentMediaTime() + Double.random(in: 8...20)
        default:
            break
        }
        nextDecisionAt = 0
        updateWired()
        refreshVoxel()
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

        // mappedState depends on wall-clock (the 10-minute sleep threshold, the working
        // pulse expiry) but the registry stays silent for a parked session, so nothing
        // else would ever re-evaluate it.
        stateRecheck += 1
        if stateRecheck % 30 == 0, state != .celebrating, traversal == nil {
            let mapped = mappedState()
            if mapped != state { applyState(mapped, animated: true) }
        }
        tickDance(now: now)
        if traversal != nil {          // a traversal owns placement until it lands
            stepTraversal(dt: 1.0 / 30.0)
            return
        }

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
            // Rope and rocket only make sense from the ceiling and the side walls, so on
            // the general trick timer they were nearly unreachable: a 10-25 minute
            // cooldown, then a one-in-three pick, and only if the crab happened to be
            // standing in the right place. Give them their own, much shorter clock that
            // only ticks while it is.
            if state == .idle, now >= nextMoodAt, DayMood.today != .none,
               beerMug == nil, loungerLayer == nil, traversal == nil {
                nextMoodAt = now + Double.random(in: 420...900)
                dayMoodBreak(now: now)
                break
            }
            if state == .idle, now >= nextTraversalAt, traversal == nil,
               currentSegment == 1 || currentSegment == 2 || currentSegment == 3 {
                nextTraversalAt = now + Double.random(in: 100...220)
                if currentSegment == 2 { startRope() } else { startRocket() }
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
                bubble.show(Quips.random(.working), for: 2.2)
            }
            if state == .idle && now >= nextMumbleAt {
                nextMumbleAt = now + Double.random(in: 180...480)
                bubble.show(mumble(), for: 2.4)
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
        bubble.show(Quips.random(.toast), for: 2.6)
    }

    var perimeterPosition: CGFloat { perimT }

    /// crabs shouldn't pile up — slide away from a too-close neighbour
    func separate(from other: PetView) {
        let now = CACurrentMediaTime()
        guard state != .celebrating, traversal == nil,
              now >= beerUntil, now >= trickUntil else { return }
        let delta = Self.shortestDelta(from: other.perimeterPosition, to: perimT, length: perimeterLength)
        slideDir = delta >= 0 ? 1 : -1
        if slideRemaining < 50 { slideRemaining = 50 }
        speed = max(speed, 36)
    }

    // MARK: - Traversals: crossing the screen instead of going round it
    //
    // Normally a crab is pinned to the perimeter by `perimT`. A traversal suspends that
    // for a few seconds and drives the frame directly, then drops the crab back onto the
    // ring at wherever it landed.

    private enum Traversal { case rope, rocket }

    /// What the day of the week does to a made man.
    enum DayMood {
        case fridayChill        // deckchair, sunglasses, no notes
        case saturdayHangover   // deckchair, but it hurts
        case mondayDisgust      // upright and thoroughly fed up
        case none

        static var today: DayMood {
            switch Calendar.current.component(.weekday, from: Date()) {
            case 6: return .fridayChill        // Calendar: 1 = Sunday
            case 7: return .saturdayHangover
            case 2: return .mondayDisgust
            default: return .none
            }
        }
    }
    private var traversal: Traversal?
    private var travFrom = CGPoint.zero
    private var travTo = CGPoint.zero
    private var travT: CGFloat = 0
    private var travSpeed: CGFloat = 0.4
    private var travProp: CALayer?

    var isTraversing: Bool { traversal != nil }
    var onCeiling: Bool { currentSegment == 2 }
    var onSideWall: Bool { currentSegment == 1 || currentSegment == 3 }

    /// Rappel from the ceiling straight down to the floor.
    private func startRope() {
        guard traversal == nil, currentSegment == 2 else { return }
        traversal = .rope
        travFrom = frame.origin
        travTo = CGPoint(x: frame.origin.x, y: roamArea.minY)
        travT = 0
        travSpeed = 0.45
        slideRemaining = 0
        setBodyAngle(0, animated: true)     // hangs upright on the line, not head-down

        let rope = CAShapeLayer()
        rope.strokeColor = NSColor(white: 0.85, alpha: 0.9).cgColor
        rope.lineWidth = 1.5
        rope.fillColor = nil
        rope.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        layer!.addSublayer(rope)
        travProp = rope
        bubble.show("🪢", for: 1.6)
    }

    /// Strap on a rocket and cross to the opposite wall.
    private func startRocket() {
        guard traversal == nil, currentSegment == 1 || currentSegment == 3 else { return }
        traversal = .rocket
        travFrom = frame.origin
        travTo = CGPoint(x: currentSegment == 1 ? roamArea.minX : roamArea.maxX, y: frame.origin.y)
        travT = 0
        travSpeed = 0.7
        slideRemaining = 0
        setBodyAngle(0, animated: true)

        let flame = CALayer()
        flame.backgroundColor = NSColor(srgbRed: 1, green: 0.65, blue: 0.2, alpha: 0.95).cgColor
        flame.bounds = CGRect(x: 0, y: 0, width: 16, height: 6)
        flame.cornerRadius = 3
        flame.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        let flicker = CABasicAnimation(keyPath: "bounds.size.width")
        flicker.fromValue = 10
        flicker.toValue = 22
        flicker.duration = 0.09
        flicker.autoreverses = true
        flicker.repeatCount = .infinity
        flame.add(flicker, forKey: "flicker")
        layer!.addSublayer(flame)
        travProp = flame
        bubble.show("🚀", for: 1.4)
    }

    private func stepTraversal(dt: CGFloat) {
        guard let kind = traversal else { return }
        travT = min(1, travT + travSpeed * dt)
        // ease out of the launch and into the landing
        let e = travT < 0.5 ? 2 * travT * travT : 1 - pow(-2 * travT + 2, 2) / 2
        let p = CGPoint(x: travFrom.x + (travTo.x - travFrom.x) * e,
                        y: travFrom.y + (travTo.y - travFrom.y) * e)
        setFrameOrigin(p)
        positionPill()

        switch kind {
        case .rope:
            // the line pays out from the ceiling down to the crab's head
            if let rope = travProp as? CAShapeLayer {
                let path = CGMutablePath()
                let topInView = travFrom.y - p.y + 96
                path.move(to: CGPoint(x: 75, y: topInView))
                path.addLine(to: CGPoint(x: 75, y: 88))
                rope.path = path
                rope.frame = bounds
            }
        case .rocket:
            let goingLeft = travTo.x < travFrom.x
            travProp?.position = CGPoint(x: goingLeft ? 104 : 46, y: 46)
        }

        if travT >= 1 { endTraversal() }
    }

    private func endTraversal() {
        travProp?.removeFromSuperlayer()
        travProp = nil
        traversal = nil
        // hand the crab back to the ring at wherever it actually landed
        perimT = Self.nearestPerimeterT(to: frame.origin, in: roamArea)
        currentSegment = -1
        applyPerimeterPosition()
        nextDecisionAt = CACurrentMediaTime() + Double.random(in: 1...3)
    }

    /// Perimeter parameter of the ring point closest to `p`.
    private static func nearestPerimeterT(to p: NSPoint, in area: RoamArea) -> CGFloat {
        let w = max(1, area.maxX - area.minX), h = max(1, area.maxY - area.minY)
        let dBottom = abs(p.y - area.minY), dTop = abs(area.maxY - p.y)
        let dLeft = abs(p.x - area.minX), dRight = abs(area.maxX - p.x)
        let best = min(dBottom, dTop, dLeft, dRight)
        let x = min(max(p.x - area.minX, 0), w), y = min(max(p.y - area.minY, 0), h)
        if best == dBottom { return x }
        if best == dRight { return w + y }
        if best == dTop { return w + h + (w - x) }
        return w + h + w + (h - y)
    }

    // MARK: - Rare tricks (spin / balloon ride)

    /// 0 spin · 1 balloon · 2 rope (ceiling only) · 3 rocket (side walls only)
    func doTrick(now: CFTimeInterval = CACurrentMediaTime(), forced: Int? = nil) {
        guard beerMug == nil, now >= trickUntil, traversal == nil else { return }

        // Bail before touching any state: a forced rope on a crab that isn't on the
        // ceiling used to silently consume the cooldown and mute its real tricks for
        // up to 25 minutes.
        if forced == 2 && currentSegment != 2 { return }
        if forced == 3 && !(currentSegment == 1 || currentSegment == 3) { return }

        nextTrickAt = now + Double.random(in: 600...1500)
        slideRemaining = 0
        legPhase = 0
        legs.path = Self.legsFrameA

        // the two traversals only make sense from the right edge, so they join the
        // random pool only when the crab is actually standing somewhere they work
        var pool = [0, 1]
        if currentSegment == 2 { pool.append(2) }
        if currentSegment == 1 || currentSegment == 3 { pool.append(3) }
        let kind = forced ?? pool.randomElement()!

        if kind == 2 { startRope(); return }
        if kind == 3 { startRocket(); return }
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
            self.bubble.show(Quips.random(.beer), for: 1.8)
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
    // MARK: - Day-of-week moods

    /// Friday and Saturday: the crab unfolds a deckchair on the edge and lies in it.
    /// Monday: no chair, just a very poor attitude.
    func dayMoodBreak(now: CFTimeInterval = CACurrentMediaTime(), forced: DayMood? = nil) {
        let mood = forced ?? DayMood.today
        guard mood != .none, beerMug == nil, loungerLayer == nil else { return }

        let kind: QuipKind
        let seconds: Double
        switch mood {
        case .fridayChill:      kind = .friday;   seconds = 9
        case .saturdayHangover: kind = .saturday; seconds = 11
        case .mondayDisgust:    kind = .monday;   seconds = 6
        case .none:             return
        }

        moodUntil = now + seconds
        trickUntil = moodUntil          // the shared "busy with something" gate
        slideRemaining = 0
        legPhase = 0
        legs.path = Self.legsFrameA
        bubble.show(Quips.random(kind), for: seconds - 1.5)

        if mood == .mondayDisgust {
            // no prop: a slow, unimpressed head shake and a scowl
            squint(true)
            let shake = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            shake.values = [0, 0.09, -0.09, 0.07, -0.07, 0]
            shake.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1]
            shake.duration = 2.2
            shake.repeatCount = 2
            rig.add(shake, forKey: "monday")
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
                self?.rig.removeAnimation(forKey: "monday")
                self?.squint(false)
            }
            return
        }

        let chair = Self.makeLounger(hungover: mood == .saturdayHangover)
        chair.position = CGPoint(x: 30, y: 16)
        body.insertSublayer(chair, at: 0)        // behind the crab, it lies on it
        loungerLayer = chair

        let unfold = CASpringAnimation(keyPath: "transform.scale")
        unfold.fromValue = 0.01
        unfold.toValue = 1
        unfold.damping = 11
        unfold.initialVelocity = 4
        unfold.duration = unfold.settlingDuration
        chair.add(unfold, forKey: "unfold")

        // lean back into it
        let recline = CABasicAnimation(keyPath: "transform.rotation.z")
        recline.fromValue = 0
        recline.toValue = -0.34
        recline.duration = 0.7
        recline.fillMode = .forwards
        recline.isRemovedOnCompletion = false
        rig.add(recline, forKey: "recline")

        if mood == .saturdayHangover {
            // a queasy sway rather than a contented one
            let sway = CAKeyframeAnimation(keyPath: "transform.translation.y")
            sway.values = [0, -1.5, 0, -1.5, 0]
            sway.keyTimes = [0, 0.25, 0.5, 0.75, 1]
            sway.duration = 2.6
            sway.repeatCount = Float(seconds / 2.6)
            sway.beginTime = CACurrentMediaTime() + 0.7
            rig.add(sway, forKey: "queasy")
        }
        squint(true)

        DispatchQueue.main.asyncAfter(deadline: .now() + seconds - 0.6) { [weak self] in
            guard let self else { return }
            let fold = CABasicAnimation(keyPath: "transform.rotation.z")
            fold.fromValue = -0.34
            fold.toValue = 0
            fold.duration = 0.5
            self.rig.add(fold, forKey: "recline")
            self.rig.removeAnimation(forKey: "queasy")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            guard let self else { return }
            self.loungerLayer?.removeFromSuperlayer()
            self.loungerLayer = nil
            self.rig.removeAnimation(forKey: "recline")
            self.squint(false)
        }
    }

    /// A striped pixel deckchair. Same drawing approach as the beer mug: flat rects, no
    /// image assets anywhere in this repo.
    private static func makeLounger(hungover: Bool) -> CALayer {
        let px: CGFloat = 3
        let group = CALayer()
        group.bounds = CGRect(x: 0, y: 0, width: 11 * px, height: 7 * px)
        group.anchorPoint = CGPoint(x: 0.5, y: 0.1)

        func rect(_ col: Int, _ row: Int) -> CGRect {
            CGRect(x: CGFloat(col) * px, y: CGFloat(6 - row) * px, width: px, height: px)
        }

        let scale = NSScreen.main?.backingScaleFactor ?? 2

        // the reclined seat: a back that rises to the left, then a flat base
        let canvasPath = CGMutablePath()
        for (col, row) in [(0,1),(1,1),(1,2),(2,2),(2,3),(3,3),(3,4),(4,4),
                           (5,4),(6,4),(7,4),(8,4),(9,4)] {
            canvasPath.addRect(rect(col, row))
        }
        let canvas = CAShapeLayer()
        canvas.path = canvasPath
        canvas.fillColor = (hungover
            ? NSColor(srgbRed: 0.42, green: 0.45, blue: 0.52, alpha: 1)     // washed out
            : NSColor(srgbRed: 0.95, green: 0.52, blue: 0.28, alpha: 1)).cgColor
        canvas.contentsScale = scale
        group.addSublayer(canvas)

        // the stripe every deckchair has
        let stripePath = CGMutablePath()
        for (col, row) in [(1,1),(3,3),(6,4),(8,4)] { stripePath.addRect(rect(col, row)) }
        let stripe = CAShapeLayer()
        stripe.path = stripePath
        stripe.fillColor = NSColor(srgbRed: 0.98, green: 0.93, blue: 0.85, alpha: 1).cgColor
        stripe.contentsScale = scale
        group.addSublayer(stripe)

        // legs
        let framePath = CGMutablePath()
        for (col, row) in [(1,3),(2,4),(3,5),(4,5),(9,5),(9,6),(4,6)] {
            framePath.addRect(rect(col, row))
        }
        let frame = CAShapeLayer()
        frame.path = framePath
        frame.fillColor = NSColor(srgbRed: 0.38, green: 0.28, blue: 0.20, alpha: 1).cgColor
        frame.contentsScale = scale
        group.addSublayer(frame)

        return group
    }

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
            refreshVoxel()
        }
    }

    /// sleeping pets crawl the shortest way around the ring down to the bottom edge
    private func crawlTowardBottom() {
        let delta = Self.shortestDelta(from: perimT, to: sleepingSpotT, length: perimeterLength)
        guard abs(delta) > 3 else { rest(); return }
        restingSince = 0
        slideDir = delta > 0 ? 1 : -1
        crawl(by: min(70.0 / 30.0, abs(delta)))
    }

    /// A crab that has been asleep in the same patch for a minute gets sick of it, says
    /// so, and shuffles off to a different stretch of floor. Without this a parked
    /// session is a statue in one corner for the rest of the day.
    private func rest() {
        let now = CACurrentMediaTime()
        if restingSince == 0 { restingSince = now; return }
        guard now - restingSince > 60 else { return }
        restingSince = 0
        // somewhere genuinely else: at least a fifth of the floor away
        let w = max(1, roamArea.maxX - roamArea.minX)
        var next = CGFloat.random(in: 0...w)
        if let bed = sleepBed, abs(next - bed) < w / 5 { next = w - next }
        sleepBed = next
        bubble.show(Quips.random(.grumble), for: 2.6)
        smallHop()
    }

    // MARK: - Perimeter geometry

    private var perimeterLength: CGFloat {
        let w = max(1, roamArea.maxX - roamArea.minX)
        let h = max(1, roamArea.maxY - roamArea.minY)
        return 2 * (w + h)
    }

    /// Each crab gets its own patch of floor, or they all pile into the same corner.
    /// Where this crab sleeps. Starts under wherever its terminal is, offset by a
    /// per-session amount so two crabs don't pile into the same corner, and moves
    /// whenever `rest()` decides it has lain there long enough.
    private var sleepingSpotT: CGFloat {
        let w = max(1, roamArea.maxX - roamArea.minX)
        if let bed = sleepBed { return min(max(bed, 0), w) }
        let bed = CGFloat(Naming.hash(sessionId) % 140)
        return min(max(frame.origin.x - roamArea.minX + bed - 70, 0), w)
    }

    /// Forget the current edge position — the next tick re-seats the crab on its ring.
    /// Used when a crab is moved to a different display.
    /// The ring changes at runtime (Space switches, resolution, the Dock). A crab that
    /// isn't crawling never re-applies its position on its own, so the one waiting on your
    /// permission would hang detached from the edge — the worst possible one to lose.
    func setRoamArea(_ area: RoamArea) {
        guard area != roamArea else { return }
        roamArea = area
        currentSegment = -1
        if traversal == nil && perimT >= 0 { applyPerimeterPosition() }
    }

    func resetPlacement() {
        perimT = -1
        currentSegment = -1
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
            positionPill()   // the clamp depends on where we are on screen
        }
        if seg != currentSegment {
            let firstTime = currentSegment < 0
            currentSegment = seg
            // legs point at the edge: local -y rotated by θ lands at (sin θ, -cos θ)
            // bottom → 0, right wall → +90° CCW, ceiling → 180°, left wall → -90°
            let angles: [CGFloat] = [0, .pi / 2, .pi, -.pi / 2]
            setBodyAngle(angles[seg], animated: !firstTime)
            // On the floor the crab sits at the very bottom of the screen, so its label
            // and bubble have to go above it; on the ceiling the bubble goes below.
            let bubbleY: CGFloat = seg == 2 ? 22 : (seg == 0 ? 122 : 90)
            bubble.setFrameOrigin(NSPoint(x: bubble.frame.origin.x, y: bubbleY))
            positionPill()
        }
    }

    /// label sits under the crab everywhere except the floor, where there's no room
    private var pillBaseY: CGFloat { currentSegment == 0 ? 100 : 2 }

    /// keep the name pill on-screen: shift it inward on the side edges
    private var pillCenterX: CGFloat {
        switch currentSegment {
        case 1: return 42    // right wall → pill toward screen center
        case 3: return 108   // left wall
        default: return 75
        }
    }

    /// Keeps the label on screen, not merely inside the crab's own box — at the side
    /// walls the pet frame hangs off the display, so clamping locally isn't enough.
    private func positionPill() {
        let w = namePill.frame.width
        var x = pillCenterX - w / 2
        if let sv = superview, sv.bounds.width > w + 8 {
            let lowest = -frame.origin.x + 4
            let highest = sv.bounds.width - frame.origin.x - w - 4
            x = min(max(x, lowest), highest)
        }
        namePill.setFrameOrigin(NSPoint(x: x, y: pillBaseY))
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

    // MARK: - Dancing (something on this Mac is playing sound)

    /// A crab dances *while* it goes about its business — it keeps crawling, working and
    /// taking its beer break. The dance lives entirely on `rig`, so it deforms the body
    /// without ever touching the placement transform underneath.
    private enum DanceMove: CaseIterable { case bounce, twist, shuffle, headbang }

    private var dancing = false
    private var danceBeat = 0.42
    private var danceMove: DanceMove = .bounce
    private var nextMoveAt: CFTimeInterval = 0

    private var musicOn = false
    private var danceUntil: CFTimeInterval = 0
    private var resumeDanceAt: CFTimeInterval = 0

    /// Music starting doesn't mean dancing non-stop — a crab dances a stretch, then takes
    /// a breather, then goes again, on its own clock. Called by the manager.
    func setMusicPlaying(_ on: Bool) {
        guard on != musicOn else { return }
        musicOn = on
        if on {
            resumeDanceAt = CACurrentMediaTime() + Double.random(in: 0...5)   // staggered entry
        } else {
            setDancing(false)
        }
    }

    /// Drives the dance/rest cycle. Runs every tick while music is playing.
    private func tickDance(now: CFTimeInterval) {
        guard musicOn else { return }
        if dancing {
            if now >= danceUntil {
                setDancing(false)
                resumeDanceAt = now + Double.random(in: 25...35)   // sit one out
            } else if now >= nextMoveAt {
                nextMoveAt = now + danceBeat * Double.random(in: 6...10)
                var next = danceMove
                while next == danceMove { next = DanceMove.allCases.randomElement()! }
                danceMove = next
                applyDance()
            }
        } else if now >= resumeDanceAt {
            setDancing(true)
            danceUntil = now + Double.random(in: 25...35)
        }
    }

    private func setDancing(_ on: Bool) {
        guard on != dancing else { return }
        dancing = on
        if on {
            danceBeat = 0.42 + Double.random(in: -0.05...0.05)   // nobody dances in lockstep
            danceMove = DanceMove.allCases.randomElement()!
            nextMoveAt = CACurrentMediaTime() + danceBeat * 8
            applyDance()
        } else {
            teardownDanceCubes()
            for k in ["swayR", "bobY", "shuffleX", "squashY", "stretchX", "hatLag"] {
                rig.removeAnimation(forKey: k)
                cap.removeAnimation(forKey: k)
            }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            rig.transform = CATransform3DIdentity
            cap.transform = CATransform3DIdentity
            CATransaction.commit()
        }
    }

    // The real dance: the shell is torn apart into its individual pixel cubes and a wave
    // is run through them. Each cube's delay comes from its position on the grid, so the
    // ripple travels diagonally across the body instead of everything pulsing at once.
    // Cubes only exist while the music is on; the rest of the time the shell is one path.
    private var danceCubes: [CALayer] = []
    private let cubeHolder = CALayer()

    private func buildDanceCubes() {
        teardownDanceCubes()
        let e = era
        let groups: [([(Int, Int)], CGColor?)] = [
            (Self.shellCellsPublic, shell.fillColor),
            (Self.accentCells(for: e), accent.fillColor),
            (Self.hatCells(for: e), cap.fillColor),
        ]
        let b = danceBeat
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let vox = Self.voxelMode
        let vpx: CGFloat = 4.5

        // In 3D the cubes are real voxel columns, so they have to be laid out with the
        // same isometric projection the static sprite uses — otherwise the crab would
        // reassemble in the wrong shape when the music stops.
        var isoOffset = CGPoint.zero
        var isoMaxY: CGFloat = 0
        if vox {
            let pts = groups.flatMap { $0.0 }.map { Self.isoPointFor($0, pixel: vpx) }
            if !pts.isEmpty {
                let minX = pts.map(\.x).min()!, maxX = pts.map(\.x).max()!
                let minY = pts.map(\.y).min()!, maxY = pts.map(\.y).max()!
                isoMaxY = maxY
                isoOffset = CGPoint(x: 40 - (minX + maxX) / 2, y: 42 - (maxY - minY) / 2)
            }
        }

        for (cells, color) in groups {
            for (col, row) in cells {
                let cube = CALayer()
                if vox, let c = color,
                   let img = VoxelSprite.columnImage(color: NSColor(cgColor: c) ?? Self.claudeOrange,
                                                     pixel: vpx) {
                    cube.contents = img
                    cube.bounds = CGRect(x: 0, y: 0,
                                         width: CGFloat(img.width) / scale,
                                         height: CGFloat(img.height) / scale)
                    let p = Self.isoPointFor((col, row), pixel: vpx)
                    cube.position = CGPoint(x: p.x + isoOffset.x,
                                            y: (isoMaxY - p.y) + isoOffset.y)
                } else {
                    cube.backgroundColor = color
                    cube.frame = Self.cellRect(col: col, row: row)
                }
                cube.contentsScale = scale

                // diagonal travelling wave: further right and further down = later
                let phase = Double(col) * 0.055 + Double(row) * 0.045

                let lift = CABasicAnimation(keyPath: "transform.translation.y")
                lift.fromValue = -1.5
                lift.toValue = 3.5
                lift.duration = b / 2
                lift.autoreverses = true
                lift.repeatCount = .infinity
                lift.timeOffset = phase
                lift.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                cube.add(lift, forKey: "cubeLift")

                let pulse = CABasicAnimation(keyPath: "transform.scale")
                pulse.fromValue = 0.94
                pulse.toValue = 1.12
                pulse.duration = b / 2
                pulse.autoreverses = true
                pulse.repeatCount = .infinity
                pulse.timeOffset = phase
                cube.add(pulse, forKey: "cubePulse")

                cubeHolder.addSublayer(cube)
                danceCubes.append(cube)
            }
        }
        // the eyes ride the same wave as the cell they sit in, so the face doesn't
        // detach from the body
        for (eye, col) in [(eyeLeft, 2), (eyeRight, 8)] {
            let lift = CABasicAnimation(keyPath: "transform.translation.y")
            lift.fromValue = -1.5
            lift.toValue = 3.5
            lift.duration = b / 2
            lift.autoreverses = true
            lift.repeatCount = .infinity
            lift.timeOffset = Double(col) * 0.055 + 3 * 0.045
            eye.add(lift, forKey: "cubeLift")
        }

        applyEyewearWave()
        for l in [shell, accent, cap] { l.isHidden = true }
        voxel.isHidden = true               // the shattered cubes replace the single sprite
        cubeHolder.isHidden = false
    }

    static func isoPointFor(_ cell: (Int, Int), pixel: CGFloat) -> CGPoint {
        VoxelSprite.isoPoint(col: cell.0, row: cell.1, pixel: pixel)
    }

    private func teardownDanceCubes() {
        danceCubes.forEach { $0.removeFromSuperlayer() }
        danceCubes.removeAll()
        cubeHolder.isHidden = true
        eyeLeft.removeAnimation(forKey: "cubeLift")
        eyeRight.removeAnimation(forKey: "cubeLift")
        accessoryLayer?.removeAnimation(forKey: "cubeLift")
        if Self.voxelMode {
            voxel.isHidden = false
        } else {
            for l in [shell, accent, cap] { l.isHidden = false }
        }
    }

    private func applyDance() {
        guard dancing else { return }
        let b = danceBeat
        // Only 2D shatters. In an isometric view, what's in front of what is decided when
        // the image is composed; once the columns move, the layer order no longer matches
        // the geometry and the crab collapses into a jumble. 3D dances as a whole body.
        if !Self.voxelMode { buildDanceCubes() }

        func anim(_ path: String, _ from: Double, _ to: Double,
                  _ dur: Double, offset: Double = 0,
                  curve: CAMediaTimingFunctionName = .easeInEaseOut) -> CABasicAnimation {
            let a = CABasicAnimation(keyPath: path)
            a.fromValue = from
            a.toValue = to
            a.duration = dur
            a.autoreverses = true
            a.repeatCount = .infinity
            a.timingFunction = CAMediaTimingFunction(name: curve)
            a.timeOffset = offset
            return a
        }

        rig.removeAllAnimations()
        cap.removeAllAnimations()

        switch danceMove {
        case .bounce:
            // squash on the landing, stretch on the way up — volume roughly preserved
            rig.add(anim("transform.translation.y", 0, 13, b / 2, curve: .easeOut), forKey: "bobY")
            rig.add(anim("transform.scale.y", 0.86, 1.13, b / 2), forKey: "squashY")
            rig.add(anim("transform.scale.x", 1.11, 0.93, b / 2), forKey: "stretchX")
            rig.add(anim("transform.rotation.z", -0.05, 0.05, b), forKey: "swayR")

        case .twist:
            rig.add(anim("transform.rotation.z", -0.30, 0.30, b), forKey: "swayR")
            rig.add(anim("transform.translation.y", 0, 5, b / 2), forKey: "bobY")
            rig.add(anim("transform.scale.y", 0.96, 1.05, b / 2), forKey: "squashY")

        case .shuffle:
            rig.add(anim("transform.translation.x", -8, 8, b), forKey: "shuffleX")
            // quarter-beat offset so the lean trails the step instead of matching it
            rig.add(anim("transform.rotation.z", -0.14, 0.14, b, offset: b / 4), forKey: "swayR")
            rig.add(anim("transform.translation.y", 0, 6, b / 2), forKey: "bobY")

        case .headbang:
            rig.add(anim("transform.rotation.z", -0.06, 0.36, b / 2, curve: .easeIn), forKey: "swayR")
            rig.add(anim("transform.translation.y", 0, 9, b / 2, curve: .easeOut), forKey: "bobY")
            rig.add(anim("transform.scale.y", 1.06, 0.90, b / 2), forKey: "squashY")
        }

        // secondary motion: the hat always lands a beat-fraction after the head does,
        // which is most of what sells the whole thing as weight rather than wobble
        cap.add(anim("transform.translation.y", -2, 4, b / 2, offset: b * 0.16), forKey: "hatLag")
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
        let baby = Self.makeBaby(capColor: cap.fillColor, era: era)   // kids wear the family hat
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

    private static func makeBaby(capColor: CGColor?, era: Era) -> CALayer {
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
        group.addSublayer(shape(hatCells(for: era), capColor ?? claudeOrange.cgColor))
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
        // .common mode, or blinking freezes for as long as a menu is tracking
        let t = Timer(timeInterval: Double.random(in: 2.4...6.5), repeats: false) { [weak self] _ in
            guard let self else { return }
            if self.state != .sleeping { self.blinkOnce() }
            self.scheduleBlink()
        }
        RunLoop.main.add(t, forMode: .common)
        blinkTimer = t
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

    /// pill: made name (rank + given + family) · effort when it's worth bragging about
    private func refreshPill() {
        var text = madeName.full
        if let e = effortLevel, e == "xhigh" || e == "max" { text += " · \(e)" }
        namePill.stringValue = text
        namePill.sizeToFit()
        namePill.setFrameSize(NSSize(width: namePill.frame.width + 12,
                                     height: namePill.frame.height + 3))
        positionPill()
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
        let title = NSMenuItem(title: "\(madeName.full)  (\(info.name) — \(info.status))", action: nil, keyEquivalent: "")
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
            let t = Timer(timeInterval: duration, repeats: false) { [weak self] _ in
                self?.hide()
            }
            RunLoop.main.add(t, forMode: .common)
            hideTimer = t
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
