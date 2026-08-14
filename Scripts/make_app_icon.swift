#!/usr/bin/env swift

import AppKit
import Foundation

let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let sourceURL = root.appending(path: "Assets/Generated/Preview/terrarium_shell.png")
guard let source = NSImage(contentsOf: sourceURL) else {
    fatalError("Could not read shell preview")
}

let size = 1024
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Could not allocate app icon")
}

NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not create drawing context")
}
NSGraphicsContext.current = context
let bounds = NSRect(x: 0, y: 0, width: size, height: size)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.03, green: 0.10, blue: 0.22, alpha: 1),
    NSColor(calibratedRed: 0.04, green: 0.28, blue: 0.21, alpha: 1),
])!
gradient.draw(in: bounds, angle: -65)

source.draw(
    in: NSRect(x: 75, y: 70, width: 874, height: 874),
    from: .zero,
    operation: .sourceOver,
    fraction: 1
)

let mossColors = [
    NSColor(calibratedRed: 0.12, green: 0.38, blue: 0.07, alpha: 1),
    NSColor(calibratedRed: 0.28, green: 0.58, blue: 0.08, alpha: 1),
    NSColor(calibratedRed: 0.48, green: 0.70, blue: 0.10, alpha: 1),
]
let mossMounds: [(Double, Double, Double, Double, Int)] = [
    (300, 260, 180, 100, 0),
    (405, 285, 195, 125, 1),
    (525, 270, 220, 135, 0),
    (650, 280, 190, 115, 2),
    (735, 250, 140, 88, 1),
]
for (xPosition, yPosition, width, height, tone) in mossMounds {
    mossColors[tone].setFill()
    NSBezierPath(ovalIn: NSRect(
        x: xPosition - width / 2,
        y: yPosition - height / 2,
        width: width,
        height: height
    )).fill()
}

let fernColor = NSColor(calibratedRed: 0.55, green: 0.82, blue: 0.12, alpha: 1)
fernColor.setStroke()
let stem = NSBezierPath()
stem.lineWidth = 13
stem.move(to: NSPoint(x: 512, y: 292))
stem.curve(
    to: NSPoint(x: 520, y: 590),
    controlPoint1: NSPoint(x: 500, y: 390),
    controlPoint2: NSPoint(x: 540, y: 495)
)
stem.stroke()
for index in 0..<7 {
    let yPosition = 340 + Double(index) * 36
    let leafLength = 104 - Double(index) * 10
    for direction in [-1.0, 1.0] {
        let leaf = NSBezierPath()
        leaf.lineWidth = 11
        leaf.move(to: NSPoint(x: 515, y: yPosition))
        leaf.line(to: NSPoint(
            x: 515 + direction * leafLength,
            y: yPosition + 24
        ))
        leaf.stroke()
    }
}

for (xPosition, yPosition, radius) in [
    (170.0, 820.0, 7.0),
    (810.0, 730.0, 5.0),
    (760.0, 220.0, 8.0),
    (225.0, 270.0, 4.0),
] {
    NSColor(calibratedRed: 0.78, green: 1, blue: 0.92, alpha: 0.85).setFill()
    NSBezierPath(ovalIn: NSRect(
        x: xPosition - radius,
        y: yPosition - radius,
        width: radius * 2,
        height: radius * 2
    )).fill()
}

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let data = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode app icon")
}
let output = root.appending(path: "App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
try data.write(to: output, options: .atomic)
print("Wrote \(output.path)")
