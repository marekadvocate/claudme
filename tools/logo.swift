import AppKit

// Isometric voxel logo generator. One model per variant; the same voxels feed the
// contact sheet, the standalone PNG and the SVG, so nothing can drift apart.

struct Voxel { let x, y, z: Int; let kind: Kind }
enum Kind { case shell, hat, eye, claw, accent }

struct Shades { let top, left, right: NSColor }
struct Palette {
    var shell: Shades, hat: Shades, eye: Shades, claw: Shades, accent: Shades
    func of(_ k: Kind) -> Shades {
        switch k {
        case .shell: return shell; case .hat: return hat
        case .eye: return eye; case .claw: return claw; case .accent: return accent
        }
    }
}

func rgb(_ r: Int, _ g: Int, _ b: Int) -> NSColor {
    NSColor(srgbRed: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
}
/// One base colour → the three face shades that create the sense of volume.
func shades(_ r: Int, _ g: Int, _ b: Int) -> Shades {
    func mul(_ f: Double) -> NSColor {
        rgb(min(255, Int(Double(r)*f)), min(255, Int(Double(g)*f)), min(255, Int(Double(b)*f)))
    }
    return Shades(top: mul(1.16), left: mul(0.82), right: mul(0.62))
}

let crabPal = Palette(shell: shades(201, 96, 63), hat: shades(58, 52, 47),
                      eye: shades(26, 24, 22), claw: shades(190, 86, 55),
                      accent: shades(232, 176, 75))
let noirPal = Palette(shell: shades(70, 64, 60), hat: shades(201, 96, 63),
                      eye: shades(240, 235, 228), claw: shades(84, 76, 70),
                      accent: shades(232, 176, 75))
let goldPal = Palette(shell: shades(201, 96, 63), hat: shades(38, 35, 32),
                      eye: shades(26, 24, 22), claw: shades(190, 86, 55),
                      accent: shades(232, 176, 75))

// MARK: - builder helper

final class Build {
    var v: [Voxel] = []
    func add(_ xs: ClosedRange<Int>, _ ys: ClosedRange<Int>, _ zs: ClosedRange<Int>, _ k: Kind) {
        for x in xs { for y in ys { for z in zs { v.append(Voxel(x: x, y: y, z: z, kind: k)) } } }
    }
    func one(_ x: Int, _ y: Int, _ z: Int, _ k: Kind) { v.append(Voxel(x: x, y: y, z: z, kind: k)) }
}

struct Variant { let name: String, note: String, pal: Palette, model: [Voxel] }

func make(_ name: String, _ note: String, _ pal: Palette, _ body: (Build) -> Void) -> Variant {
    let b = Build(); body(b); return Variant(name: name, note: note, pal: pal, model: b.v)
}

let variants: [Variant] = [

  make("01-classic", "the current one", crabPal) { b in
    b.add(1...9, 1...5, 1...3, .shell)
    for x in [1,3,7,9] { b.add(x...x,1...1,0...0,.shell); b.add(x...x,5...5,0...0,.shell) }
    b.add(0...0,5...5,2...3,.claw); b.add(10...10,5...5,2...3,.claw)
    b.add(0...0,4...4,2...2,.claw); b.add(10...10,4...4,2...2,.claw)
    b.add(3...7,1...5,4...4,.hat); b.add(4...6,2...4,5...5,.hat)
    b.one(4,5,2,.eye); b.one(6,5,2,.eye)
  },

  make("02-minimal", "fewest voxels, best at 16px", crabPal) { b in
    b.add(1...7,1...4,1...2,.shell)
    for x in [1,4,7] { b.add(x...x,1...1,0...0,.shell); b.add(x...x,4...4,0...0,.shell) }
    b.add(0...0,4...4,2...2,.claw); b.add(8...8,4...4,2...2,.claw)
    b.add(2...6,1...4,3...3,.hat)
    b.one(3,4,2,.eye); b.one(5,4,2,.eye)
  },

  make("03-tall-don", "tall crown, imposing", crabPal) { b in
    b.add(1...8,1...4,1...2,.shell)
    for x in [1,4,8] { b.add(x...x,1...1,0...0,.shell); b.add(x...x,4...4,0...0,.shell) }
    b.add(0...0,4...4,2...2,.claw); b.add(9...9,4...4,2...2,.claw)
    b.add(2...7,1...4,3...3,.hat)
    b.add(3...6,2...3,4...5,.hat)
    b.add(4...5,2...3,6...6,.hat)
    b.one(3,4,2,.eye); b.one(6,4,2,.eye)
  },

  make("04-wide-boss", "low and wide, heavy", crabPal) { b in
    b.add(0...11,1...6,1...2,.shell)
    for x in [0,3,8,11] { b.add(x...x,1...1,0...0,.shell); b.add(x...x,6...6,0...0,.shell) }
    b.add(4...8,1...6,3...3,.hat); b.add(5...7,2...5,4...4,.hat)
    b.one(4,6,2,.eye); b.one(7,6,2,.eye)
  },

  make("05-big-claws", "pincers up, hat small", crabPal) { b in
    b.add(2...8,1...5,1...3,.shell)
    for x in [2,5,8] { b.add(x...x,1...1,0...0,.shell); b.add(x...x,5...5,0...0,.shell) }
    b.add(0...1,4...5,2...4,.claw)          // chunky raised pincers
    b.add(9...10,4...5,2...4,.claw)
    b.add(4...6,2...4,4...4,.hat); b.add(5...5,3...3,5...5,.hat)
    b.one(4,5,2,.eye); b.one(6,5,2,.eye)
  },

  make("06-no-hat", "pure crab, no mafia", crabPal) { b in
    b.add(1...9,1...5,1...3,.shell)
    for x in [1,3,7,9] { b.add(x...x,1...1,0...0,.shell); b.add(x...x,5...5,0...0,.shell) }
    b.add(0...0,4...5,2...3,.claw); b.add(10...10,4...5,2...3,.claw)
    b.add(3...7,2...4,4...4,.shell)          // domed shell instead of a hat
    b.one(4,5,3,.eye); b.one(6,5,3,.eye)
  },

  make("07-monogram-c", "abstract iso C", goldPal) { b in
    // a blocky letter C built as a wall, read straight on
    let cells: [(Int,Int)] = [(1,0),(2,0),(3,0),(4,0),
                              (0,1),(0,2),(0,3),(0,4),
                              (1,5),(2,5),(3,5),(4,5)]
    for (x,z) in cells { b.add(x...x, 2...3, z...z, .shell) }
    b.add(1...4,2...3,6...6,.hat)            // fedora across the top of the C
    b.add(2...3,2...3,7...7,.hat)
  },

  make("08-cube-face", "one cube, a face on it", crabPal) { b in
    b.add(0...5,0...5,0...5,.shell)          // solid cube
    b.add(1...4,0...5,6...6,.hat)            // brim
    b.add(2...3,1...4,7...7,.hat)            // crown
    b.one(1,5,4,.eye); b.one(4,5,4,.eye)     // face on the front plane
    b.add(0...0,5...5,2...3,.claw); b.add(5...5,5...5,2...3,.claw)
  },

  make("09-noir", "dark shell, orange hat", noirPal) { b in
    b.add(1...9,1...5,1...3,.shell)
    for x in [1,3,7,9] { b.add(x...x,1...1,0...0,.shell); b.add(x...x,5...5,0...0,.shell) }
    b.add(0...0,5...5,2...3,.claw); b.add(10...10,5...5,2...3,.claw)
    b.add(3...7,1...5,4...4,.hat); b.add(4...6,2...4,5...5,.hat)
    b.one(4,5,2,.eye); b.one(6,5,2,.eye)
  },

  make("10-gold-band", "black hat, gold band", goldPal) { b in
    b.add(1...9,1...5,1...3,.shell)
    for x in [1,3,7,9] { b.add(x...x,1...1,0...0,.shell); b.add(x...x,5...5,0...0,.shell) }
    b.add(0...0,5...5,2...3,.claw); b.add(10...10,5...5,2...3,.claw)
    b.add(3...7,1...5,4...4,.accent)         // brim as the gold band
    b.add(4...6,2...4,5...6,.hat)            // tall black crown above it
    b.one(4,5,2,.eye); b.one(6,5,2,.eye)
  },
]

// MARK: - isometric projection

struct Face { let pts: [CGPoint]; let color: NSColor }

func faces(_ v: Variant, hw: CGFloat, ox: CGFloat, oy: CGFloat) -> [Face] {
    let hh = hw / 2, hz = hw
    // Only these three faces can ever be seen from this angle, and each is hidden
    // when another voxel sits against it. Culling keeps a solid block from emitting
    // hundreds of invisible polygons into the SVG.
    var occupied = Set<Int>()
    let key = { (x: Int, y: Int, z: Int) in (x + 64) << 20 | (y + 64) << 10 | (z + 64) }
    for vox in v.model { occupied.insert(key(vox.x, vox.y, vox.z)) }

    var out: [Face] = []
    for vox in v.model.sorted(by: { ($0.x + $0.y + $0.z) < ($1.x + $1.y + $1.z) }) {
        let sx = ox + CGFloat(vox.x - vox.y) * hw
        let sy = oy + CGFloat(vox.x + vox.y) * hh - CGFloat(vox.z) * hz
        let s = v.pal.of(vox.kind)
        if !occupied.contains(key(vox.x, vox.y, vox.z + 1)) {
            out.append(Face(pts: [CGPoint(x: sx, y: sy - hh), CGPoint(x: sx + hw, y: sy),
                                  CGPoint(x: sx, y: sy + hh), CGPoint(x: sx - hw, y: sy)], color: s.top))
        }
        if !occupied.contains(key(vox.x, vox.y + 1, vox.z)) {
            out.append(Face(pts: [CGPoint(x: sx - hw, y: sy), CGPoint(x: sx, y: sy + hh),
                                  CGPoint(x: sx, y: sy + hh + hz), CGPoint(x: sx - hw, y: sy + hz)], color: s.left))
        }
        if !occupied.contains(key(vox.x + 1, vox.y, vox.z)) {
            out.append(Face(pts: [CGPoint(x: sx + hw, y: sy), CGPoint(x: sx, y: sy + hh),
                                  CGPoint(x: sx, y: sy + hh + hz), CGPoint(x: sx + hw, y: sy + hz)], color: s.right))
        }
    }
    return out
}

func bounds(_ v: Variant, hw: CGFloat) -> CGRect {
    let f = faces(v, hw: hw, ox: 0, oy: 0)
    let xs = f.flatMap { $0.pts.map(\.x) }, ys = f.flatMap { $0.pts.map(\.y) }
    return CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
}

/// Draws a variant fitted into `rect`. Assumes a y-down (flipped) context.
func drawFitted(_ v: Variant, in rect: CGRect, ctx: CGContext) {
    let b1 = bounds(v, hw: 1)
    let hw = min(rect.width / b1.width, rect.height / b1.height)
    let b = bounds(v, hw: hw)
    let ox = rect.minX + (rect.width - b.width)/2 - b.minX
    let oy = rect.minY + (rect.height - b.height)/2 - b.minY
    for f in faces(v, hw: hw, ox: ox, oy: oy) {
        ctx.beginPath()
        ctx.move(to: f.pts[0])
        for p in f.pts.dropFirst() { ctx.addLine(to: p) }
        ctx.closePath()
        ctx.setFillColor(f.color.cgColor)
        ctx.fillPath()
    }
}

func newContext(_ w: Int, _ h: Int) -> CGContext? {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
}

func writePNG(_ ctx: CGContext, _ url: URL) {
    guard let img = ctx.makeImage() else { return }
    if let d = NSBitmapImageRep(cgImage: img).representation(using: .png, properties: [:]) {
        try? d.write(to: url)
    }
}

// MARK: - outputs

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

// one PNG per variant
for v in variants {
    let S = 512
    guard let ctx = newContext(S, S) else { continue }
    ctx.translateBy(x: 0, y: CGFloat(S)); ctx.scaleBy(x: 1, y: -1)
    drawFitted(v, in: CGRect(x: 24, y: 24, width: CGFloat(S)-48, height: CGFloat(S)-48), ctx: ctx)
    writePNG(ctx, out.appendingPathComponent("\(v.name).png"))
}

// contact sheet: 5 x 2, each cell showing the big render plus 48px and 24px versions
let cols = 5, rows = 2, cell = 320, labelH = 54
let sheetW = cols * cell, sheetH = rows * (cell + labelH)
if let ctx = newContext(sheetW, sheetH) {
    ctx.setFillColor(rgb(13, 12, 11).cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: sheetW, height: sheetH))

    for (i, v) in variants.enumerated() {
        let cx = (i % cols) * cell
        let cyTop = (i / cols) * (cell + labelH)

        ctx.saveGState()
        ctx.translateBy(x: 0, y: CGFloat(sheetH)); ctx.scaleBy(x: 1, y: -1)
        // main render
        drawFitted(v, in: CGRect(x: CGFloat(cx) + 26, y: CGFloat(cyTop) + 20,
                                 width: CGFloat(cell) - 110, height: CGFloat(cell) - 52), ctx: ctx)
        // small sizes stacked on the right, to judge legibility
        drawFitted(v, in: CGRect(x: CGFloat(cx) + CGFloat(cell) - 74, y: CGFloat(cyTop) + 40,
                                 width: 48, height: 48), ctx: ctx)
        drawFitted(v, in: CGRect(x: CGFloat(cx) + CGFloat(cell) - 62, y: CGFloat(cyTop) + 104,
                                 width: 24, height: 24), ctx: ctx)
        ctx.restoreGState()
    }

    // labels, drawn upright via AppKit
    let nsctx = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsctx
    for (i, v) in variants.enumerated() {
        let cx = CGFloat((i % cols) * cell)
        let cyTop = CGFloat((i / cols) * (cell + labelH))
        let yBase = CGFloat(sheetH) - cyTop - CGFloat(cell) - 34
        let title = NSAttributedString(string: v.name, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 15, weight: .bold),
            .foregroundColor: rgb(243, 236, 228)])
        title.draw(at: CGPoint(x: cx + 26, y: yBase + 14))
        let note = NSAttributedString(string: v.note, attributes: [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: rgb(150, 140, 130)])
        note.draw(at: CGPoint(x: cx + 26, y: yBase - 4))
    }
    NSGraphicsContext.restoreGraphicsState()
    writePNG(ctx, out.appendingPathComponent("variants.png"))
}

