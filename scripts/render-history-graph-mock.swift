import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputURL = root.appendingPathComponent("screenshots/model-meter-history-graph-mock.png")
let scale: CGFloat = 2
let size = CGSize(width: 1200, height: 476)

let background = NSColor(calibratedRed: 0.105, green: 0.105, blue: 0.11, alpha: 1)
let grid = NSColor.secondaryLabelColor.withAlphaComponent(0.18)
let axis = NSColor.secondaryLabelColor.withAlphaComponent(0.62)
let text = NSColor.labelColor
let control = NSColor(calibratedRed: 0.20, green: 0.20, blue: 0.21, alpha: 1)
let blue = NSColor(calibratedRed: 0.02, green: 0.48, blue: 1.00, alpha: 1)
let green = NSColor(calibratedRed: 0.19, green: 0.86, blue: 0.38, alpha: 1)
let purple = NSColor(calibratedRed: 0.82, green: 0.20, blue: 0.92, alpha: 1)
let iconTint = NSColor.labelColor.withAlphaComponent(0.95)

let image = NSImage(size: size)
image.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high

background.setFill()
NSBezierPath(rect: CGRect(origin: .zero, size: size)).fill()

func topY(_ y: CGFloat, height: CGFloat) -> CGFloat {
    size.height - y - height
}

func drawText(_ value: String, x: CGFloat, top: CGFloat, font: NSFont, color: NSColor, width: CGFloat = 260, alignment: NSTextAlignment = .left) {
    let style = NSMutableParagraphStyle()
    style.alignment = alignment
    value.draw(
        in: CGRect(x: x, y: topY(top, height: font.pointSize + 8), width: width, height: font.pointSize + 8),
        withAttributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ]
    )
}

func drawRoundedRect(_ rect: CGRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func strokeLine(from: CGPoint, to: CGPoint, color: NSColor, width: CGFloat) {
    let path = NSBezierPath()
    path.lineWidth = width
    path.move(to: from)
    path.line(to: to)
    color.setStroke()
    path.stroke()
}

func fillCircle(center: CGPoint, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()
}

func strokeCircle(center: CGPoint, radius: CGFloat, color: NSColor, width: CGFloat) {
    let path = NSBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    path.lineWidth = width
    color.setStroke()
    path.stroke()
}

func drawTemplateImage(named name: String, at rect: CGRect) {
    guard let source = NSImage(contentsOf: root.appendingPathComponent("Assets/\(name).png")) else { return }
    let tinted = NSImage(size: rect.size)
    tinted.lockFocus()
    iconTint.setFill()
    CGRect(origin: .zero, size: rect.size).fill()
    source.draw(in: CGRect(origin: .zero, size: rect.size), from: .zero, operation: .destinationIn, fraction: 1)
    tinted.unlockFocus()
    tinted.draw(in: rect)
}

let titleFont = NSFont.systemFont(ofSize: 24, weight: .semibold)
let axisFont = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .medium)
let controlFont = NSFont.systemFont(ofSize: 27, weight: .semibold)

drawText("5-hour usage by hour", x: 44, top: 48, font: titleFont, color: text, width: 420)

let segmentedTop: CGFloat = 36
let segmentedRect = CGRect(x: size.width - 294, y: topY(segmentedTop, height: 58), width: 216, height: 58)
drawRoundedRect(segmentedRect, radius: 14, color: control)
drawRoundedRect(CGRect(x: segmentedRect.minX, y: segmentedRect.minY, width: 108, height: 58), radius: 14, color: blue)
drawText("24h", x: segmentedRect.minX, top: segmentedTop + 11, font: controlFont, color: .white, width: 108, alignment: .center)
drawText("7d", x: segmentedRect.minX + 108, top: segmentedTop + 11, font: controlFont, color: .white.withAlphaComponent(0.88), width: 108, alignment: .center)

let labelLeft: CGFloat = 44
let labelWidth: CGFloat = 76
let plotLeft = labelLeft + labelWidth
let plotRight = size.width - 78
let plotTop: CGFloat = 112
let plotBottom: CGFloat = 294
let plotHeight = plotBottom - plotTop
let plotWidth = plotRight - plotLeft

for (index, label) in ["100%", "75%", "50%", "25%", "0%"].enumerated() {
    let top = plotTop + (CGFloat(index) * plotHeight / 4) - 10
    drawText(label, x: labelLeft, top: top, font: axisFont, color: axis, width: labelWidth, alignment: .left)
    let y = size.height - (plotTop + CGFloat(index) * plotHeight / 4)
    strokeLine(from: CGPoint(x: plotLeft, y: y), to: CGPoint(x: plotRight, y: y), color: grid, width: 0.7)
}

