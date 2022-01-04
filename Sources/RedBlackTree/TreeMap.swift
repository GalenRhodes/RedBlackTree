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

public class TreeMap<K, V>: BidirectionalCollection, ExpressibleByDictionaryLiteral where K: Hashable & Comparable {
    //@f:0
    public            typealias Element = (key: K, value: V)
    public            typealias Map     = TreeMap<K, V>
    @usableFromInline typealias N       = Node<Item>

    /// I know it's a performance hit to do locking but binary trees do NOT recover well
    /// from concurrent updates. Bad things happen. So we will do locking so that we can
    /// use this class concurrently without having to worry about loosing data.
    @usableFromInline      let lock:     NSRecursiveLock = NSRecursiveLock()

    /// And since we're doing locking we might as well take advantage of multiple threads
    /// to make some tasks faster. For example, with multiple CPUs you can split the tree
    /// in half to do searches as long as you're not depending on the order.
    @usableFromInline lazy var queue:    DispatchQueue   = DispatchQueue(label: UUID().uuidString, qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem)

    /// The root of our tree.
    @usableFromInline      var treeRoot: N?              = nil

    public let capacity:   Int    = Int.max
    public let startIndex: Index  = 0
    //@f:1

    public required init() {}

    public required convenience init(dictionaryLiteral elements: (K, V)...) {
        self.init()
        elements.forEach { k, v in _set(value: v, forKey: k) }
    }

    public required convenience init(from decoder: Decoder) throws where K: Codable, V: Codable {
        self.init()
        var c = try decoder.unkeyedContainer()
        while !c.isAtEnd { _insert(item: try c.decode(Item.self)) }
    }
}

extension TreeMap {
    //@f:0
    @inlinable public var endIndex:   Index   { Index(count)                                                                   }
    @inlinable public var count:      Int     { lock.withLock { unwrap(treeRoot, def: 0) { (r: N) in r.count } }               }
    @inlinable public var isEmpty:    Bool    { lock.withLock { treeRoot == nil }                                              }
    @inlinable public var keys:       Keys    { Keys(map: self)                                                                }
    @inlinable public var values:     Values  { Values(map: self)                                                              }
    @inlinable public var first:      Element { preconditionNotNil(treeRoot?.farLeftNode,  ERR_MSG_OUT_OF_BOUNDS).item.element }
    @inlinable public var last:       Element { preconditionNotNil(treeRoot?.farRightNode, ERR_MSG_OUT_OF_BOUNDS).item.element }
    //@f:1

    @inlinable public convenience init(_ other: Map) {
        self.init()
        other.lock.withLock { if let r = other.treeRoot { treeRoot = N(node: r) } }
    }

    @inlinable public convenience init<S>(uniqueKeysWithValues keysAndValues: S) where S: Sequence, S.Element == (K, V) {
        self.init()
        keysAndValues.forEach { (e: (K, V)) in _set(value: e.1, forKey: e.0) }
    }

    @inlinable public convenience init<S>(_ keysAndValues: S, uniquingKeysWith combine: (V, V) throws -> V) rethrows where S: Sequence, S.Element == (K, V) {
        self.init()
        try keysAndValues.forEach { (e: (K, V)) in
            if let v = _value(forKey: e.0) { _set(value: try combine(v, e.1), forKey: e.0) }
            else { _set(value: e.1, forKey: e.0) }
        }
    }

    @inlinable public convenience init<S>(grouping values: S, by keyForValue: (S.Element) throws -> K) rethrows where V == [S.Element], S: Sequence {
        self.init()
        try values.forEach { (e: S.Element) in
            let k = try keyForValue(e)
            if var v: [S.Element] = _value(forKey: k) { v.append(e) }
            else { _set(value: [ e ], forKey: k) }
        }
    }

    @inlinable public convenience init(_unsafeUninitializedCapacity capacity: Int,
                                       allowingDuplicates: Bool,
                                       initializingWith initializer: (_ keys: UnsafeMutableBufferPointer<K>, _ values: UnsafeMutableBufferPointer<V>) -> Int) {
        self.init()
    }

    @inlinable public subscript(key: K, default defaultValue: @autoclosure () -> V) -> V {
        lock.withLock { _value(forKey: key) ?? defaultValue() }
    }

    @inlinable public subscript(key: K) -> V? {
        get { lock.withLock { _value(forKey: key) } }
        set { lock.withLock { _set(value: newValue, forKey: key) } }
    }

    @inlinable public subscript(position: Index) -> Element {
        lock.withLock { _node(at: position).item.element }
    }

