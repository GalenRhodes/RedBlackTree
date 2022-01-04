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

@usableFromInline let NAME_LEFT:  String = "left"
@usableFromInline let NAME_RIGHT: String = "right"
@usableFromInline let NAME_ERROR: String = "ERROR"

@usableFromInline let ERR_MISSING_SIBLING:     String = "\(NAME_ERROR): Missing sibling node."
@usableFromInline let ERR_MISSING_GRANDPARENT: String = "\(NAME_ERROR): Missing grandparent node."
@usableFromInline let ERR_MISSING_NEPHEW:      String = "\(NAME_ERROR): Missing distant nephew node."
@usableFromInline let ERR_NOT_PARENT:          String = "\(NAME_ERROR): Neither node is a parent of the other."
@usableFromInline let ERR_ROTATE_LEFT:         String = "\(NAME_ERROR): Cannot rotate node to the \(NAME_LEFT) because there is no \(NAME_RIGHT) child node."
@usableFromInline let ERR_ROTATE_RIGHT:        String = "\(NAME_ERROR): Cannot rotate node to the \(NAME_RIGHT) because there is no \(NAME_LEFT) child node."

@usableFromInline class Node<T> where T: Hashable & Comparable {
    //@f:0
    @usableFromInline enum Color { case Black, Red }
    @usableFromInline enum Side  { case Left, Right }

    @usableFromInline var item:       T
    @usableFromInline var data:       UInt = 1
    @usableFromInline var parentNode: Node<T>? = nil
    @usableFromInline var leftNode:   Node<T>? = nil { willSet { child_willSet(leftNode,  newValue) } didSet { child_didSet(oldValue,  leftNode) } }
    @usableFromInline var rightNode:  Node<T>? = nil { willSet { child_willSet(rightNode, newValue) } didSet { child_didSet(oldValue, rightNode) } }
    //@f:1

    @usableFromInline init(item i: T, color: Color = .Black) {
        item = i
        data = (1 | color.bit)
    }

    @usableFromInline init(node: Node<T>) {
        item = node.item
        data = node.data
        if let n = node.leftNode { leftNode = Node<T>(node: n) }
        if let n = node.rightNode { rightNode = Node<T>(node: n) }
    }
}

extension Node {
    @inlinable subscript(index: Int) -> Node<T>? { find { index <=> $0.index } }

    @inlinable subscript(item: T) -> Node<T>? { find { item <=> $0.item } }

    @usableFromInline func find(using comparator: (Node<T>) throws -> ComparisonResult) rethrows -> Node<T>? {
        switch try comparator(self) {
            case .orderedSame:       return self
            case .orderedAscending:  return try leftNode?.find(using: comparator)
            case .orderedDescending: return try rightNode?.find(using: comparator)
        }
    }

    @inlinable @discardableResult func forEach(_ body: (Node<T>, inout Bool) throws -> Void) rethrows -> Bool {
        var flag = false
        try forEach(body, stop: &flag)
        return flag
    }

    @usableFromInline func insert(item i: T) -> Node<T> {
        switch i <=> item {
            case .orderedSame:       item = i
            case .orderedAscending:  return insert(item: i, side: .Left)
            case .orderedDescending: return insert(item: i, side: .Right)
        }
        return root
    }

    @usableFromInline func remove() -> Node<T>? {
        if let l = leftNode, let r = rightNode {
            let n = (Bool.random() ? l.farRightNode : r.farLeftNode)
            swap(&item, &n.item)
            return n.remove()
        }
        if let c = (leftNode ?? rightNode) {
            c.color = .Black
            unLink(newNode: c)
            return c.root
        }
        if let p = parentNode {
            if self == Color.Black { preRemove() }
            unLink()
            return p.root
        }
        return nil
    }

    @usableFromInline func removeAll() {
        if let n = leftNode {
            n.removeAll()
            leftNode = nil
        }
        if let n = rightNode {
            n.removeAll()
            rightNode = nil
        }
        parentNode = nil
        data = 1
    }

    @usableFromInline func preRemove() {
        if let p = parentNode {
            let side    = (self <=> p)
            var sibling = preconditionNotNil(p[!side], ERR_MISSING_SIBLING)

            if sibling == Color.Red {
                p.rotate(dir: side)
                sibling = preconditionNotNil(p[!side], ERR_MISSING_SIBLING)
            }

            if sibling == Color.Black && sibling.leftNode == Color.Black && sibling.rightNode == Color.Black {
                sibling.color = .Red
                if p == Color.Black { p.preRemove() }
                else { p.color = .Black }
            }
            else {
                if let nn = sibling[side], nn == Color.Red {
                    sibling.rotate(dir: !side)
                    sibling = nn
                }
                preconditionNotNil(sibling[!side], ERR_MISSING_NEPHEW).color = .Black
                p.rotate(dir: side)
            }
        }
    }

