import AppKit
import CoreGraphics

let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("Unable to create icon context") }

context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

// Asset catalogs apply the platform mask. Keeping the artwork edge-to-edge
// avoids a second, mismatched rounded mask around the icon.
let canvas = CGRect(x: 0, y: 0, width: 1024, height: 1024)
let background = CGPath(rect: canvas, transform: nil)

let backgroundColors = [
    CGColor(red: 0.055, green: 0.075, blue: 0.16, alpha: 1),
    CGColor(red: 0.12, green: 0.16, blue: 0.34, alpha: 1)
] as CFArray
let backgroundLocations: [CGFloat] = [0, 1]
let backgroundGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: backgroundColors,
    locations: backgroundLocations
)!

context.saveGState()
context.addPath(background)
context.clip()
context.drawLinearGradient(
    backgroundGradient,
    start: CGPoint(x: 160, y: 160),
    end: CGPoint(x: 880, y: 880),
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)

// A quiet highlight gives the mark depth without turning it glossy.
let glowColors = [
    CGColor(red: 0.30, green: 0.36, blue: 0.76, alpha: 0.24),
    CGColor(red: 0.30, green: 0.36, blue: 0.76, alpha: 0)
] as CFArray
let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0, 1])!
context.drawRadialGradient(
    glow,
    startCenter: CGPoint(x: 512, y: 512), startRadius: 0,
    endCenter: CGPoint(x: 512, y: 512), endRadius: 520,
    options: []
)
context.restoreGState()

func drawRoute(from start: CGPoint, through center: CGPoint, to end: CGPoint, color: CGColor) {
    context.saveGState()
    context.setStrokeColor(color)
    context.setLineWidth(108)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    let path = CGMutablePath()
    path.move(to: start)
    path.addCurve(
        to: center,
        control1: CGPoint(x: 365, y: start.y),
        control2: CGPoint(x: 405, y: center.y)
    )
    path.addCurve(
        to: end,
        control1: CGPoint(x: 620, y: center.y),
        control2: CGPoint(x: 665, y: end.y)
    )
    context.addPath(path)
    context.strokePath()
    context.restoreGState()
}

// Two routes exchange places: battery and AC converge at one mode switch.
drawRoute(
    from: CGPoint(x: 220, y: 300), through: CGPoint(x: 512, y: 512), to: CGPoint(x: 804, y: 730),
    color: CGColor(red: 1.0, green: 0.40, blue: 0.36, alpha: 1)
)
drawRoute(
    from: CGPoint(x: 220, y: 730), through: CGPoint(x: 512, y: 512), to: CGPoint(x: 804, y: 300),
    color: CGColor(red: 0.28, green: 0.86, blue: 0.80, alpha: 1)
)

// A compact switch hub separates the crossing at Dock and Spotlight sizes.
context.setFillColor(CGColor(red: 0.075, green: 0.095, blue: 0.20, alpha: 1))
context.fillEllipse(in: CGRect(x: 433, y: 433, width: 158, height: 158))
context.setFillColor(CGColor(gray: 1, alpha: 0.96))
context.fillEllipse(in: CGRect(x: 482, y: 482, width: 60, height: 60))

guard let image = context.makeImage() else { fatalError("Unable to render icon") }
let representation = NSBitmapImageRep(cgImage: image)
guard let png = representation.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode icon")
}

let output = CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.png"
try png.write(to: URL(fileURLWithPath: output))