    @inlinable public func mapValues<O>(_ transform: (V) throws -> O) rethrows -> TreeMap<K, O> {
        try _withNew { t in try forEach { t[$0.key] = try transform($0.value) } }
    }

    @inlinable public func compactMapValues<O>(_ transform: (V) throws -> O?) rethrows -> TreeMap<K, O> {
        try _withNew { t in try forEach { if let v = try transform($0.value) { t[$0.key] = v } } }
    }

    @inlinable @discardableResult public func updateValue(_ value: V, forKey key: K) -> V? {
        lock.withLock { _set(value: value, forKey: key) }
    }

    @inlinable public func merge<S>(_ other: S, uniquingKeysWith combine: (V, V) throws -> V) rethrows where S: Sequence, S.Element == (K, V) {
        try lock.withLock { try other.forEach { (e: S.Element) in try _combine(e, combine) } }
    }

    @inlinable public func merge(_ other: [K: V], uniquingKeysWith combine: (V, V) throws -> V) rethrows {
        try lock.withLock { try other.forEach { try _combine($0, combine) } }
    }

    @inlinable public func merge(_ other: Map, uniquingKeysWith combine: (V, V) throws -> V) rethrows {
        try lock.withLock { try other.forEach { try _combine($0, combine) } }
    }

    @inlinable public func merging<S>(_ other: S, uniquingKeysWith combine: (V, V) throws -> V) rethrows -> Map where S: Sequence, S.Element == (K, V) {
        try _withCopy { try $0.merge(other, uniquingKeysWith: combine) }
    }

    @inlinable public func merging(_ other: [K: V], uniquingKeysWith combine: (V, V) throws -> V) rethrows -> Map {
        try _withCopy { try $0.merge(other, uniquingKeysWith: combine) }
    }

    @inlinable public func merging(_ other: Map, uniquingKeysWith combine: (V, V) throws -> V) rethrows -> Map {
        try _withCopy { try $0.merge(other, uniquingKeysWith: combine) }
    }

    @inlinable public func remove(at index: Index) -> Element {
        lock.withLock { _remove(node: _node(at: index)).element }
    }

    @inlinable public func removeValue(forKey key: K) -> V? {
        lock.withLock { _remove(forKey: key) }
    }