    @inlinable func insert(item i: T, side: Side) -> Node<T> {
        if let n = self[side] { return n.insert(item: i) }
        let n = Node<T>(item: i, color: .Red)
        self[side] = n
        n.postInsert()
        return root
    }

    @usableFromInline func postInsert() {
        if let p = parentNode {
            if p == Color.Red {
                let g  = preconditionNotNil(p.parentNode, ERR_MISSING_GRANDPARENT)
                let s1 = (p <=> g)
                let s2 = !s1

                if let u = g[s2], u == Color.Red {
                    u.color = .Black
                    p.color = .Black
                    g.color = .Red
                    return g.postInsert()
                }

                if s1 != (self <=> p) { rotate(dir: s1) }
                g.rotate(dir: s2)
            }
            return
        }
        color = .Black
    }

    @inlinable func rotate(dir d: Side) {
        let _d = !d
        let c  = preconditionNotNil(self[_d], d.isLeft ? ERR_ROTATE_LEFT : ERR_ROTATE_RIGHT)
        unLink(newNode: c)
        self[_d] = c[d]
        c[d] = self
        swap(&color, &c.color)
    }

    @usableFromInline @discardableResult func unLink(newNode: Node<T>? = nil) -> Node<T> {
        if let p = parentNode { p[self <=> p] = newNode }
        else if let n = newNode { n.unLink() }
        return self
    }

    @usableFromInline func forEach(_ body: (Node<T>, inout Bool) throws -> Void, stop flag: inout Bool) rethrows {
        if let n = leftNode { try n.forEach(body, stop: &flag) }
        if !flag {
            try body(self, &flag)
            if !flag { if let n = rightNode { try n.forEach(body, stop: &flag) } }
        }
    }

    //@f:0
    @inlinable subscript(side: Side) -> Node<T>? {
        get { side.isLeft ? leftNode : rightNode }
        set { if side.isLeft { leftNode = newValue } else { rightNode = newValue } }
    }
    //@f:1

    @inlinable func child_willSet(_ oldNode: Node<T>?, _ newNode: Node<T>?) {
        if oldNode !== newNode {
            if let n = oldNode { n.parentNode = nil }
            if let n = newNode { n.unLink().parentNode = self }
        }
    }

    @inlinable func child_didSet(_ oldNode: Node<T>?, _ newNode: Node<T>?) {
        if oldNode !== newNode { recount() }
    }

    @usableFromInline func recount() {
        count = (1 + leftCount + rightCount)
        parentNode?.recount()
    }

    @inlinable static func <=> (l: Node<T>, r: Node<T>) -> Side {
        if l.parentNode === r { return l === r.leftNode ? .Left : .Right }
        if r.parentNode === l { return r === l.leftNode ? .Left : .Right }
        fatalError(ERR_NOT_PARENT)
    }

    //@f:0
    @usableFromInline var farLeftNode:  Node<T> { leftNode?.farLeftNode ?? self   }
    @usableFromInline var farRightNode: Node<T> { rightNode?.farRightNode ?? self }
    @usableFromInline var root:         Node<T> { parentNode?.root ?? self        }

    @inlinable        var color:        Color   { get { Color.color(data) } set { data = ((data & countBits) | newValue.bit) } }

    @inlinable        var count:        Int     { get { Int(bitPattern: data & countBits) } set { data = ((data & colorBit) | (UInt(bitPattern: newValue) & countBits)) }                                 }
    @inlinable        var leftCount:    Int     { leftNode?.count ?? 0                                                                                                                                    }
    @inlinable        var rightCount:   Int     { rightNode?.count ?? 0                                                                                                                                   }
    @usableFromInline var index:        Int     { ifNil(parentNode) { () -> Int in leftCount } else: { (p: Node<T>) -> Int in (self === p.leftNode ? p.index - leftCount - 1 : p.index + leftCount + 1) } }
    //@f:1
}

extension Node.Side {
    @inlinable var isLeft:  Bool { self == .Left }
    @inlinable var isRight: Bool { self == .Right }

    @inlinable static prefix func ! (s: Self) -> Self { s.isLeft ? .Right : .Left }
}

@usableFromInline let colorBit:  UInt = (1 << (UInt.bitWidth - 1))
@usableFromInline let countBits: UInt = ~colorBit

extension Node.Color {
    @inlinable var bit: UInt { self == .Red ? colorBit : 0 }

    @inlinable static func color(_ d: UInt) -> Self { (d & colorBit) == 0 ? .Black : .Red }

    @inlinable static func == (l: Node?, r: Self) -> Bool { (l?.color ?? .Black) == r }
}
