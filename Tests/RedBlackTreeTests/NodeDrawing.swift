/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: NodeDrawing.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 09, 2021
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
@testable import RedBlackTree

let leftAngle:  CGFloat = 135
let rightAngle: CGFloat = 45
let theta:      CGFloat = (CGFloat.pi / 180)

extension TreeNode where T == RedBlackTreeDictionary<String, NodeTestValue>.KV {

    @inlinable var colorIndex: Int { ((color == .Red) ? 1 : 0) }

    func drawTree(filename: String) throws {
        let url = URL(fileURLWithPath: filename, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true))
        try drawTree(url: url)
    }

    func drawTree(url: URL) throws {
        let r     = rootNode
        let size  = r.calcSize()
        let cSize = size.expand(width: 10, height: labelHeight + 10)
        r.calcPosition(origin: NSPoint(x: (cSize.width - size.width) / 2, y: cSize.height - ((cSize.height - size.height) / 2)))

        let img = NSImage(size: cSize, flipped: false) { b in
            bgColor.setFill()
            NSBezierPath(rect: b).fill()
            r.drawNode()
            return true
        }
        try saveImageAsPNG(img: img, url: url)
    }

    private func drawLine(to child: TreeNode<T>) {
        let angle:         CGFloat      = (theta * child.forSide(parent: self, ifLeft: leftAngle, ifRight: rightAngle))
        let parentLoc:     NSPoint      = value.value.bounds.origin
        let childLoc:      NSPoint      = child.value.value.bounds.origin
        let startPoint:    NSPoint      = NSPoint(x: parentLoc.x + (nodeRadius * cos(angle)), y: parentLoc.y - (nodeRadius * sin(angle)))
        let endPoint:      NSPoint      = NSPoint(x: childLoc.x, y: childLoc.y + nodeRadius)
        let controlPoint1: NSPoint      = NSPoint(x: startPoint.x, y: halfway(p1: startPoint.y, p2: endPoint.y))
        let controlPoint2: NSPoint      = NSPoint(x: endPoint.x, y: halfway(p1: startPoint.y, p2: endPoint.y))
        let labelLoc:      NSPoint      = calcBezierPoint(t: 0.5, p1: startPoint, p2: controlPoint1, p3: controlPoint2, p4: endPoint)
        let path:          NSBezierPath = NSBezierPath()

        path.move(to: startPoint)
        path.curve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        lineColor.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
        child.drawNode()
        drawLabel(at: labelLoc, text: String(child.count), color: NSColor.yellow, drawBox: true)
    }

    private func drawNode() {
        let colors = nodeColors[colorIndex]
        let x      = value.value.bounds.minX
        let y      = value.value.bounds.minY
        let ly     = (y - nodeRadius - (labelHeight / 2))

        if let child = leftNode { drawLine(to: child) }
        if let child = rightNode { drawLine(to: child) }
        drawOval(centeredAt: value.value.bounds.origin, size: NSSize(width: nodeDiameter, height: nodeDiameter), lineWidth: lineWidth, lineColor: colors[1], fillColor: colors[0])
        drawLabel(at: NSPoint(x: x, y: y), text: value.key, font: nodeFont, color: NSColor.white)
        drawLabel(at: NSPoint(x: x, y: ly), text: String(index.idx), color: NSColor.blue)
        if parentNode == nil { drawLabel(at: NSPoint(x: x, y: ly - labelHeight), text: String(count), color: NSColor.yellow) }
    }

    private func calcSize() -> NSSize {
        let lSz = (leftNode?.calcSize() ?? NSSize.zero)
        let rSz = (rightNode?.calcSize() ?? NSSize.zero)
        value.value.bounds.size.width = (max(lSz.width, (nodeRadius + lineWidth)) + max(rSz.width, (nodeRadius + lineWidth)))
        value.value.bounds.size.height = (deltaY + max(lSz.height, rSz.height))
        return value.value.bounds.size
    }

    private func calcPosition(origin: NSPoint) {
        let nextY = (origin.y - deltaY)
        value.value.bounds.origin.x = (origin.x + (leftNode?.value.value.bounds.width ?? (nodeRadius + lineWidth)))
        value.value.bounds.origin.y = (origin.y - (nodeRadius + lineWidth))
        leftNode?.calcPosition(origin: NSPoint(x: origin.x, y: nextY))
        rightNode?.calcPosition(origin: NSPoint(x: value.value.bounds.minX, y: nextY))
    }
}
