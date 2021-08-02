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

open class TreeDictionary<Key, Value>: ExpressibleByDictionaryLiteral, BidirectionalCollection, Sequence where Key: Comparable & Hashable {
    public typealias Element = (key: Key, value: Value)

    //@f:0
    public            let startIndex: Index                 = Index(index: 0)
    public            var endIndex:   Index                 { Index(index: count)    }
    public            var isEmpty:    Bool                  { (rootNode == nil)      }
    public            var count:      Int                   { (rootNode?.count ?? 0) }
    @usableFromInline var rootNode:   TreeNode<Key, Value>? = nil
    //@f:1

    public init() {}

    public init(dictionary: [Key: Value]) {
        for e in dictionary {
            if let r = rootNode {
                rootNode = r.insertNode(key: e.key, value: e.value)
            }
            else {
                rootNode = TreeNode(key: e.key, value: e.value, color: .Black)
            }
        }
    }

    public required convenience init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(elements: elements)
    }

    public init(elements: [(Key, Value)]) {
        for (key, value) in elements {
            if let r = rootNode {
                rootNode = r.insertNode(key: key, value: value)
            }
            else {
                rootNode = TreeNode<Key, Value>(key: key, value: value, color: .Black)
            }
        }
    }

    public subscript(position: Index) -> (key: Key, value: Value) {
        guard let root = rootNode else { fatalError("Index out of bounds.") }
        let n = root.find(index: position.index)
        return (key: n.key, value: n.value)
    }

    public func distance(from start: Index, to end: Index) -> Int { (end.index - start.index) }

    public func index(after i: Index) -> Index { Index(index: (i.index + 1)) }

    public func index(before i: Index) -> Index { Index(index: (i.index - 1)) }

    public subscript(key: Key) -> Value? {
        get {
            guard let r = rootNode, let n = r[key] else { return nil }
            return n.value
        }
        set {
            if let r = rootNode {
                if let v = newValue {
                    rootNode = r.insertNode(key: key, value: v)
                }
                else if let n = r[key] {
                    rootNode = n.removeNode()
                }
            }
            else if let v = newValue {
                rootNode = TreeNode<Key, Value>(key: key, value: v, color: .Black)
            }
        }
    }

    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        guard let v = self[key] else { return defaultValue() }
        return v
    }

    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> [Key: T] {
        var out: [Key: T] = [:]
        if let r = rootNode { try r.forEach { node in out[node.key] = try transform(node.value) } }
        return out
    }

    @frozen public struct Index: Comparable, Hashable {
        let index: Int

        public static func < (lhs: Index, rhs: Index) -> Bool { (lhs.index < rhs.index) }

        public static func == (lhs: Index, rhs: Index) -> Bool { (lhs.index == rhs.index) }

        public func hash(into hasher: inout Hasher) { hasher.combine(index) }
    }
}

extension TreeDictionary: Equatable where Key: Equatable, Value: Equatable {

    @inlinable public static func == (lhs: TreeDictionary<Key, Value>, rhs: TreeDictionary<Key, Value>) -> Bool {
        if lhs === rhs { return true }
        guard lhs.count == rhs.count else { return false }
        guard lhs.count > 0 else { return true }
        for (key, value) in lhs { guard let n = rhs[key], value == n else { return false } }
        return true
    }
}

extension TreeDictionary: Hashable where Value: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        guard let r = rootNode else { return }
        r.forEach { node in
            hasher.combine(node.key)
            hasher.combine(node.value)
        }
    }
}

