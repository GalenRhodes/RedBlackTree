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

@usableFromInline let colorBit:  UInt = (1 << (UInt.bitWidth - 1))
@usableFromInline let countBits: UInt = ~(colorBit)

@usableFromInline let ERR_ROT_LEFT:          String = "ERROR: Cannot rotate left. Missing right child node."
@usableFromInline let ERR_ROT_RIGHT:         String = "ERROR: Cannot rotate right. Missing left child node."
@usableFromInline let ERR_NO_GRANDPARENT:    String = "ERROR: Missing grandparent node."
@usableFromInline let ERR_NO_DISTANT_NEPHEW: String = "ERROR: Missing distant nephew node."
@usableFromInline let ERR_NO_SIBLING:        String = "ERROR: Missing sibling node."

@usableFromInline class Node<T>: Hashable where T: Hashable & Comparable {

    @usableFromInline enum Color { case Black, Red }

    @usableFromInline enum Side { case Left, Right }

    @usableFromInline var item: T

    @usableFromInline convenience init(item: T, color: Color = .Black) { self.init(item: item, data: (1 | (color == .Red ? colorBit : 0))) }

    @usableFromInline init(item: T, data: UInt = 1, parentNode: Node<T>? = nil, leftNode: Node<T>? = nil, rightNode: Node<T>? = nil) {
        self.item = item
        self.data = data
        self.parentNode = parentNode
        self.leftNode = leftNode
        self.rightNode = rightNode
    }

    @usableFromInline func findNode(_ comparator: (Node<T>) throws -> ComparisonResult) rethrows -> Node<T>? {
        switch try comparator(self) {
            case .orderedSame:       return self
            case .orderedAscending:  return try _get(from: leftNode, default: nil) { try $0.findNode(comparator) }
            case .orderedDescending: return try _get(from: rightNode, default: nil) { try $0.findNode(comparator) }
        }
    }

    @usableFromInline func remove() -> Node<T>? {
        if let l = leftNode, let r = rightNode {
            let n = (Bool.random() ? l.farRightNode : r.farLeftNode)
            swap(&item, &n.item)
            return n.remove()
        }
        else if let c = (leftNode ?? rightNode) {
            c.color = .Black
            _withParent { p, s in p[s] = c }
            return c.root
        }
        else if let p = parentNode {
            if Color.isBlack(self) { preRemove() }
            p[self === p[.Left] ? .Left : .Right] = nil
            return p.root
        }

        return nil
    }

    @usableFromInline func removeAll() {
        _with(node: leftNode) { $0.removeAll(); leftNode = nil }
        _with(node: rightNode) { $0.removeAll(); rightNode = nil }
        parentNode = nil
        data = 0
    }

    @usableFromInline func copy() -> Node<T> { Node<T>(item: item, data: data, parentNode: nil, leftNode: leftNode?.copy(), rightNode: rightNode?.copy()) }

    //@f:0
    @usableFromInline var data:       UInt
    @usableFromInline var parentNode: Node<T>?
    @usableFromInline var leftNode:   Node<T>? = nil { willSet { _foo(newValue,  leftNode) } didSet { _bar(leftNode,  oldValue) } }
    @usableFromInline var rightNode:  Node<T>? = nil { willSet { _foo(newValue, rightNode) } didSet { _bar(rightNode, oldValue) } }
    //@f:1
}

extension Node {

    //@f:0
    @inlinable var farLeftNode:  Node<T>  { _get(from: leftNode,   default: self) { $0.farLeftNode } }
    @inlinable var farRightNode: Node<T>  { _get(from: rightNode,  default: self) { $0.farLeftNode } }
    @inlinable var root:         Node<T>  { _get(from: parentNode, default: self) { $0.root        } }

    @inlinable var count:        Int      { get { Int(bitPattern: (data & countBits))      } set { data = ((data & colorBit) | (UInt(bitPattern: newValue) & countBits))  } }
    @inlinable var color:        Color    { get { ((data & colorBit) == 0 ? .Black : .Red) } set { data = ((newValue == .Black) ? (data & countBits) : (data | colorBit)) } }
    //@f:1

    @usableFromInline var index: Int {
        let lc = _get(from: leftNode, default: 0) { $0.count }
        return _get(from: parentNode, default: lc) { (self === $0.rightNode) ? ($0.index + lc + 1) : ($0.index - lc - 1) }
    }

    @inlinable subscript(side: Side) -> Node<T>? {
        get { ((side == .Left) ? leftNode : rightNode) }
        set { doIf(side == .Left) { leftNode = newValue } else: { rightNode = newValue } }
    }

    @inlinable subscript(i: T) -> Node<T>? { find { RedBlackTree.compare(i, $0) } }

    @inlinable func find(index i: Int) -> Node<T>? { findNode { RedBlackTree.compare(i, $0.index) } }

    @inlinable func find(using comparator: (T) throws -> ComparisonResult) rethrows -> Node<T>? { try findNode { try comparator($0.item) } }

    @inlinable @discardableResult func forEach(_ body: (Node<T>, inout Bool) throws -> Void) rethrows -> Bool {
        var stop: Bool = false
        try _forEach(flag: &stop, do: body)
        return stop
    }

