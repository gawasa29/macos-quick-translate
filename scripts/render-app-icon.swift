#!/usr/bin/env swift

import AppKit
import Foundation

private enum TailDirection {
    case left
    case right
}

private func speechBubblePath(in rect: NSRect, tail: TailDirection) -> NSBezierPath {
    let path = NSBezierPath(roundedRect: rect, xRadius: 56, yRadius: 56)
    let baseY = rect.minY + 18

    switch tail {
    case .left:
        path.move(to: NSPoint(x: rect.minX + 82, y: baseY))
        path.line(to: NSPoint(x: rect.minX + 42, y: rect.minY - 50))
        path.line(to: NSPoint(x: rect.minX + 130, y: baseY + 8))
        path.close()
    case .right:
        path.move(to: NSPoint(x: rect.maxX - 82, y: baseY))
        path.line(to: NSPoint(x: rect.maxX - 42, y: rect.minY - 50))
        path.line(to: NSPoint(x: rect.maxX - 130, y: baseY + 8))
        path.close()
    }

    return path
}

private func drawArrow(
    from start: NSPoint,
    to end: NSPoint,
    color: NSColor,
    lineWidth: CGFloat
) {
    color.setStroke()

    let body = NSBezierPath()
    body.lineWidth = lineWidth
    body.lineCapStyle = .round
    body.move(to: start)
    body.line(to: end)
    body.stroke()

    let angle = atan2(end.y - start.y, end.x - start.x)
    let arrowLength: CGFloat = 24
    let spread: CGFloat = 0.62

    let headA = NSPoint(
        x: end.x - arrowLength * cos(angle - spread),
        y: end.y - arrowLength * sin(angle - spread)
    )
    let headB = NSPoint(
        x: end.x - arrowLength * cos(angle + spread),
        y: end.y - arrowLength * sin(angle + spread)
    )

    let head = NSBezierPath()
    head.lineWidth = lineWidth
    head.lineCapStyle = .round
    head.move(to: end)
    head.line(to: headA)
    head.move(to: end)
    head.line(to: headB)
    head.stroke()
}

private func drawCenteredLabel(_ text: String, in rect: NSRect) {
    let style = NSMutableParagraphStyle()
    style.alignment = .center

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 116, weight: .black),
        .foregroundColor: NSColor.white,
        .paragraphStyle: style
    ]
    let attributed = NSAttributedString(string: text, attributes: attributes)
    let textSize = attributed.size()

    let textRect = NSRect(
        x: rect.minX,
        y: rect.midY - textSize.height / 2 + 6,
        width: rect.width,
        height: textSize.height
    )
    attributed.draw(in: textRect)
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("Usage: render-app-icon.swift <output-png>\n".utf8))
    exit(1)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let iconSize: CGFloat = 1024
let canvas = NSRect(x: 0, y: 0, width: iconSize, height: iconSize)

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(iconSize),
    pixelsHigh: Int(iconSize),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bitmapFormat: [],
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    FileHandle.standardError.write(Data("Failed to allocate bitmap image\n".utf8))
    exit(1)
}

guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    FileHandle.standardError.write(Data("Failed to create graphics context\n".utf8))
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
defer { NSGraphicsContext.restoreGraphicsState() }

NSColor.clear.setFill()
canvas.fill()

let outerRect = canvas.insetBy(dx: 54, dy: 54)
let outerPath = NSBezierPath(roundedRect: outerRect, xRadius: 192, yRadius: 192)
NSColor(calibratedWhite: 0.99, alpha: 1.0).setFill()
outerPath.fill()

let innerRect = outerRect.insetBy(dx: 28, dy: 28)
let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: 168, yRadius: 168)
let gradient = NSGradient(
    colors: [
        NSColor(calibratedRed: 0.17, green: 0.53, blue: 0.95, alpha: 1.0),
        NSColor(calibratedRed: 0.08, green: 0.74, blue: 0.59, alpha: 1.0)
    ]
)!
gradient.draw(in: innerPath, angle: -28)

let bridgeRect = NSRect(x: 448, y: 416, width: 128, height: 194)
let bridgePath = NSBezierPath(roundedRect: bridgeRect, xRadius: 46, yRadius: 46)
NSColor(calibratedWhite: 1.0, alpha: 0.2).setFill()
bridgePath.fill()

let leftBubbleRect = NSRect(x: 118, y: 390, width: 348, height: 256)
let rightBubbleRect = NSRect(x: 558, y: 390, width: 348, height: 256)

let leftBubble = speechBubblePath(in: leftBubbleRect, tail: .left)
NSColor(calibratedRed: 0.08, green: 0.35, blue: 0.84, alpha: 0.96).setFill()
leftBubble.fill()

let rightBubble = speechBubblePath(in: rightBubbleRect, tail: .right)
NSColor(calibratedRed: 0.0, green: 0.62, blue: 0.46, alpha: 0.96).setFill()
rightBubble.fill()

drawCenteredLabel("EN", in: leftBubbleRect)
drawCenteredLabel("JA", in: rightBubbleRect)

let arrowColor = NSColor(calibratedWhite: 1.0, alpha: 0.96)
drawArrow(
    from: NSPoint(x: leftBubbleRect.maxX + 20, y: leftBubbleRect.midY + 38),
    to: NSPoint(x: rightBubbleRect.minX - 20, y: rightBubbleRect.midY + 38),
    color: arrowColor,
    lineWidth: 16
)
drawArrow(
    from: NSPoint(x: rightBubbleRect.minX - 20, y: rightBubbleRect.midY - 38),
    to: NSPoint(x: leftBubbleRect.maxX + 20, y: leftBubbleRect.midY - 38),
    color: arrowColor,
    lineWidth: 16
)

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("Failed to render icon image\n".utf8))
    exit(1)
}

do {
    try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try png.write(to: outputURL)
} catch {
    FileHandle.standardError.write(Data("Failed to write PNG: \(error)\n".utf8))
    exit(1)
}