func point(hourOffset: CGFloat, used: CGFloat) -> CGPoint {
    let x = plotLeft + plotWidth * hourOffset / 24
    let y = size.height - (plotBottom - (plotHeight * used / 100))
    return CGPoint(x: x, y: y)
}

func drawSeries(_ points: [CGPoint], color: NSColor) {
    guard let first = points.first else { return }
    let path = NSBezierPath()
    path.lineWidth = 2.2
    path.move(to: first)
    for point in points.dropFirst() {
        path.line(to: point)
    }
    color.setStroke()
    path.stroke()

    for p in points {
        fillCircle(center: p, radius: 2.4, color: color)
        strokeCircle(center: p, radius: 3.2, color: background, width: 0.75)
    }
}

drawSeries([
    point(hourOffset: 0.5, used: 18),
    point(hourOffset: 2.0, used: 22),
    point(hourOffset: 3.5, used: 20),
    point(hourOffset: 5.0, used: 32),
    point(hourOffset: 6.5, used: 36),
    point(hourOffset: 8.0, used: 44),
    point(hourOffset: 9.5, used: 41),
    point(hourOffset: 11.0, used: 52),
    point(hourOffset: 12.5, used: 57),
    point(hourOffset: 14.0, used: 63),
    point(hourOffset: 15.5, used: 68),
    point(hourOffset: 17.0, used: 74),
    point(hourOffset: 18.5, used: 70),
    point(hourOffset: 20.0, used: 61),
    point(hourOffset: 21.5, used: 54),
    point(hourOffset: 23.5, used: 42)
], color: green)

drawSeries([
    point(hourOffset: 0.5, used: 3),
    point(hourOffset: 2.0, used: 5),
    point(hourOffset: 3.5, used: 4),
    point(hourOffset: 5.0, used: 8),
    point(hourOffset: 6.5, used: 9),
    point(hourOffset: 8.0, used: 7),
    point(hourOffset: 9.5, used: 13),
    point(hourOffset: 11.0, used: 15),
    point(hourOffset: 12.5, used: 14),
    point(hourOffset: 14.0, used: 18),
    point(hourOffset: 15.5, used: 22),
    point(hourOffset: 17.0, used: 25),
    point(hourOffset: 18.5, used: 21),
    point(hourOffset: 20.0, used: 19),
    point(hourOffset: 21.5, used: 17),
    point(hourOffset: 23.5, used: 14)
], color: purple)

drawSeries([
    point(hourOffset: 0.5, used: 0),
    point(hourOffset: 2.0, used: 1),
    point(hourOffset: 3.5, used: 1),
    point(hourOffset: 5.0, used: 2),
    point(hourOffset: 6.5, used: 2),
    point(hourOffset: 8.0, used: 3),
    point(hourOffset: 9.5, used: 2),
    point(hourOffset: 11.0, used: 3),
    point(hourOffset: 12.5, used: 4),
    point(hourOffset: 14.0, used: 4),
    point(hourOffset: 15.5, used: 5),
    point(hourOffset: 17.0, used: 4),
    point(hourOffset: 18.5, used: 3),
    point(hourOffset: 20.0, used: 2),
    point(hourOffset: 21.5, used: 2),
    point(hourOffset: 23.5, used: 1)
], color: blue)

drawText("8 PM", x: plotLeft - 24, top: plotBottom + 9, font: axisFont, color: axis, width: 84, alignment: .center)
drawText("8 AM", x: plotLeft + (plotWidth / 2) - 42, top: plotBottom + 9, font: axisFont, color: axis, width: 84, alignment: .center)
drawText("8 PM", x: plotRight - 42, top: plotBottom + 9, font: axisFont, color: axis, width: 84, alignment: .center)

let legendY = topY(plotBottom + 56, height: 28)
let legendIconSize: CGFloat = 28
let legendDotRadius: CGFloat = 8
var legendX = labelLeft
let legendItems: [(String, NSColor)] = [
    ("ChatGPT-Logo", green),
    ("claude-transparent-custom", purple),
    ("google-gemini-logomark-black-24439_32", blue)
]

for (name, color) in legendItems {
    drawTemplateImage(named: name, at: CGRect(x: legendX, y: legendY, width: legendIconSize, height: legendIconSize))
    fillCircle(center: CGPoint(x: legendX + legendIconSize + 21, y: legendY + legendIconSize / 2), radius: legendDotRadius, color: color)
    legendX += 108
}

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let png = rep.representation(using: .png, properties: [:])
else {
    fatalError("Unable to render PNG")
}

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: outputURL)
print(outputURL.path)
