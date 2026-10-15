import AppKit
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
NSColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
NSColor(red: 0.49, green: 0.19, blue: 0.31, alpha: 1).setFill()
for i in 0..<5 {
    NSGraphicsContext.saveGraphicsState()
    let t = NSAffineTransform(); t.translateX(by: 512, yBy: 535)
    t.concat()
    let r = NSAffineTransform(); r.rotate(byDegrees: CGFloat(i) * 72); r.concat()
    NSBezierPath(ovalIn: NSRect(x: -115, y: 0, width: 230, height: 270)).fill()
    NSGraphicsContext.restoreGraphicsState()
}
NSColor(red: 0.88, green: 0.69, blue: 0.50, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 444, y: 467, width: 136, height: 136)).fill()
NSColor(red: 0.29, green: 0.44, blue: 0.37, alpha: 1).setStroke()
let stem = NSBezierPath(); stem.lineWidth = 22; stem.lineCapStyle = .round
stem.move(to: NSPoint(x: 512, y: 310)); stem.curve(to: NSPoint(x: 512,y: 195), controlPoint1: NSPoint(x: 480,y: 260), controlPoint2: NSPoint(x: 490,y: 220)); stem.stroke()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