// MARK: - the chosen mark: iconset, standalone PNG and SVG

let chosenName = ProcessInfo.processInfo.environment["LOGO"] ?? "08-cube-face"
guard let chosen = variants.first(where: { $0.name == chosenName }) else {
    fatalError("unknown variant \(chosenName)")
}

/// App icon: the mark on a dark rounded plate, the way macOS expects.
func renderIcon(size: Int, to url: URL) {
    let S = CGFloat(size)
    guard let ctx = newContext(size, size) else { return }
    let plate = CGRect(x: S*0.055, y: S*0.055, width: S*0.89, height: S*0.89)
    ctx.addPath(CGPath(roundedRect: plate, cornerWidth: S*0.205, cornerHeight: S*0.205, transform: nil))
    ctx.setFillColor(rgb(19, 17, 16).cgColor)
    ctx.fillPath()
    ctx.translateBy(x: 0, y: S); ctx.scaleBy(x: 1, y: -1)
    let m = S * 0.19
    drawFitted(chosen, in: CGRect(x: m, y: m, width: S - m*2, height: S - m*2), ctx: ctx)
    writePNG(ctx, url)
}

let iconset = out.appendingPathComponent("Claudme.iconset")
try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for (name, px) in [("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),
                   ("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),
                   ("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)] {
    renderIcon(size: px, to: iconset.appendingPathComponent("\(name).png"))
}

// transparent mark for the README and the page
if let ctx = newContext(512, 512) {
    ctx.translateBy(x: 0, y: 512); ctx.scaleBy(x: 1, y: -1)
    drawFitted(chosen, in: CGRect(x: 20, y: 20, width: 472, height: 472), ctx: ctx)
    writePNG(ctx, out.appendingPathComponent("logo.png"))
}

// Menubar image: the bare mark on transparency. The plated app icon looks like a
// black sticker up there, since every other menubar item is borderless.
if let ctx = newContext(72, 72) {
    ctx.translateBy(x: 0, y: 72); ctx.scaleBy(x: 1, y: -1)
    drawFitted(chosen, in: CGRect(x: 1, y: 1, width: 70, height: 70), ctx: ctx)
    writePNG(ctx, out.appendingPathComponent("menubar.png"))
}

// SVG, for crisp scaling on the page
do {
    let hw: CGFloat = 12, pad: CGFloat = 4
    let b = bounds(chosen, hw: hw)
    var s = #"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 "#
    s += "\(Int(b.width + pad*2)) \(Int(b.height + pad*2))\" role=\"img\" aria-label=\"Claudme\">"
    s += "<g shape-rendering=\"crispEdges\">"
    for f in faces(chosen, hw: hw, ox: pad - b.minX, oy: pad - b.minY) {
        let pts = f.pts.map { "\(String(format: "%.1f", $0.x)),\(String(format: "%.1f", $0.y))" }
                       .joined(separator: " ")
        let c = f.color.usingColorSpace(.sRGB)!
        s += String(format: "<polygon points=\"%@\" fill=\"#%02x%02x%02x\"/>", pts,
                    Int(c.redComponent*255), Int(c.greenComponent*255), Int(c.blueComponent*255))
    }
    s += "</g></svg>\n"
    try? s.write(to: out.appendingPathComponent("logo.svg"), atomically: true, encoding: .utf8)
    print("chosen \(chosen.name): \(faces(chosen, hw: hw, ox: 0, oy: 0).count) visible faces, svg \(s.count) bytes")
}

print("wrote \(variants.count) variants + variants.png to \(out.path)")
