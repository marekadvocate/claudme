import AppKit

/// Renders a crab as isometric voxels — the same look as the app icon.
///
/// The flat 11×6 pixel grid is extruded to a few voxels of depth and projected 2:1,
/// with three flat shades per cube giving the volume. Output is a single CGImage that
/// a pet can drop straight into a layer's `contents`, so 3D mode costs one layer
/// instead of a dozen and every existing animation keeps working untouched.
enum VoxelSprite {

    static let depth = 3          // how thick the crab is, in voxels

    private struct Group {
        let cells: [(Int, Int)]   // (col, row) in the flat grid
        let color: NSColor
    }

    /// Three shades from one base — top face lit, then the two side faces.
    private static func shades(_ c: NSColor) -> (NSColor, NSColor, NSColor) {
        let s = c.usingColorSpace(.sRGB) ?? c
        func mul(_ f: CGFloat) -> NSColor {
            NSColor(srgbRed: min(1, s.redComponent * f),
                    green: min(1, s.greenComponent * f),
                    blue: min(1, s.blueComponent * f),
                    alpha: s.alphaComponent)
        }
        return (mul(1.18), mul(0.80), mul(0.60))
    }

    /// Cached because the sprite only changes on a leg flip or a state change, but the
    /// same handful of variants recur constantly across every crab on screen.
    private static var cache: [String: CGImage] = [:]

    static func image(bodyColor: NSColor,
                      capColor: NSColor,
                      era: Era,
                      legPhase: Int,
                      sleeping: Bool,
                      pixel: CGFloat) -> CGImage? {
        let key = "\(bodyColor.hexish)|\(capColor.hexish)|\(era.rawValue)|\(legPhase)|\(sleeping)|\(pixel)"
        if let hit = cache[key] { return hit }

        let groups = [
            Group(cells: PetView.shellCellsPublic, color: bodyColor),
            Group(cells: legPhase == 0 ? PetView.legCellsAPublic : PetView.legCellsBPublic,
                  color: bodyColor),
            Group(cells: PetView.accentCells(for: era),
                  color: NSColor(white: 1, alpha: 0.30).blended(withFraction: 0.7, of: bodyColor) ?? bodyColor),
            Group(cells: PetView.hatCells(for: era), color: capColor),
            Group(cells: sleeping ? [] : [(2, 3), (8, 3)], color: PetView.inkColor),
        ]

        // occupancy over every group, so faces buried between parts are dropped too
        var filled = Set<Int>()
        let key3 = { (x: Int, y: Int, z: Int) in (x + 32) << 20 | (y + 32) << 10 | (z + 32) }
        for g in groups {
            for (col, row) in g.cells {
                for y in 0..<depth { filled.insert(key3(col, y, -row)) }
            }
        }

        let hw = pixel, hh = pixel / 2, hz = pixel
        var faces: [(pts: [CGPoint], color: NSColor)] = []
        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity

        for g in groups {
            let (top, left, right) = shades(g.color)
            for (col, row) in g.cells {
                for y in 0..<depth {
                    let x = col, z = -row
                    let sx = CGFloat(x - y) * hw
                    let sy = CGFloat(x + y) * hh - CGFloat(z) * hz
                    func push(_ pts: [CGPoint], _ c: NSColor) {
                        faces.append((pts, c))
                        for p in pts {
                            minX = min(minX, p.x); maxX = max(maxX, p.x)
                            minY = min(minY, p.y); maxY = max(maxY, p.y)
                        }
                    }
                    if !filled.contains(key3(x, y, z + 1)) {
                        push([CGPoint(x: sx, y: sy - hh), CGPoint(x: sx + hw, y: sy),
                              CGPoint(x: sx, y: sy + hh), CGPoint(x: sx - hw, y: sy)], top)
                    }
                    if !filled.contains(key3(x, y + 1, z)) {
                        push([CGPoint(x: sx - hw, y: sy), CGPoint(x: sx, y: sy + hh),
                              CGPoint(x: sx, y: sy + hh + hz), CGPoint(x: sx - hw, y: sy + hz)], left)
                    }
                    if !filled.contains(key3(x + 1, y, z)) {
                        push([CGPoint(x: sx + hw, y: sy), CGPoint(x: sx, y: sy + hh),
                              CGPoint(x: sx, y: sy + hh + hz), CGPoint(x: sx + hw, y: sy + hz)], right)
                    }
                }
            }
        }
        guard !faces.isEmpty, minX < maxX else { return nil }

        // painter's order: farthest voxel first. Sorting the faces themselves keeps
        // groups from occluding each other in the wrong order.
        faces.sort { a, b in
            let ka = a.pts.map { $0.y }.max()! + a.pts.map { $0.x }.min()! * 0.001
            let kb = b.pts.map { $0.y }.max()! + b.pts.map { $0.x }.min()! * 0.001
            return ka < kb
        }

        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let w = Int(ceil((maxX - minX) * scale)) + 2
        let h = Int(ceil((maxY - minY) * scale)) + 2
        guard w > 0, h > 0, w < 4000, h < 4000,
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }

