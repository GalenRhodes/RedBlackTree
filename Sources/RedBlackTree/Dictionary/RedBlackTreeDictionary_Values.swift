/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: RedBlackTreeDictionary_Values.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 23, 2021
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

extension RedBlackTreeDictionary {

    @inlinable public var values: Values { Values(tree: self) }

    @frozen public struct Values: BidirectionalCollection {

        public typealias Index = RedBlackTreeDictionary.Index
        public typealias Element = Value

        @inlinable public var startIndex: Index { tree.startIndex }
        @inlinable public var endIndex:   Index { tree.endIndex }
        @usableFromInline let tree: RedBlackTreeDictionary<Key, Value>

        @inlinable public init(tree: RedBlackTreeDictionary<Key, Value>) { self.tree = tree }

        @inlinable public func index(before i: Index) -> Index { tree.index(before: i) }

        @inlinable public func index(after i: Index) -> Index { tree.index(after: i) }

        @inlinable public subscript(position: Index) -> Element { tree[position].1 }
    }
}
