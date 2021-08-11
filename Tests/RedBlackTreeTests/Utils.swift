/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: Utils.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 11, 2021
 *
  * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided
 * that the above copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
 * NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//*****************************************************************************************************************************/

import Foundation
import CoreFoundation
import Cocoa

//@f:0
@usableFromInline typealias FontAttrDict = [NSAttributedString.Key: Any]

@usableFromInline let fontStyle:      NSMutableParagraphStyle = { let s = NSMutableParagraphStyle(); s.alignment = .center; return s }()
@usableFromInline let nodeFont:       NSFont                  = NSFont(name: "TimesNewRomanPSMT", size: 87)!
@usableFromInline let labelFont:      NSFont                  = NSFont(name: "TimesNewRomanPS-BoldMT", size: 26)!
@usableFromInline let bgColor:        NSColor                 = NSColor(red: 0.788, green: 0.788, blue: 0.788, alpha: 1)
@usableFromInline let lineColor:      NSColor                 = NSColor.blue
@usableFromInline let nodeColors:     [[NSColor]]             = [ [ NSColor.black, NSColor.white ], [ NSColor.red, NSColor.black ] ]
@usableFromInline let lineWidth:      CGFloat                 = 2
@usableFromInline let nodeDiameter:   CGFloat                 = 125
@usableFromInline let nodeRadius:     CGFloat                 = (nodeDiameter / 2)
@usableFromInline let labelHeight:    CGFloat                 = (labelFont.pointSize * 1.1)
@usableFromInline let deltaY:         CGFloat                 = (nodeDiameter + (lineWidth * 2) + (labelHeight * 1.25))
//@f:1

func saveImageAsPNG(img: NSImage, url: URL) throws {
    let imageRep = NSBitmapImageRep(data: img.tiffRepresentation!)
    let pngData  = imageRep?.representation(using: .png, properties: [:])
    try pngData?.write(to: url)
}

@inlinable func halfway(p1: CGFloat, p2: CGFloat) -> CGFloat { ((p1 == p2) ? p1 : ((p1 < p2) ? (p1 + ((p2 - p1) / 2)) : (p2 + ((p1 - p2) / 2)))) }

@inlinable func calcBezierPoint(t: CGFloat, p1: NSPoint, p2: NSPoint, p3: NSPoint, p4: NSPoint) -> NSPoint {
    func c(_ t: CGFloat, _ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
        let t2 = (1 - t)
        let r1 = (pow(t2, 3) * a)
        let r2 = (pow(t2, 2) * 3 * t * b)
        let r3 = (pow(t, 2) * 3 * t2 * c)
        let r4 = (pow(t, 3) * d)

        return (r1 + r2 + r3 + r4)
    }

    return NSPoint(x: c(t, p1.x, p2.x, p3.x, p4.x), y: c(t, p1.y, p2.y, p3.y, p4.y))
}

@inlinable func drawLabel(at p: NSPoint, text str: String, color: NSColor, drawBox: Bool = false) { drawLabel(at: p, text: str, font: labelFont, color: color, drawBox: drawBox) }

@usableFromInline func drawLabel(at p: NSPoint, text str: String, font: NSFont, color: NSColor, drawBox: Bool = false) {
    NSGraphicsContext.saveGraphicsState()

    let attrs: FontAttrDict = [ .font: font, .foregroundColor: color, .paragraphStyle: fontStyle ]
    let text:  NSString     = str as NSString
    let r1:    NSRect       = NSRect(x: (p.x - nodeRadius), y: (p.y - (labelHeight / 2)), width: nodeDiameter, height: labelHeight)
    let r2:    NSRect       = text.boundingRect(with: r1.size, options: .usesLineFragmentOrigin, attributes: attrs)
    let r3:    NSRect       = NSRect(x: (r1.minX + ((r1.width - r2.width) / 2)), y: (r1.minY + ((r1.height - r2.height) / 2)), width: r2.width, height: r2.height)

    if drawBox { drawRect(centeredAt: p, size: r2.size.expand(width: 5, height: 5), fillColor: bgColor) }
    text.draw(in: r3.offsetBy(dx: 0, dy: 0.5), withAttributes: attrs)
    r3.clip()

    NSGraphicsContext.restoreGraphicsState()
}

@inlinable func drawRect(centeredAt p: NSPoint, size: NSSize, lineColor: NSColor? = nil, fillColor: NSColor? = nil) {
    let path = NSBezierPath(rect: NSRect(x: p.x - size.width / 2, y: p.y - size.height / 2, width: size.width, height: size.height))

    if let c = fillColor {
        c.setFill()
        path.fill()
    }
    if let c = lineColor {
        c.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

@inlinable func drawOval(centeredAt p: NSPoint, size: NSSize, lineWidth lw: CGFloat? = nil, lineColor: NSColor? = nil, fillColor: NSColor? = nil) {
    let path = NSBezierPath(ovalIn: NSRect(x: (p.x - (size.width / 2)), y: (p.y - (size.height / 2)), width: size.width, height: size.height))

    if let c = fillColor {
        c.setFill()
        path.fill()
    }
    if let c = lineColor {
        path.lineWidth = (lw ?? lineWidth)
        c.setStroke()
        path.stroke()
    }
}