        ctx.scaleBy(x: scale, y: scale)
        ctx.translateBy(x: 0, y: (maxY - minY))
        ctx.scaleBy(x: 1, y: -1)              // projection is y-down, CG is y-up
        ctx.translateBy(x: -minX, y: -minY)

        for f in faces {
            ctx.beginPath()
            ctx.move(to: f.pts[0])
            for p in f.pts.dropFirst() { ctx.addLine(to: p) }
            ctx.closePath()
            ctx.setFillColor(f.color.cgColor)
            ctx.fillPath()
        }

        let img = ctx.makeImage()
        if let img, cache.count < 400 { cache[key] = img }
        return img
    }
}

// MARK: - Dance mode: one image per grid cell, so the cubes can move independently

extension VoxelSprite {

    /// Where a cell's voxel column lands on screen, before centring.
    static func isoPoint(col: Int, row: Int, pixel: CGFloat) -> CGPoint {
        let hw = pixel, hh = pixel / 2, hz = pixel
        let y = depth - 1                       // anchor on the front-most voxel
        return CGPoint(x: CGFloat(col - y) * hw,
                       y: CGFloat(col + y) * hh + CGFloat(row) * hz)
    }

    private static var columnCache: [String: CGImage] = [:]

    /// A single voxel column — the same picture for every cell of a given colour, so
    /// a whole shattered crab costs only a handful of distinct images.
    static func columnImage(color: NSColor, pixel: CGFloat) -> CGImage? {
        let key = "\(color.hexish)|\(pixel)"
        if let hit = columnCache[key] { return hit }

        let hw = pixel, hh = pixel / 2, hz = pixel
        let (top, left, right) = shadesPublic(color)
        var faces: [(pts: [CGPoint], color: NSColor)] = []
        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity

        for y in 0..<depth {
            let sx = CGFloat(-y) * hw, sy = CGFloat(y) * hh
            func push(_ pts: [CGPoint], _ c: NSColor) {
                faces.append((pts, c))
                for p in pts {
                    minX = min(minX, p.x); maxX = max(maxX, p.x)
                    minY = min(minY, p.y); maxY = max(maxY, p.y)
                }
            }
            push([CGPoint(x: sx, y: sy - hh), CGPoint(x: sx + hw, y: sy),
                  CGPoint(x: sx, y: sy + hh), CGPoint(x: sx - hw, y: sy)], top)
            if y == depth - 1 {   // only the front column shows its side faces
                push([CGPoint(x: sx - hw, y: sy), CGPoint(x: sx, y: sy + hh),
                      CGPoint(x: sx, y: sy + hh + hz), CGPoint(x: sx - hw, y: sy + hz)], left)
                push([CGPoint(x: sx + hw, y: sy), CGPoint(x: sx, y: sy + hh),
                      CGPoint(x: sx, y: sy + hh + hz), CGPoint(x: sx + hw, y: sy + hz)], right)
            }
        }
        faces.sort { $0.pts.map(\.y).max()! < $1.pts.map(\.y).max()! }

        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let w = Int(ceil((maxX - minX) * scale)) + 2
        let h = Int(ceil((maxY - minY) * scale)) + 2
        guard w > 0, h > 0,
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.scaleBy(x: scale, y: scale)
        ctx.translateBy(x: 0, y: maxY - minY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.translateBy(x: -minX, y: -minY)
        for f in faces {
            ctx.beginPath()
            ctx.move(to: f.pts[0])
            for p in f.pts.dropFirst() { ctx.addLine(to: p) }
            ctx.closePath()
            ctx.setFillColor(f.color.cgColor)
            ctx.fillPath()
        }
        let img = ctx.makeImage()
        if let img, columnCache.count < 64 { columnCache[key] = img }
        return img
    }

    static func shadesPublic(_ c: NSColor) -> (NSColor, NSColor, NSColor) { shades(c) }
}

private extension NSColor {
    /// cheap stable key for the sprite cache
    var hexish: String {
        let c = usingColorSpace(.sRGB) ?? self
        return String(format: "%02x%02x%02x%02x",
                      Int(c.redComponent * 255), Int(c.greenComponent * 255),
                      Int(c.blueComponent * 255), Int(c.alphaComponent * 255))
    }
}
