/*===============================================================================================================================================================================*
 *     PROJECT: RedBlackTree
 *    FILENAME: SimpleIConvCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 8/2/21
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

extension Dictionary where Key: Comparable & Hashable {

    @inlinable public static func treeDictionary() -> TreeDictionary<Self.Key, Self.Value> { TreeDictionary() }

    @inlinable public static func treeDictionary(dictionaryLiteral elements: (Self.Key, Self.Value)...) -> TreeDictionary<Self.Key, Self.Value> { TreeDictionary(elements: elements) }

    @inlinable public static func treeDictionary(dictionary: [Self.Key: Self.Value]) -> TreeDictionary<Self.Key, Self.Value> { TreeDictionary(dictionary: dictionary) }

    public init(treeDictionary tree: TreeDictionary<Key, Value>) {
        self.init(minimumCapacity: tree.count)
        for e in tree { self[e.key] = e.value }
    }
}
