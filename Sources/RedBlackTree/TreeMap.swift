/*===============================================================================================================================================================================*
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeMap.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/26/21
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

public class TreeMap<K, V> where K: Hashable & Comparable {
    var sample: [K: V] = [:]

    @usableFromInline var treeRoot: Node<T>? = nil

    public let startIndex: Index = 0
}

extension TreeMap {

    @inlinable public func forEach(_ body: (K, V) throws -> Void) rethrows {
        guard let r = treeRoot else { return }
        try r.forEach { n, _ in try body(n.item.key, n.item.value) }
    }

    @inlinable func forEach(_ body: (K, V, inout Bool) throws -> Void) rethrows -> Bool {
        guard let r = treeRoot else { return false }
    }

    @inlinable public subscript(key: K) -> V? {
        get {
            guard let r = treeRoot, let n = r.find({ RedBlackTree.compare(key, $0.key) }) else { return nil }
            return n.item.value
        }
        set {
            if let r = treeRoot {
                if let n = r.find({ RedBlackTree.compare(key, $0.key) }) {
                    if let v = newValue { n.item.value = v }
                    else { treeRoot = n.remove() }
                }
                else if let v = newValue {
                    treeRoot = r.insert(item: T(key: key, value: v))
                }
            }
            else if let v = newValue {
                treeRoot = Node<T>(item: T(key: key, value: v))
            }
        }
    }

    @usableFromInline struct T: Hashable, Comparable {
        @usableFromInline let key:   K
        @usableFromInline var value: V

        @inlinable init(key: K, value: V) {
            self.key = key
            self.value = value
        }

        @inlinable func hash(into hasher: inout Hasher) { hasher.combine(key) }

        @inlinable static func < (lhs: T, rhs: T) -> Bool { lhs.key < rhs.key }

        @inlinable static func == (lhs: T, rhs: T) -> Bool { lhs.key == rhs.key }
    }
}

extension TreeMap: BidirectionalCollection {
    public typealias Element = (key: K, value: V)

    @inlinable public var endIndex: Index { Index(treeRoot?.count ?? 0) }

    @inlinable public subscript(position: Index) -> Element {
        guard let r = treeRoot, let n = r.nodeWith(index: position.index) else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return (key: n.item.key, value: n.item.value)
    }

    @inlinable public func index(after i: Index) -> Index {
        guard i < endIndex else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return i.advanced(by: 1)
    }

    @inlinable public func index(before i: Index) -> Index {
        guard i > startIndex else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return i.advanced(by: -1)
    }

    @frozen public struct Index: Hashable, Strideable, ExpressibleByIntegerLiteral {
        public typealias Stride = Int

        @usableFromInline let index: Int

        @inlinable public func distance(to other: Index) -> Stride { (other.index - index) }

        @inlinable public func advanced(by n: Stride) -> Index { Index((index + n)) }

        @inlinable init(_ index: Int) { self.index = index }

        @inlinable public init(integerLiteral value: IntegerLiteralType) { index = value }
    }
}

extension TreeMap: Equatable where V: Equatable {
    @inlinable public static func == (lhs: TreeMap<K, V>, rhs: TreeMap<K, V>) -> Bool {
        if lhs === rhs { return true }
        if lhs.count != rhs.count { return true }

    }
}

extension TreeMap: Hashable where V: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) {
        guard let r = treeRoot else { return }
        r.forEach { n, _ in
            hasher.combine(n.item.key)
            hasher.combine(n.item.value)
        }
    }

}
