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

@usableFromInline class Node<T> where T: Hashable & Comparable {
    @usableFromInline typealias ND = Node<T>

    @usableFromInline enum Color { case Black, Red }

    @usableFromInline enum Side { case Left, Right }

    //@f:0
    @usableFromInline var item:       T
    @usableFromInline var data:       UInt
    @usableFromInline var parentNode: ND?
    @usableFromInline var leftNode:   ND? = nil { willSet { _foo(newValue,  leftNode) } didSet { _bar(leftNode,  oldValue) } }
    @usableFromInline var rightNode:  ND? = nil { willSet { _foo(newValue, rightNode) } didSet { _bar(rightNode, oldValue) } }
    //@f:1

    @usableFromInline convenience init(item: T, color: Color = .Black) {
        self.init(item: item, data: color.d(1))
    }

    @usableFromInline init(item: T, data: UInt = 1, leftNode: ND? = nil, rightNode: ND? = nil) {
        self.item = item
        self.data = data
        self.leftNode = leftNode
        self.rightNode = rightNode
    }

    @usableFromInline func findNode(_ comparator: (ND) throws -> ComparisonResult) rethrows -> ND? {
        switch try comparator(self) {
            case .orderedSame:       return self
            case .orderedAscending:  return try _get(from: leftNode, default: nil) { try $0.findNode(comparator) }
            case .orderedDescending: return try _get(from: rightNode, default: nil) { try $0.findNode(comparator) }
        }
    }

    @usableFromInline func removeAll() {
        leftNode?.removeAll()
        rightNode?.removeAll()
        leftNode = nil
        rightNode = nil
        parentNode = nil
        data = 0
    }

    @usableFromInline func copy() -> ND { ND(item: item, data: data, leftNode: leftNode?.copy(), rightNode: rightNode?.copy()) }
}

extension Node {
    //@f:0
    @inlinable var farLeftNode:  ND    { _get(from: leftNode,   default: self)      { $0.farLeftNode                                                                    } }
    @inlinable var farRightNode: ND    { _get(from: rightNode,  default: self)      { $0.farLeftNode                                                                    } }
    @inlinable var root:         ND    { _get(from: parentNode, default: self)      { $0.root                                                                           } }
    @inlinable var leftCount:    Int   { _get(from: leftNode,   default: 0)         { $0.count                                                                          } }
    @inlinable var rightCount:   Int   { _get(from: rightNode,  default: 0)         { $0.count                                                                          } }
    @usableFromInline var index: Int   { _get(from: parentNode, default: leftCount) { (self === $0.rightNode) ? ($0.index + leftCount + 1) : ($0.index - leftCount - 1) } }

    @inlinable var count:        Int   { get { Int(bitPattern: (data & countBits)) } set { data = ((data & colorBit) | (UInt(bitPattern: newValue) & countBits)) } }
    @inlinable var color:        Color { get { Color.color(data)                   } set { data = newValue.d(data)                                         } }
    //@f:1
}

extension Node {
    //@f:0
    @inlinable subscript(side: Side) -> ND? { get { side.with { leftNode } right: { rightNode } } set { side.with { leftNode = newValue } right: { rightNode = newValue } } }
    @inlinable subscript(index: T)   -> ND? { find { comp(index, $0) } }
    //@f:1
}

extension Node {
    @inlinable func find(index i: Int) -> ND? { findNode { comp(i, $0.index) } }

    @inlinable func find(using comparator: (T) throws -> ComparisonResult) rethrows -> ND? { try findNode { try comparator($0.item) } }
}

extension Node {
    @inlinable @discardableResult func forEach(_ body: (ND, inout Bool) throws -> Void) rethrows -> Bool {
        var stop: Bool = false
        try _forEach(flag: &stop, do: body)
        return stop
    }

    @usableFromInline func _forEach(flag stop: inout Bool, do body: (ND, inout Bool) throws -> Void) rethrows {
        guard !stop else { return }
        try _with(node: leftNode) { try $0._forEach(flag: &stop, do: body) }
        guard !stop else { return }
        try body(self, &stop)
        guard !stop else { return }
        try _with(node: rightNode) { try $0._forEach(flag: &stop, do: body) }
    }
}

