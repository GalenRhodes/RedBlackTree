/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeIndex.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 30, 2021
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

@frozen public struct TreeIndex: Strideable, Comparable, Hashable, Equatable {
    public typealias Stride = Int

    @usableFromInline let idx: Int

    @inlinable init(index idx: Int) { self.idx = idx }

    @inlinable public func distance(to other: TreeIndex) -> Stride { other.idx - idx }

    @inlinable public func advanced(by n: Stride) -> TreeIndex { TreeIndex(index: idx + n) }

    @inlinable public static func < (lhs: TreeIndex, rhs: TreeIndex) -> Bool { lhs.idx < rhs.idx }

    @inlinable public static func == (lhs: TreeIndex, rhs: TreeIndex) -> Bool { lhs.idx == rhs.idx }

    @inlinable public func hash(into hasher: inout Hasher) { hasher.combine(idx) }

    @inlinable static func + (lhs: TreeIndex, rhs: TreeIndex) -> TreeIndex { TreeIndex(index: lhs.idx + rhs.idx) }

    @inlinable static func - (lhs: TreeIndex, rhs: TreeIndex) -> TreeIndex { TreeIndex(index: lhs.idx - rhs.idx) }

    @inlinable static func + (lhs: TreeIndex, rhs: Int) -> TreeIndex { TreeIndex(index: lhs.idx + rhs) }

    @inlinable static func - (lhs: TreeIndex, rhs: Int) -> TreeIndex { TreeIndex(index: lhs.idx - rhs) }

    @inlinable static func + (lhs: Int, rhs: TreeIndex) -> TreeIndex { TreeIndex(index: lhs + rhs.idx) }

    @inlinable static func - (lhs: Int, rhs: TreeIndex) -> TreeIndex { TreeIndex(index: lhs - rhs.idx) }
}
