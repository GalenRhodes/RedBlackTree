/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: BinaryTreeDictionary.swift
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

public class BinaryTreeDictionary<Key, Value>: ExpressibleByDictionaryLiteral where Key: Comparable {
    public typealias Element = (Key, Value)
    public typealias Index = TreeIndex

    @usableFromInline var base: TreeBase<KV>

    public init() {
        base = TreeBase<KV>(trackOrder: false)
    }

    public init(trackOrder: Bool) {
        base = TreeBase<KV>(trackOrder: false)
    }

    public required init(from decoder: Decoder) throws where Key: Decodable, Value: Decodable {
        base = try TreeBase<KV>(from: decoder)
    }

    public required init(dictionaryLiteral elements: (Key, Value)...) {
        base = TreeBase<KV>(trackOrder: false)
        for (key, value) in elements { base.insert(element: KV(key: key, value: value)) }
    }

    public init<S>(trackOrder: Bool = false, _ sequence: S) where S: Sequence, S.Element == (Key, Value) {
        base = TreeBase<KV>(trackOrder: trackOrder)
        for (key, value) in sequence { base.insert(element: KV(key: key, value: value)) }
    }

    public init(_ other: BinaryTreeDictionary<Key, Value>) {
        base = TreeBase<KV>(other.base)
    }

    deinit { base.removeAll(fast: false) }
}

extension BinaryTreeDictionary {
    @inlinable public subscript(key: Key) -> Value? {
        get {
            base.search(compareWith: { compare(a: key, b: $0.key) })?.value
        }
        set {
            if let v = newValue { updateValue(v, forKey: key) }
            else { removeValue(forKey: key) }
        }
    }

    @inlinable public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            guard let kv = base.search(compareWith: { compare(a: key, b: $0.key) }) else { return defaultValue() }
            return kv.value
        }
        set {
            updateValue(newValue, forKey: key)
        }
    }

    @inlinable @discardableResult public func updateValue(_ value: Value, forKey key: Key) -> Value? {
        base.insert(element: KV(key: key, value: value))?.value
    }

    @inlinable @discardableResult public func removeValue(forKey key: Key) -> Value? {
        guard let n = base.searchNode(compareWith: { kv in compare(a: key, b: kv.key) }) else { return nil }
        return base.remove(node: n).value
    }

    @inlinable @discardableResult public func remove(at index: Index) -> Element {
        guard let n = base.rootNode?[index] else { fatalError("Index out of bounds.") }
        return base.remove(node: n).element
    }

    @inlinable public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        base.removeAll(fast: true)
    }

    @usableFromInline struct KV: Comparable {
        @usableFromInline enum CodingKeys: String, CodingKey { case key, value }

        @usableFromInline let key:     Key
        @usableFromInline var value:   Value
        @inlinable var        element: Element { (key, value) }

        @inlinable init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }

        @inlinable static func < (lhs: KV, rhs: KV) -> Bool { lhs.key < rhs.key }

        @inlinable static func == (lhs: KV, rhs: KV) -> Bool { lhs.key == rhs.key }
    }

    @frozen public struct Keys: BidirectionalCollection {
        public typealias Element = Key
        public typealias Index = TreeIndex

        @usableFromInline let tree: BinaryTreeDictionary<Key, Value>

        public var startIndex: Index { tree.startIndex }
        public var endIndex:   Index { tree.endIndex }
        public var count:      Int { tree.count }

        @inlinable init(_ tree: BinaryTreeDictionary<Key, Value>) { self.tree = tree }

        @inlinable public subscript(position: Index) -> Element { tree[position].0 }

        @inlinable public func index(before i: Index) -> Index { tree.index(before: i) }

        @inlinable public func index(after i: Index) -> Index { tree.index(after: i) }
    }

    @frozen public struct Values: BidirectionalCollection {
        public typealias Element = Value
        public typealias Index = TreeIndex

        @usableFromInline let tree: BinaryTreeDictionary<Key, Value>

        public var startIndex: Index { tree.startIndex }
        public var endIndex:   Index { tree.endIndex }
        public var count:      Int { tree.count }

        @inlinable init(_ tree: BinaryTreeDictionary<Key, Value>) { self.tree = tree }

        @inlinable public subscript(position: Index) -> Element { tree[position].1 }

        @inlinable public func index(before i: Index) -> Index { tree.index(before: i) }

        @inlinable public func index(after i: Index) -> Index { tree.index(after: i) }
    }
}

extension BinaryTreeDictionary.KV: Hashable where Key: Hashable, Value: Hashable {
    @inlinable func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(value)
    }
}

extension BinaryTreeDictionary.KV: Encodable where Key: Encodable, Value: Encodable {
    @inlinable func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(key, forKey: .key)
        try c.encode(value, forKey: .value)
    }
}

extension BinaryTreeDictionary.KV: Decodable where Key: Decodable, Value: Decodable {
    @inlinable init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = try c.decode(Key.self, forKey: .key)
        value = try c.decode(Value.self, forKey: .value)
    }
}

extension BinaryTreeDictionary: BidirectionalCollection {
    @inlinable public var startIndex: Index { base.startIndex }
    @inlinable public var endIndex:   Index { base.endIndex }
    @inlinable public var count:      Int { base.count }

    @inlinable public func index(forKey key: Key) -> Index? {
        guard let n = base.searchNode(compareWith: { compare(a: key, b: $0.key) }) else { return nil }
        return n.index
    }

    @inlinable public func index(after i: Index) -> Index { base.index(after: i) }

    @inlinable public func index(before i: Index) -> Index { base.index(before: i) }

    @inlinable public subscript(position: Index) -> (Key, Value) { base[position].element }

    @inlinable public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<(Key, Value)>) throws -> R) rethrows -> R? { nil }

    @inlinable public func makeIterator() -> Iterator { Iterator(base.makeIterator()) }

    @frozen public struct Iterator: IteratorProtocol {
        @usableFromInline var baseIterator: TreeBase<KV>.Iterator

        @inlinable init(_ baseIterator: TreeBase<KV>.Iterator) { self.baseIterator = baseIterator }

        @inlinable public mutating func next() -> Element? { baseIterator.next()?.element }
    }
}

extension BinaryTreeDictionary: Equatable where Value: Equatable {
    @inlinable public static func == (lhs: BinaryTreeDictionary<Key, Value>, rhs: BinaryTreeDictionary<Key, Value>) -> Bool {
        guard lhs.count == rhs.count else { return false }
        let ne = lhs.first { key, value in
            guard let other = rhs[key] else { return true }
            return (other != value)
        }
        return (ne == nil)
    }
}

extension BinaryTreeDictionary: Hashable where Key: Hashable, Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        base.forEach { hasher.combine($0) }
    }
}

extension BinaryTreeDictionary: Encodable where Key: Encodable, Value: Encodable {
    @inlinable public func encode(to encoder: Encoder) throws { try base.encode(to: encoder) }
}

extension BinaryTreeDictionary: Decodable where Key: Decodable, Value: Decodable {}