extension Node {
    @usableFromInline func insert(item i: T) -> ND {
        switch comp(i, item) {
            case .orderedSame:       item = i
            case .orderedAscending:  return _i1(item: i, side: .Left)
            case .orderedDescending: return _i1(item: i, side: .Right)
        }
        return root
    }

    @inlinable func _i1(item i: T, side sd: Side) -> ND {
        if let n = self[sd] { return n.insert(item: i) }
        let n = ND(item: item, color: .Red)
        self[sd] = n
        return n._i2()
    }

    @usableFromInline func _i2() -> ND { _withParent { _i3() } do: { ($0 == Color.Red) ? root : _i4($0, $1) } }

    @inlinable func _i3() -> ND { color = .Black; return self }

    @inlinable func _i4(_ p: ND, _ ns: Side) -> ND { p._withParent(ERR_NO_GRANDPARENT) { _i5($0, p, ns, $1) } }

    @inlinable func _i5(_ g: ND, _ p: ND, _ ns: Side, _ ps: Side) -> ND {
        _with(node: g[!ps]) { (($0 == Color.Black) ? _i6(g, p, ns, ps) : _i7(g, p, $0)) } else: { _i6(g, p, ns, ps) }
    }

    @inlinable func _i6(_ g: ND, _ p: ND, _ ns: Side, _ ps: Side) -> ND {
        if ps != ns { p._rotate(ps) }
        g._rotate(!ps)
        return root
    }

    @inlinable func _i7(_ g: ND, _ p: ND, _ u: ND) -> ND {
        p.color = .Black
        u.color = .Black
        g.color = .Red
        return g._i2()
    }
}

extension Node {
    @usableFromInline func remove() -> ND? {
        //@f:0
        doWith(default: nil,
               ([ leftNode, rightNode ],     { (a: [ND]) -> ND? in self._r1(left: a[0], right: a[1]) }),
               ([ (leftNode ?? rightNode) ], { (a: [ND]) -> ND? in self._r2(child: a[0])             }),
               ([ parentNode ],              { (a: [ND]) -> ND? in self._r3(parent: a[0])            }))
        //@f:1
    }

    @inlinable func _r1(left l: ND, right r: ND) -> ND? {
        let n = Bool.random() ? l.farRightNode : r.farLeftNode
        swap(&item, &n.item)
        return n.remove()
    }

    @inlinable func _r2(child c: ND) -> ND? {
        c.color = .Black
        _withParent { $0[$1] = c }
        return c.root
    }

    @inlinable func _r3(parent p: ND) -> ND? {
        if self == Color.Black { _r4() }
        p[self ?= p] = nil
        return p.root
    }

    @usableFromInline typealias tup1 = (Side, ND, ND?, ND?)
    @usableFromInline typealias tup2 = (ND, ND?, ND?)

    @usableFromInline func _r4() {
        if let parent = parentNode {
            var (side, sibling, closeNephew, distantNephew) = _r5(parent: parent, side: self ?= parent)

            if sibling == Color.Red { (sibling, closeNephew, distantNephew) = _r6(parent: parent, nSide: side, node: parent, dir: side) }

            if sibling == Color.Black && closeNephew == Color.Black && distantNephew == Color.Black {
                sibling.color = .Red
                guard parent == Color.Black else { return parent.color = .Black }
                return parent._r4()
            }

            if closeNephew == Color.Red { (sibling, closeNephew, distantNephew) = _r6(parent: parent, nSide: side, node: sibling, dir: !side) }
            _with(node: distantNephew, ERR_NO_DISTANT_NEPHEW) { $0.color = .Black }
            parent._rotate(side)
        }
    }

    @inlinable func _r5(parent p: ND, side: Side) -> tup1 { assertNotNil(p[!side], ERR_NO_SIBLING) { (s: ND) -> tup1 in (side, s, s[side], s[!side]) } }

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
    @inlinable func _r6(parent p: ND, nSide: Side, node n: ND, dir: Side) -> tup2 {
        n._rotate(dir)
        let t = _r5(parent: p, side: nSide)
        return (t.1, t.2, t.3)
    }
}

