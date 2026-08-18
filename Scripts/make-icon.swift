#!/usr/bin/env swift
// Renders Assets/AppIcon.icns: a beige rounded square with a midnight-black
// clipboard glyph, drawn with CoreGraphics at every iconset size, then packed
// with iconutil. Run once from anywhere: swift Scripts/make-icon.swift

import AppKit
import UniformTypeIdentifiers

let beige = CGColor(srgbRed: 0xF2 / 255, green: 0xEA / 255, blue: 0xD9 / 255, alpha: 1)
let midnight = CGColor(srgbRed: 0x14 / 255, green: 0x14 / 255, blue: 0x1A / 255, alpha: 1)

func rounded(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> CGPath {
    CGPath(
        roundedRect: CGRect(x: x, y: y, width: w, height: h),
        cornerWidth: r, cornerHeight: r, transform: nil)
}

// All coordinates in 1024-point space, origin bottom-left.
func draw(in ctx: CGContext) {
    // Beige rounded-square background with the standard ~10% margin.
    ctx.setFillColor(beige)
    ctx.addPath(rounded(100, 100, 824, 824, 185))
    ctx.fillPath()

    // Clipboard board.
    ctx.setFillColor(midnight)
    ctx.addPath(rounded(312, 252, 400, 520, 48))
    ctx.fillPath()

    // Paper inset.
    ctx.setFillColor(beige)
    ctx.addPath(rounded(352, 292, 320, 400, 24))
    ctx.fillPath()

    // Clip tab overlapping the top edge.
    ctx.setFillColor(midnight)
    ctx.addPath(rounded(422, 732, 180, 90, 28))
    ctx.fillPath()

    // Text lines on the paper.
    for y: CGFloat in [560, 480, 400] {
        ctx.addPath(rounded(402, y, 220, 28, 14))
    }
    ctx.fillPath()
}

func renderPNG(size: Int, to url: URL) {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard
        let ctx = CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { fatalError("could not create CGContext for size \(size)") }
    let scale = CGFloat(size) / 1024
    ctx.scaleBy(x: scale, y: scale)
    draw(in: ctx)
    guard let image = ctx.makeImage(),
        let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { fatalError("could not write \(url.path)") }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let assets = root.appendingPathComponent("Assets")
let iconset = assets.appendingPathComponent("AppIcon.iconset")
let fm = FileManager.default
try? fm.removeItem(at: iconset)
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)

let entries: [(name: String, size: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for entry in entries {
    renderPNG(size: entry.size, to: iconset.appendingPathComponent("\(entry.name).png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = [
    "-c", "icns", iconset.path, "-o", assets.appendingPathComponent("AppIcon.icns").path,
]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { fatalError("iconutil failed") }
try? fm.removeItem(at: iconset)
print("Wrote \(assets.appendingPathComponent("AppIcon.icns").path)")
