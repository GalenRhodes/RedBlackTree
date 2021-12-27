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

public class TreeMap<Key, Value>: ExpressibleByDictionaryLiteral where Key: Hashable & Comparable {

    @usableFromInline var treeRoot: Node<T>? = nil

    public let startIndex: Index = 0

    public required init() {}

    public required convenience init(dictionaryLiteral elements: (Key, Value)...) {
        self.init()
        elements.forEach { k, v in self[k] = v }
    }

    public required convenience init(from decoder: Decoder) throws where Key: Codable, Value: Codable {
        self.init()
        var c = try decoder.unkeyedContainer()
        while !c.isAtEnd {
            let t: T = try c.decode(T.self)
            treeRoot = ((treeRoot == nil) ? Node<T>(item: t) : treeRoot!.insert(item: t))
        }
    }
}

extension TreeMap {

    @inlinable public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        guard let v = self[key] else { return defaultValue() }
        return v
    }

    @inlinable public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> TreeMap<Key, T> {
        let t = TreeMap<Key, T>()
        try forEach { (e: Element) in t[e.key] = try transform(e.value) }
        return t
    }

    @inlinable public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> TreeMap<Key, T> {
        let t = TreeMap<Key, T>()
        try forEach { (e: Element) in if let v = try transform(e.value) { t[e.key] = v } }
        return t
    }

    @inlinable public func updateValue(_ value: Value, forKey key: Key) -> Value? {
        let o = self[key]
        self[key] = value
        return o
    }

    @inlinable public func merge<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S: Sequence, S.Element == (Key, Value) {}

    @inlinable public func merge(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {}

    @inlinable public func merging<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> [Key: Value] where S: Sequence, S.Element == (Key, Value) {}

    @inlinable public func merging(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> [Key: Value] {}

    @inlinable public func remove(at index: Dictionary<Key, Value>.Index) -> Dictionary<Key, Value>.Element {}

    @inlinable public func removeValue(forKey key: Key) -> Value? {}

    @inlinable public func removeAll(keepingCapacity keepCapacity: Bool = false) {}

    @inlinable public convenience init<S>(uniqueKeysWithValues keysAndValues: S) where S: Sequence, S.Element == (Key, Value) {
        self.init()
        keysAndValues.forEach { e in self[e.0] = e.1 }
    }

    @inlinable public convenience init<S>(_ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S: Sequence, S.Element == (Key, Value) {
        self.init()
        try keysAndValues.forEach { e in
            if let v = self[e.0] {
                self[e.0] = try combine(v, e.1)
            }
            else {
                self[e.0] = e.1
            }
        }
    }

    @inlinable public convenience init<S>(grouping values: S, by keyForValue: (S.Element) throws -> Key) rethrows where Value == [S.Element], S: Sequence {
        self.init()
        try values.forEach { v in
            let k = try keyForValue(v)
            if var vv: [S.Element] = self[k] {
                vv.append(v)
            }
            else {
                var vv: [S.Element] = []
                vv.append(v)
                self[k] = vv
            }
        }
    }

    @inlinable public func forEach(_ body: (Key, Value) throws -> Void) rethrows {
        guard let r = treeRoot else { return }
        try r.forEach { n, _ in try body(n.item.key, n.item.value) }
    }

    @inlinable func forEach(_ body: (Key, Value, inout Bool) throws -> Void) rethrows -> Bool {
        guard let r = treeRoot else { return false }
        return try r.forEach { n, f in try body(n.item.key, n.item.value, &f) }
    }

    @inlinable public subscript(key: Key) -> Value? {
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
        @usableFromInline let key:   Key
        @usableFromInline var value: Value

        @inlinable init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }

        @inlinable func hash(into hasher: inout Hasher) { hasher.combine(key) }

        @inlinable static func < (lhs: T, rhs: T) -> Bool { lhs.key < rhs.key }

        @inlinable static func == (lhs: T, rhs: T) -> Bool { lhs.key == rhs.key }
    }
}

extension TreeMap.T: Codable where Key: Codable, Value: Codable {
    @usableFromInline enum CodingKeys: CodingKey { case Key, Value }

    @inlinable init(from decoder: Decoder) throws {
        let c: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        key = try c.decode(Key.self, forKey: CodingKeys.Key)
        value = try c.decode(Value.self, forKey: CodingKeys.Value)
    }

    @inlinable func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(key, forKey: .Key)
        try c.encode(value, forKey: .Value)
    }
}

extension TreeMap: BidirectionalCollection {
    public typealias Element = (key: Key, value: Value)

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

extension TreeMap: Equatable where Value: Equatable {
    @inlinable public static func == (lhs: TreeMap<Key, Value>, rhs: TreeMap<Key, Value>) -> Bool {
        guard lhs !== rhs else { return true }
        guard lhs.count == rhs.count else { return false }
        return !lhs.forEach { k, v, f in f = (rhs[k] != v) }
    }
}

extension TreeMap: Hashable where Value: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) {
        guard let r = treeRoot else { return }
        r.forEach { n, _ in
            hasher.combine(n.item.key)
            hasher.combine(n.item.value)
        }
    }
}

extension TreeMap: Encodable where Key: Codable, Value: Codable {
    public func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        try forEach { (k: Key, v: Value) in try c.encode(T(key: k, value: v)) }
    }
}
