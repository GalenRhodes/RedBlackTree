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
    public var endIndex: Index { Index(index: count)    }
    public var isEmpty:  Bool  { (count == 0)           }
    //@f:1

    public convenience init<S>(_ other: S) where S: Sequence, S.Element == SequenceElement {
        self.init()
        for e: SequenceElement in other { updateValue(e.1, forKey: e.0) }
    }

    @discardableResult public func remove(at index: Index) -> Element {
        let n = node(at: index)
        remove(node: n)
        return n.value.data
    }

    @discardableResult public func removeValue(forKey key: Key) -> Value? {
        guard let n = node(forKey: key) else { return nil }
        remove(node: n)
        return n.value.value
    }

    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        guard let v = self[key] else { return defaultValue() }
        return v
    }
//@f:0
    public subscript(key: Key) -> Value? {
        get { node(forKey: key)?.value.value }
        set { if let v = newValue { updateValue(v, forKey: key) } else { removeValue(forKey: key) } }
    }
//@f:1
    public func mapValues<T>(fast: Bool = false, _ transform: (Value) throws -> T) rethrows -> RedBlackTreeDictionary<Key, T> {
        let copy = RedBlackTreeDictionary<Key, T>()
        if fast { let lock = NSLock(); try _forEachFast { (key, value) in try lock.withLock { _ = copy.updateValue(try transform(value), forKey: key) } } }
        else { try forEach { (key, value) -> Void in copy.updateValue(try transform(value), forKey: key) } }
        return copy
    }

    public func compactMapValues<T>(fast: Bool = false, _ transform: (Value) throws -> T?) rethrows -> RedBlackTreeDictionary<Key, T> {
        let copy = RedBlackTreeDictionary<Key, T>()
        if fast { let lock = NSLock(); try _forEachFast { (key, value) in if let v = try transform(value) { lock.withLock { _ = copy.updateValue(v, forKey: key) } } } }
        else { try forEach { (key, value) in if let v = try transform(value) { copy.updateValue(v, forKey: key) } } }
        return copy
    }

    public func merge<S>(_ other: S, uniquingKeysWith combine: CombineLambda) rethrows where S: Sequence, S.Element == SequenceElement {
        try _merge(copy: self, other: other, uniquingKeysWith: combine)
    }

    public func merge(_ other: RedBlackTreeDictionary<Key, Value>, fast: Bool = false, uniquingKeysWith combine: CombineLambda) rethrows {
        try _merge(copy: self, other: other, fast: fast, uniquingKeysWith: combine)
    }

    public func merging<S>(_ other: S, uniquingKeysWith combine: CombineLambda) rethrows -> RedBlackTreeDictionary<Key, Value> where S: Sequence, S.Element == SequenceElement {
        let copy = RedBlackTreeDictionary<Key, Value>(self)
        try _merge(copy: copy, other: other, uniquingKeysWith: combine)
        return copy
    }

    public func merging(_ other: RedBlackTreeDictionary<Key, Value>, fast: Bool = false, uniquingKeysWith combine: CombineLambda) rethrows -> RedBlackTreeDictionary<Key, Value> {
        let copy = RedBlackTreeDictionary<Key, Value>(self)
        try _merge(copy: copy, other: other, fast: fast, uniquingKeysWith: combine)
        return copy
    }

    func _merge<S>(copy: RedBlackTreeDictionary<Key, Value>, other: S, uniquingKeysWith combine: CombineLambda) rethrows where S: Sequence, S.Element == SequenceElement {
        for e: SequenceElement in other {
            if let v = copy[e.0] { copy.updateValue(try combine(v, e.1), forKey: e.0) }
            else { copy.updateValue(e.1, forKey: e.0) }
        }
    }

    func _merge(copy: RedBlackTreeDictionary<Key, Value>, other: RedBlackTreeDictionary<Key, Value>, fast: Bool, uniquingKeysWith combine: CombineLambda) rethrows {
        if fast {
            let lock = NSLock()
            try _forEachFast { (key, value) in
                if let v = copy[key] { let vv = try combine(v, value); lock.withLock { copy.updateValue(vv, forKey: key) } }
                else { lock.withLock { copy.updateValue(value, forKey: key) } }
            }
        }
        else {
            try forEach { (key, value) -> Void in
                if let v = copy[key] { copy.updateValue(try combine(v, value), forKey: key) }
                else { copy.updateValue(value, forKey: key) }
            }
        }
    }

    public func forEach(_ body: (Element) throws -> Void) rethrows { try forEach(reverse: false, body) }

    public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? { try _first(reverse: false, where: predicate) }

    public func last(where predicate: (Element) throws -> Bool) rethrows -> Element? { try _first(reverse: true, where: predicate) }

    public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<(Key, Value)>) throws -> R) rethrows -> R? { nil }
}