    @usableFromInline func insert(item i: T) -> Node<T> {
        switch RedBlackTree.compare(i, item) {
            case .orderedSame:       item = i
            case .orderedAscending:  return _insert(item: i, side: .Left)
            case .orderedDescending: return _insert(item: i, side: .Right)
        }
        return root
    }

    @usableFromInline func postInsert() -> Node<T> {
        _withParent { color = .Black } do: { p, nSide in
            if Color.isRed(p) {
                p._withParent { _error(ERR_NO_GRANDPARENT) } do: { g, pSide in
                    let uSide = !pSide

                    if let u = g[uSide], Color.isRed(u) {
                        p.color = .Black
                        u.color = .Black
                        g.color = .Red
                        return g.postInsert()
                    }

                    if pSide != (self === p.leftNode ? .Left : .Right) { p.rotate(pSide) }
                    g.rotate(uSide)
                }
            }
        }
        return root
    }

    @inlinable func _error(_ message: @autoclosure () -> String = String()) {
        fatalError(message())
    }

    @usableFromInline func preRemove() {
        if let p = parentNode {
            var (sd, s, cn, dn) = siblings(parent: p, side: self === p.leftNode ? .Left : .Right)

            if Color.isRed(s) { (s, cn, dn) = xr(parent: p, nSide: sd, node: p, dir: sd) }

            if Color.isBlack(s) && Color.isBlack(cn) && Color.isBlack(dn) {
                s.color = .Red
                guard Color.isBlack(p) else { return p.color = .Black }
                return p.preRemove()
            }

            if Color.isRed(cn) { (s, cn, dn) = xr(parent: p, nSide: sd, node: s, dir: !sd) }
            guard let n = dn else { _error(ERR_NO_DISTANT_NEPHEW) }
            n.color = .Black
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
        let xide = !side
        guard let s = p[xide] else { _error(ERR_NO_SIBLING) }
        return (side, s, s[side], s[xide])
    }

    @usableFromInline func recount() {
        count = (1 + _get(from: leftNode, default: 0, { $0.count }) + _get(from: rightNode, default: 0, { $0.count }))
        _withParent { p, _ in p.recount() }
    }

    @inlinable func rotate(_ sd: Side) {
        guard let c = self[!sd] else { _error(sd == .Left ? ERR_ROT_LEFT : ERR_ROT_RIGHT) }
        _withParent { p, s in p[s] = c }
        self[!sd] = c[sd]
        c[sd] = self
        swap(&color, &c.color)
    }

    @inlinable func _insert(item i: T, side sd: Side) -> Node<T> {
        if let n = self[sd] { return n.insert(item: i) }
        let n = Node<T>(item: item, color: .Red)
        self[sd] = n
        return n.postInsert()
    }

    @inlinable @discardableResult func _withParent(do action: (Node<T>, Side) throws -> Void) rethrows -> Node<T> { try _withParent(none: {}, do: action); return self }

    @inlinable func _withParent(none noneAction: () throws -> Void, do action: (Node<T>, Side) throws -> Void) rethrows {
        if let p = parentNode { try action(p, self === p.leftNode ? .Left : .Right) }
        else { try noneAction() }
    }

    @inlinable func _with(node: Node<T>?, do action: (Node<T>) throws -> Void) rethrows { if let n = node { try action(n) } }

    @inlinable func _get<R>(from node: Node<T>?, default defaultValue: @autoclosure () -> R, _ getter: (Node<T>) throws -> R) rethrows -> R {
        guard let n = node else { return defaultValue() }
        return try getter(n)
    }

    @inlinable func _foo(_ newNode: Node<T>?, _ oldNode: Node<T>?) {
        guard newNode !== oldNode else { return }
        _with(node: oldNode) { $0.parentNode = nil }
        _with(node: newNode) {
            $0._withParent { p, s in p[s] = nil }
            $0.parentNode = self
        }
    }

    @inlinable func _bar(_ newNode: Node<T>?, _ oldNode: Node<T>?) { if newNode !== oldNode { recount() } }

    @usableFromInline func _forEach(flag stop: inout Bool, do body: (Node<T>, inout Bool) throws -> Void) rethrows {
        guard !stop else { return }
        try _with(node: leftNode) { try $0._forEach(flag: &stop, do: body) }
        guard !stop else { return }
        try body(self, &stop)
        guard !stop else { return }
        try _with(node: rightNode) { try $0._forEach(flag: &stop, do: body) }
    }

    @inlinable static func == (lhs: Node<T>, rhs: Node<T>) -> Bool { lhs === rhs }

    @inlinable func hash(into hasher: inout Hasher) { hasher.combine(item) }
}

extension Node.Side {
    @inlinable prefix static func ! (side: Self) -> Self { (side == .Left ? .Right : .Left) }

    @inlinable var name: String { self == .Left ? "left" : "right" }
}

extension Node.Color {
    @inlinable static func isRed(_ n: Node?) -> Bool { ((n != nil) && (n!.color == .Red)) }

    @inlinable static func isBlack(_ n: Node?) -> Bool { ((n == nil) || (n!.color == .Black)) }
}
