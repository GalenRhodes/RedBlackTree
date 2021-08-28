/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeNode_Index.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 19, 2021
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

extension TreeNode {

    @inlinable var index: Index {
        Index(index: _forPSide(ifNeither: leftCount, ifLeft: { $0.index.idx - rightCount - 1 }, ifRight: { $0.index.idx + leftCount + 1 }))
    }

    @inlinable subscript(index: Index) -> TreeNode<T> {
        guard index.idx >= 0 else { fatalError("Index out of bounds.") }
        switch compare(a: index, b: self.index) {
            case .EqualTo:     return self
            case .LessThan:    if let n = leftNode { return n[index] }
            case .GreaterThan: if let n = rightNode { return n[index] }
        }
        fatalError("Index out of bounds.")
    }

    @frozen public struct Index: Comparable, Hashable {
        @usableFromInline let idx: Int

        @inlinable init(index: Int) { idx = index }

        @inlinable public func hash(into hasher: inout Hasher) { hasher.combine(idx) }

        @inlinable public static func == (lhs: Self, rhs: Self) -> Bool { lhs.idx == rhs.idx }

        @inlinable public static func < (lhs: Self, rhs: Self) -> Bool { lhs.idx < rhs.idx }

        @inlinable static func + (lhs: Self, rhs: Self) -> Self { lhs + rhs.idx }

        @inlinable static func - (lhs: Self, rhs: Self) -> Self { lhs - rhs.idx }

        @inlinable static func + (lhs: Self, rhs: Int) -> Self { Index(index: lhs.idx + rhs) }

        @inlinable static func + (lhs: Int, rhs: Self) -> Self { Index(index: lhs + rhs.idx) }

        @inlinable static func - (lhs: Self, rhs: Int) -> Self { Index(index: lhs.idx - rhs) }

        @inlinable static func - (lhs: Int, rhs: Self) -> Self { Index(index: lhs - rhs.idx) }
    }
}