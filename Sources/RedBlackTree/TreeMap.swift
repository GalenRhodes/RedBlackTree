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

    private(set) lazy var queue: DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem)

    typealias N = Node<T>
    public typealias Map = TreeMap<Key, Value>

    var treeRoot: N? = nil

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
            treeRoot = ((treeRoot == nil) ? N(item: t) : treeRoot!.insert(item: <#T##T##T#>))
        }
    }
}

extension TreeMap {
    public convenience init(_ other: Map) {
        self.init()
        if let r = other.treeRoot { treeRoot = N(node: r) }
    }

    public convenience init<S>(uniqueKeysWithValues keysAndValues: S) where S: Sequence, S.Element == (Key, Value) {
        self.init()
        keysAndValues.forEach { e in self[e.0] = e.1 }
    }

    public convenience init<S>(_ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S: Sequence, S.Element == (Key, Value) {
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

    public convenience init<S>(grouping values: S, by keyForValue: (S.Element) throws -> Key) rethrows where Value == [S.Element], S: Sequence {
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
}

extension TreeMap {
    func error(_ msg: @autoclosure () -> String = String()) { fatalError(msg()) }

    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value { self[key] ?? defaultValue() }

    public subscript(key: Key) -> Value? {
        get { treeRoot?.find(using: { key <=> $0.item.key })?.item.value }
        set {
            if let v = newValue {
                let t = T(key: key, value: v)
                treeRoot = ((treeRoot?.insert(item: t)) ?? N(item: t))
            }
            else if let n = treeRoot?.find(using: { key <=> $0.item.key }) {
                treeRoot = n.remove()
            }
        }
    }

    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> TreeMap<Key, T> {
        let t = TreeMap<Key, T>()
        try forEach { t[$0.key] = try transform($0.value) }
        return t
    }

    public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> TreeMap<Key, T> {
        let t = TreeMap<Key, T>()
        try forEach { if let v = try transform($0.value) { t[$0.key] = v } }
        return t
    }

    public func updateValue(_ value: Value, forKey key: Key) -> Value? {
        let v = self[key]
        self[key] = value
        return v
    }

    public func merge<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S: Sequence, S.Element == (Key, Value) {
        try other.forEach { (e: S.Element) in try self.combine(e, combine) }
    }

    public func merge(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        try other.forEach { try self.combine($0, combine) }
    }

    public func merge(_ other: Map, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        try other.forEach { try self.combine($0, combine) }
    }

    public func merging<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> Map where S: Sequence, S.Element == (Key, Value) {
        try withCopy { try $0.merge(other, uniquingKeysWith: combine) }
    }

    public func merging(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> Map {
        try withCopy { try $0.merge(other, uniquingKeysWith: combine) }
    }

    public func merging(_ other: Map, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> Map {
        try withCopy { try $0.merge(other, uniquingKeysWith: combine) }
    }

    public func remove(at index: Index) -> Element {
        guard let r = treeRoot, let n = r[index.index] else { error(ERR_MSG_OUT_OF_BOUNDS) }
        treeRoot = n.remove()
        return (key: n.item.key, value: n.item.value)
    }

    public func removeValue(forKey key: Key) -> Value? {
        guard let r = treeRoot, let n = r.find(using: { key <=> $0.item.key }) else { return nil }
        treeRoot = n.remove()
        return n.item.value
    }

    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        guard let r = treeRoot else { return }
        treeRoot = nil
        queue.async { r.removeAll() }
    }

    public func forEach(_ body: (Element) throws -> Void) rethrows {
        guard let r = treeRoot else { return }
        try r.forEach { n, _ in try body(n.item.element) }
    }

    func forEach(_ body: (Element, inout Bool) throws -> Void) rethrows -> Bool {
        guard let r = treeRoot else { return false }
        return try r.forEach { n, f in try body(n.item.element, &f) }
    }

    func withCopy(_ body: (Map) throws -> Void) rethrows -> Map {
        let t = Map(self)
        try body(t)
        return t
    }

    func combine(_ e: Element, _ body: (Value, Value) throws -> Value) throws {
        if let v0 = self[e.key] { self[e.key] = try body(v0, e.value) }
        else { self[e.key] = e.value }
    }

    struct T: Hashable, Comparable {
        let key:   Key
        var value: Value

        var element: Element { (key, value) }

        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }

        func hash(into hasher: inout Hasher) { hasher.combine(key) }

        static func < (lhs: T, rhs: T) -> Bool { lhs.key < rhs.key }

        static func == (lhs: T, rhs: T) -> Bool { lhs.key == rhs.key }
    }
}

extension TreeMap.T: Codable where Key: Codable, Value: Codable {
    enum CodingKeys: CodingKey { case Key, Value }

    init(from decoder: Decoder) throws {
        let c: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        key = try c.decode(Key.self, forKey: CodingKeys.Key)
        value = try c.decode(Value.self, forKey: CodingKeys.Value)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(key, forKey: .Key)
        try c.encode(value, forKey: .Value)
    }
}

extension TreeMap: BidirectionalCollection {
    public typealias Element = (key: Key, value: Value)

    public var endIndex: Index { Index(treeRoot?.count ?? 0) }

    public subscript(position: Index) -> Element {
        guard let r = treeRoot, let n = r[position.index] else { error(ERR_MSG_OUT_OF_BOUNDS) }
        return (key: n.item.key, value: n.item.value)
    }

    public func index(after i: Index) -> Index {
        guard i < endIndex else { error(ERR_MSG_OUT_OF_BOUNDS) }
        return i.advanced(by: 1)
    }

    public func index(before i: Index) -> Index {
        guard i > startIndex else { error(ERR_MSG_OUT_OF_BOUNDS) }
        return i.advanced(by: -1)
    }

    @frozen public struct Index: Hashable, Strideable, ExpressibleByIntegerLiteral {
        public typealias Stride = Int

        let index: Int

        init(_ index: Int) { self.index = index }

        public init(integerLiteral value: IntegerLiteralType) { index = value }

        public func distance(to other: Index) -> Stride { (other.index - index) }

        public func advanced(by n: Stride) -> Index { Index((index + n)) }

        public func hash(into hasher: inout Hasher) { hasher.combine(index) }

        public static func < (lhs: Index, rhs: Index) -> Bool { (lhs.index < rhs.index) }

        public static func <= (lhs: Index, rhs: Index) -> Bool { ((lhs < rhs) || (lhs == rhs)) }

        public static func >= (lhs: Index, rhs: Index) -> Bool { !(lhs < rhs) }

        public static func > (lhs: Index, rhs: Index) -> Bool { !(lhs <= rhs) }

        public static func == (lhs: Index, rhs: Index) -> Bool { (lhs.index == rhs.index) }
    }
}

extension TreeMap: Equatable where Value: Equatable {
    public static func == (l: Map, r: Map) -> Bool { ((l === r) || ((l.count == r.count) && !l.forEach({ $1 = ($0.value != r[$0.key]) }))) }
}

extension TreeMap: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
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
        try forEach { try c.encode(T(key: $0.key, value: $0.value)) }
    }
}
