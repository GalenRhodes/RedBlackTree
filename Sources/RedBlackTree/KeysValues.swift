/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: KeysValues.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 04, 2021
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

extension TreeDictionary {
    public struct Keys: BidirectionalCollection {

        public typealias Index = TreeDictionary.Index
        public typealias Indices = TreeDictionary.Indices
        public typealias Element = TreeDictionary.Key

        public var startIndex: Index { tree.startIndex }
        public var endIndex:   Index { tree.endIndex }
        public var indices:    Indices { tree.indices }

        let tree: TreeDictionary<Key, Value>

        init(tree: TreeDictionary<Key, Value>) { self.tree = tree }

        public subscript(position: Index) -> Element { tree[position].key }

        public func index(before i: Index) -> Index { tree.index(before: i) }

        public func index(after i: Index) -> Index { tree.index(after: i) }
    }

    public struct Values: BidirectionalCollection {

        public typealias Index = TreeDictionary.Index
        public typealias Indices = TreeDictionary.Indices
        public typealias Element = TreeDictionary.Value

        public var startIndex: Index { tree.startIndex }
        public var endIndex:   Index { tree.endIndex }
        public var indices:    Indices { tree.indices }

        let tree: TreeDictionary<Key, Value>

        init(tree: TreeDictionary<Key, Value>) { self.tree = tree }

        public subscript(position: Index) -> Element { tree[position].value }

        public func index(before i: Index) -> Index { tree.index(before: i) }

        public func index(after i: Index) -> Index { tree.index(after: i) }
    }
}