extension Node {
    @inlinable @discardableResult func _withParent(do action: (ND, Side) throws -> Void) rethrows -> ND {
        try _withParent(none: {}, do: action); return self
    }

    @inlinable func _withParent<R>(none noneAction: () throws -> R, do action: (ND, Side) throws -> R) rethrows -> R {
        guard let p = parentNode else { return try noneAction() }
        return try action(p, (self ?= p))
    }

    @inlinable func _withParent<R>(_ msg: @autoclosure () -> String, _ action: (ND, Side) throws -> R) rethrows -> R { try assertNotNil(parentNode, msg()) { try action($0, (self ?= $0)) } }

    @inlinable func _with(node: ND?, do action: (ND) throws -> Void) rethrows { if let n = node { try action(n) } }

    @inlinable func _with<R>(node: ND?, _ msg: @autoclosure () -> String, _ action: (ND) throws -> R) rethrows -> R { try assertNotNil(node, msg(), action) }

    @inlinable func _with<R>(node: ND?, do action: (ND) throws -> R, else noAction: () throws -> R) rethrows -> R {
        guard let n = node else { return try noAction() }
        return try action(n)
    }

    @inlinable func _get<R>(from node: ND?, default defaultValue: @autoclosure () -> R, _ getter: (ND) throws -> R) rethrows -> R {
        guard let n = node else { return defaultValue() }
        return try getter(n)
    }
}

extension Node {
    @usableFromInline func _recount() {
        count = (1 + leftCount + rightCount)
        _withParent { p, _ in p._recount() }
    }

    @inlinable func _rotate(_ sd: Side) {
        assertNotNil(self[!sd], sd == .Left ? ERR_ROT_LEFT : ERR_ROT_RIGHT) { (c: ND) -> Void in
            _withParent { p, s in p[s] = c }
            self[!sd] = c[sd]
            c[sd] = self
            swap(&color, &c.color)
        }
    }

    @inlinable func _foo(_ newNode: ND?, _ oldNode: ND?) {
        guard newNode !== oldNode else { return }
        _with(node: oldNode) { $0.parentNode = nil }
        _with(node: newNode) {
            $0._withParent { p, s in p[s] = nil }
            $0.parentNode = self
        }
    }

    @inlinable func _bar(_ newNode: ND?, _ oldNode: ND?) { if newNode !== oldNode { _recount() } }

    @inlinable static func ?= (lhs: ND, rhs: ND) -> Side {
        if lhs.parentNode === rhs {
            return lhs === rhs.leftNode ? .Left : .Right
        }
        else if rhs.parentNode === lhs {
            return rhs === lhs.leftNode ? .Left : .Right
        }
        fatalError("ERROR: Hierarchy Error")
    }
}

extension Node: Hashable {
    @inlinable static func == (lhs: ND, rhs: ND) -> Bool { lhs === rhs }

    @inlinable func hash(into hasher: inout Hasher) { hasher.combine(item) }
}

extension Node.Side {
    @inlinable var isLeft:  Bool { self == .Left }
    @inlinable var isRight: Bool { self == .Right }
    @inlinable var name:    String { isLeft ? "left" : "right" }

    @inlinable prefix static func ! (side: Self) -> Self { (side.isLeft ? .Right : .Left) }

    @inlinable func with<R>(left: () throws -> R, right: () throws -> R) rethrows -> R { try (isLeft ? left() : right()) }
}

extension Node.Color {
    @inlinable var bitValue: UInt { isRed ? colorBit : 0 }
    @inlinable var isRed:    Bool { self == .Red }
    @inlinable var isBlack:  Bool { self == .Black }

    @inlinable func d(_ data: UInt) -> UInt { (data & countBits) | bitValue }

    @inlinable static func color(_ data: UInt) -> Self { (data & colorBit) == 0 ? .Black : .Red }

    @inlinable static func == (lhs: Node.ND?, rhs: Self) -> Bool { (lhs?.color ?? .Black) == rhs }

    @inlinable static func == (lhs: Self, rhs: Node.ND?) -> Bool { rhs == lhs }
}
