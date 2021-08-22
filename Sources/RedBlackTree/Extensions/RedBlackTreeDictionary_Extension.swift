/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: RedBlackTreeDictionary_Extension.swift
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
    public typealias CombineLambda = (Value, Value) throws -> Value
    public typealias SequenceElement = (Key, Value)

    //@f:0
    @inlinable public var endIndex: Index { Index(index: count)    }
    @inlinable public var isEmpty:  Bool  { (count == 0)           }
    //@f:1

    @inlinable public func index(after i: Index) -> Index {
        guard i >= startIndex && i < endIndex else { fatalError("Index out of bounds.") }
        return (i + 1)
    }

    @inlinable public func index(before i: Index) -> Index {
        guard i > startIndex && i <= endIndex else { fatalError("Index out of bounds.") }
        return (i - 1)
    }

    @inlinable public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        guard let v = self[key] else { return defaultValue() }
        return v
    }
//@f:0
    @inlinable public subscript(key: Key) -> Value? {
        get { _getValue(forKey: key) }
        set { if let v = newValue { updateValue(v, forKey: key) } else { removeValue(forKey: key) } }
    }
//@f:1
    @inlinable public convenience init(_ other: RedBlackTreeDictionary<Key, Value>) {
        self.init()
        for e in other { updateValue(e.1, forKey: e.0) }
    }

    @inlinable public convenience init<S>(_ other: S) where S: Sequence, S.Element == SequenceElement {
        self.init()
        for e: SequenceElement in other { updateValue(e.1, forKey: e.0) }
    }

    @inlinable public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> RedBlackTreeDictionary<Key, T> {
        let copy = RedBlackTreeDictionary<Key, T>()
        for e in self { copy[e.0] = try transform(e.1) }
        return copy
    }

    @inlinable public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> RedBlackTreeDictionary<Key, T> {
        let copy = RedBlackTreeDictionary<Key, T>()
        for e in self { if let v = try transform(e.1) { copy[e.0] = v } }
        return copy
    }

    @inlinable public func merge<S>(_ other: S, uniquingKeysWith combine: CombineLambda) rethrows where S: Sequence, S.Element == SequenceElement {
        try _merge(copy: self, other: other, uniquingKeysWith: combine)
    }

    @inlinable public func merge(_ other: RedBlackTreeDictionary<Key, Value>, uniquingKeysWith combine: CombineLambda) rethrows {
        try _merge(copy: self, other: other, uniquingKeysWith: combine)
    }

    @inlinable public func merging<S>(_ other: S, uniquingKeysWith combine: CombineLambda) rethrows -> RedBlackTreeDictionary<Key, Value> where S: Sequence, S.Element == SequenceElement {
        let copy = RedBlackTreeDictionary<Key, Value>(self)
        try _merge(copy: copy, other: other, uniquingKeysWith: combine)
        return copy
    }

    @inlinable public func merging(_ other: RedBlackTreeDictionary<Key, Value>, uniquingKeysWith combine: CombineLambda) rethrows -> RedBlackTreeDictionary<Key, Value> {
        let copy = RedBlackTreeDictionary<Key, Value>(self)
        try _merge(copy: copy, other: other, uniquingKeysWith: combine)
        return copy
    }

    @inlinable func _merge<S>(copy: RedBlackTreeDictionary<Key, Value>, other: S, uniquingKeysWith combine: CombineLambda) rethrows where S: Sequence, S.Element == SequenceElement {
        for e: SequenceElement in other {
            if let v = copy[e.0] { copy.updateValue(try combine(v, e.1), forKey: e.0) }
            else { copy.updateValue(e.1, forKey: e.0) }
        }
    }

    @inlinable func _merge(copy: RedBlackTreeDictionary<Key, Value>, other: RedBlackTreeDictionary<Key, Value>, uniquingKeysWith combine: CombineLambda) rethrows {
        for e in other {
            if let v = copy[e.0] { copy.updateValue(try combine(v, e.1), forKey: e.0) }
            else { copy.updateValue(e.1, forKey: e.0) }
        }
    }

    @inlinable public func forEach(_ body: (Element) throws -> Void) rethrows { try forEach(reverse: false, body) }

    @inlinable public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? { try _first(reverse: false, where: predicate) }

    @inlinable public func last(where predicate: (Element) throws -> Bool) rethrows -> Element? { try _first(reverse: true, where: predicate) }
}