    @inlinable public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        lock.withLock { unwrap(treeRoot) { (r: N) in treeRoot = nil; queue.async { r.removeAll() } } }
    }

    @inlinable public func forEach(_ body: (Element) throws -> Void) rethrows {
        try lock.withLock { try _forEach { e, _ in try body(e) } }
    }

    @inlinable public func popFirst() -> Element? {
        lock.withLock { unwrap(treeRoot, def: nil) { (r: N) in _remove(node: r.farLeftNode).element } }
    }

    @inlinable public func reserveCapacity(_ minimumCapacity: Int) {}

    @inlinable public func makeIterator() -> Iterator {
        lock.withLock { Iterator(map: self) }
    }

    @inlinable public func index(after i: Index) -> Index {
        precondition(i < endIndex, ERR_MSG_OUT_OF_BOUNDS)
        return i.advanced(by: 1)
    }

    @inlinable public func index(before i: Index) -> Index {
        precondition(i > startIndex, ERR_MSG_OUT_OF_BOUNDS)
        return i.advanced(by: -1)
    }

    @frozen public struct Index: Hashable, Strideable, ExpressibleByIntegerLiteral {
        public typealias Stride = Int

        @usableFromInline let index: Int

        @inlinable init(_ index: Int) { self.index = index }

        @inlinable public init(integerLiteral value: IntegerLiteralType) { index = value }

        @inlinable public func distance(to other: Index) -> Stride { (other.index - index) }

        @inlinable public func advanced(by n: Stride) -> Index { Index((index + n)) }

        @inlinable public func hash(into hasher: inout Hasher) { hasher.combine(index) }

        @inlinable public static func < (lhs: Index, rhs: Index) -> Bool { (lhs.index < rhs.index) }

        @inlinable public static func <= (lhs: Index, rhs: Index) -> Bool { ((lhs < rhs) || (lhs == rhs)) }

        @inlinable public static func >= (lhs: Index, rhs: Index) -> Bool { !(lhs < rhs) }

        @inlinable public static func > (lhs: Index, rhs: Index) -> Bool { !(lhs <= rhs) }

        @inlinable public static func == (lhs: Index, rhs: Index) -> Bool { (lhs.index == rhs.index) }
    }

    @frozen public struct Iterator: IteratorProtocol {
        public typealias Element = Map.Element

        @usableFromInline var stack: [N] = []

        @usableFromInline init(map: Map) {
            prime(node: map.treeRoot)
        }

        @inlinable mutating func prime(node n: N?) {
            var n = n
            while let node = n {
                stack.append(node)
                n = node.leftNode
            }
        }

        @inlinable public mutating func next() -> Element? {
            guard let n = stack.popLast() else { return nil }
            prime(node: n.rightNode)
            return n.item.element
        }
    }

    @frozen public struct Keys: BidirectionalCollection, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
        //@f:0
        public typealias Index   = Map.Index
        public typealias Element = K
        public typealias Indices = DefaultIndices<Map.Keys>

        @inlinable public  var startIndex:       Index  { map.startIndex }
        @inlinable public  var endIndex:         Index  { map.endIndex }
        @inlinable public  var description:      String { "TreeMap.keys [ \(componentsJoined(with: "\", \"")) ]" }
        @inlinable public  var debugDescription: String { description }
        @inlinable public  var count:            Int    { map.count }
        @inlinable public  var isEmpty:          Bool   { map.isEmpty }
        @usableFromInline  let map:              Map
        //@f:1

        @inlinable init(map: Map) { self.map = map }

        @inlinable public subscript(position: Index) -> K { map[position].key }

        @inlinable public func index(after i: Index) -> Index { map.index(after: i) }

        @inlinable public func index(before i: Index) -> Index { map.index(before: i) }

        @inlinable public func formIndex(after i: inout Index) { map.formIndex(after: &i) }

        @inlinable public func formIndex(before i: inout Index) { map.formIndex(before: &i) }

        @inlinable public func hash(into hasher: inout Hasher) { forEach { hasher.combine($0) } }

        @inlinable public static func == (lhs: Map.Keys, rhs: Map.Keys) -> Bool {
            guard lhs.count == rhs.count else { return false }
            for i in (lhs.startIndex ..< lhs.endIndex) { guard lhs[i] == rhs[i] else { return false } }
            return true
        }
    }

    @frozen public struct Values: MutableCollection, BidirectionalCollection, CustomStringConvertible, CustomDebugStringConvertible {
        //@f:0
        public typealias Indices = DefaultIndices<Map.Values>
        public typealias Element = V
        public typealias Index   = Map.Index

        @inlinable public  var startIndex:       Index  { map.startIndex }
        @inlinable public  var endIndex:         Index  { map.endIndex }
        @inlinable public  var description:      String { "TreeMap.values [ \(componentsJoined(with: "\", \"")) ]" }
        @inlinable public  var debugDescription: String { description }
        @inlinable public  var count:            Int    { map.count }
        @inlinable public  var isEmpty:          Bool   { map.isEmpty }
        @usableFromInline  let map:              Map
        //@f:1

        @inlinable init(map: Map) { self.map = map }

        @inlinable public subscript(position: TreeMap<K, V>.Map.Index) -> V {
            get { map[position].value }
            set(newValue) { map.updateValue(newValue, forKey: map[position].key) }
        }

        @inlinable public func index(after i: Index) -> Index { map.index(after: i) }

        @inlinable public func index(before i: Index) -> Index { map.index(before: i) }

        @inlinable public func formIndex(after i: inout Index) { map.formIndex(after: &i) }

        @inlinable public func formIndex(before i: inout Index) { map.formIndex(before: &i) }

        @inlinable public mutating func swapAt(_ i: Index, _ j: Index) {
            let a = map[i]
            let b = map[j]
            map.updateValue(b.value, forKey: a.key)
            map.updateValue(a.value, forKey: b.key)
        }
    }
}

extension TreeMap {
    @usableFromInline class Item: Hashable, Comparable {
        @usableFromInline let key:   K
        @usableFromInline var value: V

        @usableFromInline init(key: K, value: V) {
            self.key = key
            self.value = value
        }

        @usableFromInline required init(from decoder: Decoder) throws where K: Codable, V: Codable {
            let c: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
            key = try c.decode(K.self, forKey: CodingKeys.Key)
            value = try c.decode(V.self, forKey: CodingKeys.Value)
        }
    }

    @inlinable func _forEach(_ body: (Element, inout Bool) throws -> Void) rethrows -> Bool {
        try _forEachItem { i, f in try body(i.element, &f) }
    }

    @inlinable func _forEachItem(_ body: (Item, inout Bool) throws -> Void) rethrows -> Bool {
        try unwrap(treeRoot, def: false) { (r: N) in try r.forEach { n, f in try body(n.item, &f) } }
    }

    @inlinable func _combine(_ e: Element, _ c: (V, V) throws -> V) rethrows {
        _set(value: try _resolve(old: _value(forKey: e.key), new: e.value, c), forKey: e.key)
    }

