/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: RedBlackTreeDictionary_Codable.swift
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

extension RedBlackTreeDictionary: Encodable where Key: Encodable, Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        for e in self { try c.encode(KV(e)) }
    }
}

extension RedBlackTreeDictionary: Decodable where Key: Decodable, Value: Decodable {}

extension RedBlackTreeDictionary: Equatable where Value: Equatable {
    public static func == (lhs: RedBlackTreeDictionary<Key, Value>, rhs: RedBlackTreeDictionary<Key, Value>) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for e: Element in lhs { guard rhs.contains(e) else { return false } }
        return true
    }

    public func contains(_ element: Element) -> Bool { contains { ((element.0 == $0.0) && (element.1 == $0.1)) } }
}
