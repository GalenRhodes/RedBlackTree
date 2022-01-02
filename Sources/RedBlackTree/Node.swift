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

    @usableFromInline func copy() -> ND { ND(item: item, data: data, leftNode: leftNode?.copy(), rightNode: rightNode?.copy()) }
}

extension Node {
    @inlinable func find(index i: Int) -> ND? { findNode { comp(i, $0.index) } }

    @inlinable func find(using comparator: (T) throws -> ComparisonResult) rethrows -> ND? { try findNode { try comparator($0.item) } }

    @usableFromInline func findNode(_ comparator: (ND) throws -> ComparisonResult) rethrows -> ND? {
        switch try comparator(self) {
            case .orderedSame:       return self
            case .orderedAscending:  return try _get(from: leftNode, default: nil) { try $0.findNode(comparator) }
            case .orderedDescending: return try _get(from: rightNode, default: nil) { try $0.findNode(comparator) }
        }
    }
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