    @inlinable func _resolve(old v1: V?, new v2: V, _ c: (V, V) throws -> V) rethrows -> V {
        unwrap(v1, def: v2) { (v1: V) in try c(v1, v2) }
    }

    @inlinable func _node(at i: Index) -> Node<Item> {
        preconditionNotNil(preconditionNotNil(treeRoot, ERR_MSG_OUT_OF_BOUNDS)[i.index], ERR_MSG_OUT_OF_BOUNDS)
    }

    @inlinable func _node(forKey k: K) -> Node<Item>? {
        unwrap(treeRoot, def: nil) { (r: N) in r.find { k <=> $0.item.key } }
    }

    @inlinable func _item(forKey k: K) -> Item? {
        unwrap(_node(forKey: k), def: nil) { (n: N) in n.item }
    }

    @inlinable func _value(forKey k: K) -> V? {
        unwrap(_item(forKey: k), def: nil) { (i: Item) in i.value }
    }

    @inlinable @discardableResult func _set(value v: V?, forKey k: K) -> V? {
        unwrap(v, def: _remove(forKey: k)) { (v: V) in _insertOrReplace(value: v, forKey: k) }
    }

    @inlinable func _insertOrReplace(value v: V, forKey k: K) -> V? {
        unwrap(_node(forKey: k), def: _insert(value: v, forKey: k)) { (n: N) in _replace(value: v, inNode: n) }
    }

    @inlinable func _remove(forKey k: K) -> V? {
        unwrap(_node(forKey: k), def: nil) { (n: N) in _remove(node: n).value }
    }

    @inlinable func _remove(node n: N) -> Item {
        treeRoot = n.remove()
        return n.item
    }

    @inlinable func _insert(value v: V, forKey k: K) -> V? {
        _insert(item: Item(key: k, value: v))
        return nil
    }

    @inlinable func _insert(item i: Item) {
        treeRoot = unwrap(treeRoot, def: N(item: i)) { (r: N) in r.insert(item: i) }
    }

    @inlinable func _replace(value v: V, inNode n: N) -> V {
        let ov = n.item.value
        n.item.value = v
        return ov
    }

    @inlinable func _withNew<O>(_ body: (TreeMap<K, O>) throws -> Void) rethrows -> TreeMap<K, O> {
        let m = TreeMap<K, O>()
        try body(m)
        return m
    }

    @inlinable func _withCopy(_ body: (Map) throws -> Void) rethrows -> Map {
        let t = Map(self)
        try body(t)
        return t
    }
}

extension TreeMap.Values: Equatable where V: Equatable {
    @inlinable public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for i in (lhs.startIndex ..< lhs.endIndex) { guard lhs[i] == rhs[i] else { return false } }
        return true
    }
}

extension TreeMap.Values: Hashable where V: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) { forEach { hasher.combine($0) } }
}

extension TreeMap.Item {
    @inlinable var element: TreeMap.Element { (key, value) }

    @inlinable func hash(into hasher: inout Hasher) { hasher.combine(key) }

    @inlinable static func < (lhs: TreeMap.Item, rhs: TreeMap.Item) -> Bool { lhs.key < rhs.key }

    @inlinable static func == (lhs: TreeMap.Item, rhs: TreeMap.Item) -> Bool { lhs.key == rhs.key }
}

extension TreeMap.Item: Codable where K: Codable, V: Codable {
    @usableFromInline enum CodingKeys: CodingKey { case Key, Value }

    @inlinable func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(key, forKey: .Key)
        try c.encode(value, forKey: .Value)
    }
}

extension TreeMap: Equatable where V: Equatable {
    @inlinable public static func == (l: Map, r: Map) -> Bool { ((l === r) || ((l.count == r.count) && !l._forEach({ $1 = ($0.value != r[$0.key]) }))) }
}

extension TreeMap: Hashable where V: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) {
        forEach { key, value in
            hasher.combine(key)
            hasher.combine(value)
        }
    }
}

extension TreeMap: Encodable where K: Codable, V: Codable {
    @inlinable public func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        try forEach { key, value in try c.encode(Item(key: key, value: value)) }
    }
}

extension TreeMap: @unchecked Sendable where K: Sendable, V: Sendable {}

extension TreeMap.Item: @unchecked Sendable where K: Sendable, V: Sendable {}

extension TreeMap.Iterator: @unchecked Sendable where K: Sendable, V: Sendable {}

extension TreeMap.Index: @unchecked Sendable where K: Sendable, V: Sendable {}

extension TreeMap.Keys: @unchecked Sendable where K: Sendable, V: Sendable {}

extension TreeMap.Values: @unchecked Sendable where K: Sendable, V: Sendable {}
