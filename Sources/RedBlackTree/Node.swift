/*===============================================================================================================================================================================*
 *     PROJECT: RedBlackTree
 *    FILENAME: Node.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/22/21
 *
 * Copyright © 2021. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation

let colorBit:  UInt = (1 << (UInt.bitWidth - 1))
let countBits: UInt = ~(colorBit)

class Node<T>: Hashable where T: Hashable & Comparable {

    enum Color { case Black, Red }

    enum Side: Int { case Left = 0, Right = 1 }

    private(set) var item: T

    init(item: T, color: Color = .Black) {
        self.item = item
        self.color = color
        self.count = 1
    }

    subscript(i: T) -> Node<T>? { ((i == item) ? self : self[i < item ? .Left : .Right]?[i]) }

    func insert(item i: T) -> Node<T> {
        guard i == item else { return insert(item: i, side: ((i < item) ? Side.Left : Side.Right)) }
        item = i
        return root
    }

    func remove() -> Node<T>? {
        if let l = leftNode, let r = rightNode {
            let n = (Bool.random() ? l.farRightNode : r.farLeftNode)
            swap(&item, &n.item)
            return n.remove()
        }
        else if let c = (leftNode ?? rightNode) {
            c.paintBlack()
            swapWith(node: c)
            return c.root
        }
        else if let p = parentNode {
            if Color.isBlack(self) { preRemove() }
            makeOrphan()
            return p.root
        }

        return nil
    }

    func forEach(_ body: (Node<T>, inout Bool) throws -> Void) rethrows -> Bool {
        var flag: Bool = false
        try forEach(flag: &flag, body)
        return flag
    }

    private func forEach(flag: inout Bool, _ body: (Node<T>, inout Bool) throws -> Void) rethrows {
        try leftNode?.forEach(flag: &flag, body)
        if !flag { try body(self, &flag) }
        if !flag { try rightNode?.forEach(flag: &flag, body) }
    }

    private var data:       UInt       = 0
    private var parentNode: Node<T>?   = nil
    private var children:   [Node<T>?] = [ nil, nil ]
}

extension Node {
    //@f:0
    @inlinable var leftNode:     Node<T>? { get { children[Side.Left.rawValue] }  set { self[.Left] = newValue  } }
    @inlinable var rightNode:    Node<T>? { get { children[Side.Right.rawValue] } set { self[.Right] = newValue } }
    @inlinable var farLeftNode:  Node<T>  { leftNode?.farLeftNode ?? self                                         }
    @inlinable var farRightNode: Node<T>  { rightNode?.farRightNode ?? self                                       }
    @inlinable var root:         Node<T>  { parentNode?.root ?? self                                              }

    @inlinable var count:        Int      { get { Int(bitPattern: (data & countBits))      } set { data = ((data & colorBit) | (UInt(bitPattern: newValue) & countBits))  } }
    @inlinable var color:        Color    { get { ((data & colorBit) == 0 ? .Black : .Red) } set { data = ((newValue == .Black) ? (data & countBits) : (data | colorBit)) } }
    //@f:1

    @inlinable func hash(into hasher: inout Hasher) { hasher.combine(item) }

    @inlinable static func == (lhs: Node<T>, rhs: Node<T>) -> Bool { lhs === rhs }

    @inlinable subscript(side: Side) -> Node<T>? {
        get { children[side.rawValue] }
        set {
            let s = side.rawValue
            let c = children[s]
            guard c != newValue else { return }
            c?.parentNode = nil
            newValue?.makeOrphan().parentNode = self
            children[s] = newValue
            recount()
        }
    }

    @inlinable func side(_ p: Node<T>) -> Side { ((self === p[.Left]) ? .Left : .Right) }

    @inlinable @discardableResult func makeOrphan() -> Node<T> {
        if let p = parentNode { p[side(p)] = nil }
        return self
    }

    @inlinable func swapWith(node: Node<T>?) { if let p = parentNode { p[side(p)] = node } }

    @usableFromInline func recount() {
        count = (1 + (leftNode?.count ?? 0) + (rightNode?.count ?? 0))
        parentNode?.recount()
    }

    @inlinable func paintRed() { color = .Red }

    @inlinable func paintBlack() { color = .Black }

    @inlinable func rotate(_ sd: Side) {
        guard let c = self[!sd] else { fatalError("ERROR: Cannot rotate \(sd.name). Missing \((!sd).name) child node.") }
        swapWith(node: c)
        self[!sd] = c[sd]
        c[sd] = self
        swap(&color, &c.color)
    }

    @inlinable func insert(item i: T, side s: Side) -> Node<T> {
        if let n = self[s] { return n.insert(item: i) }
        let n = Node<T>(item: i, color: .Red)
        self[s] = n
        return n.postInsert()
    }

    @usableFromInline func postInsert() -> Node<T> {
        guard let p = parentNode else { paintBlack(); return self }
        guard Color.isRed(p) else { return p.root }
        guard let g = p.parentNode else { fatalError("ERROR: Missing grandparent node.") }
        let pSide = p.side(g)

        if let u = g[!pSide], Color.isRed(u) {
            p.paintBlack()
            u.paintBlack()
            g.paintRed()
            return g.postInsert()
        }

        if pSide != side(p) { p.rotate(pSide) }
        g.rotate(!pSide)
        return root
    }

    @usableFromInline func preRemove() {
        if let p = parentNode {
            var (sd, s, cn, dn) = siblings(parent: p, side: side(p))

            if Color.isRed(s) { (s, cn, dn) = xr(parent: p, nSide: sd, node: p, dir: sd) }

            if Color.isBlack(s) && Color.isBlack(cn) && Color.isBlack(dn) {
                s.paintRed()
                guard Color.isBlack(p) else { return p.paintBlack() }
                return p.preRemove()
            }

            if Color.isRed(cn) { (s, cn, dn) = xr(parent: p, nSide: sd, node: s, dir: !sd) }
            guard let n = dn else { fatalError("ERROR: Missing distant nephew node.") }
            n.paintBlack()
            p.rotate(sd)
        }
    }

    /// Performs a rotation that, in some way, is going to affect this node's sibling. Once the rotation is done this
    /// method will return this nodes new sibling, close nephew, and distant nephew.
    ///
    /// - Parameters:
    ///   - p: This nodes parent node.
    ///   - nSide: Which side of its parent node this node is on - Side.Left or Side.Right.
    ///   - n: The node to be rotated.
    ///   - dir: The direction of rotation.
    /// - Returns: A tuple that includes the new sibling, close nephew, and distant nephew.
    ///
    @inlinable func xr(parent p: Node<T>, nSide: Side, node n: Node<T>, dir: Side) -> (Node<T>, Node<T>?, Node<T>?) {
        n.rotate(dir)
        let t = siblings(parent: p, side: nSide)
        return (t.1, t.2, t.3)
    }

    @inlinable func siblings(parent p: Node<T>, side: Side) -> (Side, Node<T>, Node<T>?, Node<T>?) {
        guard let s = p[!side] else { fatalError("ERROR: Missing sibling node.") }
        return (side, s, s[side], s[!side])
    }
}

extension Node.Side {
    @inlinable prefix static func ! (side: Self) -> Self { (side == .Left ? .Right : .Left) }

    @inlinable var name: String { self == .Left ? "left" : "right" }
}

extension Node.Color {
    @inlinable static func isRed(_ n: Node?) -> Bool { ((n != nil) && (n!.color == .Red)) }

    @inlinable static func isBlack(_ n: Node?) -> Bool { ((n == nil) || (n!.color == .Black)) }
}
