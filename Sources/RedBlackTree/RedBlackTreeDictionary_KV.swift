/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: RedBlackTreeDictionary_KV.swift
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

extension RedBlackTreeDictionary {
    @usableFromInline struct KV {
        @usableFromInline enum CodingKeys: String, CodingKey { case key, value }

        public let key:   Key
        public let value: Value

        @usableFromInline init(key: Key, value: Value) { self.key = key; self.value = value }

        @usableFromInline init(_ e: Element) { key = e.0; value = e.1 }
    }
}

extension RedBlackTreeDictionary.KV: Decodable where Key: Decodable, Value: Decodable {
    @usableFromInline init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = try c.decode(Key.self, forKey: .key)
        value = try c.decode(Value.self, forKey: .value)
    }
}

extension RedBlackTreeDictionary.KV: Encodable where Key: Encodable, Value: Encodable {
    @usableFromInline func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(key, forKey: .key)
        try c.encode(value, forKey: .value)
    }
}

extension RedBlackTreeDictionary.KV: Comparable, Equatable {
    @usableFromInline static func < (lhs: Self, rhs: Self) -> Bool { lhs.key < rhs.key }

    @usableFromInline static func == (lhs: Self, rhs: Self) -> Bool { lhs.key == rhs.key }
}

extension RedBlackTreeDictionary.KV: Hashable where Key: Hashable {
    @usableFromInline func hash(into hasher: inout Hasher) { hasher.combine(key) }
}
