/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: Other.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 04, 2021
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

extension TreeDictionary {

    @inlinable public func randomElement<T>(using generator: inout T) -> Element? where T: RandomNumberGenerator { self[Index(index: Int.random(in: 0 ..< count, using: &generator))] }

    @inlinable public func randomElement() -> Element? { randomElement(using: &random) }

    @inlinable public func merge(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where Key: Hashable {
        try lock.withLock { try other.forEach { try _combine($0, combine: combine) } }
    }

    @inlinable public func merge<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S: Sequence, S.Element == (Key, Value) {
        try lock.withLock { try other.forEach { try _combine((key: $0.0, value: $0.1), combine: combine) } }
    }

    @inlinable public func merge(_ other: TreeDictionary<Key, Value>, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        try lock.withLock { try other.forEach { try _combine($0, combine: combine) } }
    }

    @inlinable public func merging(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> TreeDictionary<Key, Value> where Key: Hashable {
        try lock.withLock {
            let tree = TreeDictionary<Key, Value>(treeDictionary: self)
            try tree.merge(other, uniquingKeysWith: combine)
            return tree
        }
    }

    @inlinable public func merging<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> TreeDictionary<Key, Value> where S: Sequence, S.Element == (Key, Value) {
        try lock.withLock {
            let tree = TreeDictionary<Key, Value>(treeDictionary: self)
            try tree.merge(other, uniquingKeysWith: combine)
            return tree
        }
    }

    /*==========================================================================================================*/
    /// Returns a new tree dictionary containing the key-value pairs of this tree dictionary that satisfy the
    /// given predicate.
    /// 
    /// - Parameter isIncluded: A closure that takes a key-value pair as its argument and returns a Boolean value
    ///                         indicating whether the pair should be included in the returned dictionary.
    /// - Returns: A tree dictionary of the key-value pairs that isIncluded allows.
    /// - Throws: Any error thrown by the closure.
    ///
    @inlinable public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> TreeDictionary<Key, Value> {
        try lock.withLock {
            let tree = TreeDictionary<Key, Value>()
            try _forEach { if try isIncluded($0) { _update($0) } }
            return tree
        }
    }

    /*==========================================================================================================*/
    /// Returns a Boolean value indicating whether the sequence contains an element that satisfies the given
    /// predicate.
    /// 
    /// You can use the predicate to check for an element of a type that doesn’t conform to the Equatable
    /// protocol, such as the HTTPResponse enumeration in this example.
    /// 
    /// ```
    /// enum HTTPResponse {
    ///     case ok
    ///     case error(Int)
    /// }
    /// 
    /// let lastThreeResponses: [HTTPResponse] = [.ok, .ok, .error(404)]
    /// let hadError = lastThreeResponses.contains { element in
    ///     if case .error = element {
    ///         return true
    ///     } else {
    ///         return false
    ///     }
    /// }
    /// // 'hadError' == true
    /// ```
    /// 
    /// Alternatively, a predicate can be satisfied by a range of Equatable elements or a general condition. This
    /// example shows how you can check an array for an expense greater than $100.
    /// 
    /// ```
    /// let expenses = [21.37, 55.21, 9.32, 10.18, 388.77, 11.41]
    /// let hasBigPurchase = expenses.contains { $0 > 100 }
    /// // 'hasBigPurchase' == true
    /// ```
    /// 
    /// Complexity: O(n), where n is the length of the sequence.
    /// 
    /// - Parameter predicate: A closure that takes an element of the sequence as its argument and returns a
    ///                        Boolean value that indicates whether the passed element represents a match.
    /// - Returns: `true` if the sequence contains an element that satisfies predicate; otherwise, `false`.
    /// - Throws: Any error thrown by the closure.
    ///
    @inlinable public func contains(where predicate: (Element) throws -> Bool) rethrows -> Bool {
        try lock.withLock {
            guard let _ = try _firstNode(where: { try predicate($0.data)}) else { return false }
            return true
        }
    }

    /*==========================================================================================================*/
    /// Returns a Boolean value indicating whether every element of a sequence satisfies a given predicate.
    /// 
    /// The following code uses this method to test whether all the names in an array have at least five
    /// characters:
    /// 
    /// ```
    /// let names = ["Sofia", "Camilla", "Martina", "Mateo", "Nicolás"]
    /// let allHaveAtLeastFive = names.allSatisfy({ $0.count >= 5 })
    /// // allHaveAtLeastFive == true
    /// ```
    /// 
    /// If the sequence is empty, this method returns `true`.
    /// 
    /// Complexity: O(n), where n is the length of the sequence.
    /// 
    /// - Parameter predicate: A closure that takes an element of the sequence as its argument and returns a
    ///                        Boolean value that indicates whether the passed element satisfies a condition.
    /// - Returns: `true` if the sequence contains only elements that satisfy predicate; otherwise, `false`.
    /// - Throws: Any error thrown by the closure.
    ///
    @inlinable public func allSatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        try lock.withLock {
            guard let _ = try _firstNode(where: { try !predicate($0.data) }) else { return true }
            return false
        }
    }

    /*==========================================================================================================*/
    /// Returns the first element of the sequence that satisfies the given predicate.
    /// 
    /// The following example uses the first(where:) method to find the first negative number in an array of
    /// integers:
    /// 
    /// ```
    /// let numbers = [3, 7, 4, -2, 9, -6, 10, 1]
    /// if let firstNegative = numbers.first(where: { $0 < 0 }) {
    ///     print("The first negative number is \(firstNegative).")
    /// }
    /// // Prints "The first negative number is -2."
    /// ```
    /// 
    /// Complexity: O(n), where n is the length of the sequence.
    /// 
    /// - Parameter predicate: A closure that takes an element of the sequence as its argument and returns a
    ///                        Boolean value indicating whether the element is a match.
    /// - Returns: The first element of the sequence that satisfies predicate, or nil if there is no element that
    ///            satisfies predicate.
    /// - Throws: Any error thrown by the closure.
    ///
    @inlinable public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        try lock.withLock {
            guard let n = try _firstNode(where: { node in try predicate(node.data) }) else { return nil }
            return n.data
        }
    }

    @inlinable public func firstIndex(where predicate: (Element) throws -> Bool) rethrows -> Index? {
        try lock.withLock {
            guard let n = try _firstNode(where: { node in try predicate(node.data) }) else { return nil }
            return Index(index: n.index)
        }
    }

    @inlinable @warn_unqualified_access public func min(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Element? {
        try lock.withLock {
            var minElem: Element? = nil
            try _forEach {
                if let e = minElem { if try areInIncreasingOrder($0, e) { minElem = $0 } }
                else { minElem = $0 }
            }
            return minElem
        }
    }

    @inlinable @warn_unqualified_access public func max(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Element? {
        try lock.withLock {
            var maxElem: Element? = nil
            try _forEach {
                if let e = maxElem { if try areInIncreasingOrder(e, $0) { maxElem = $0 } }
                else { maxElem = $0 }
            }
            return maxElem
        }
    }

    /*==========================================================================================================*/
    /// Returns a new dictionary containing the keys of this dictionary with the values transformed by the given
    /// closure.
    /// 
    /// Complexity: O(n), where n is the length of the dictionary.
    /// 
    /// - Parameter transform: A closure that transforms a value. transform accepts each value of the dictionary
    ///                        as its parameter and returns a transformed value of the same or of a different
    ///                        type.
    /// - Returns: A dictionary containing the keys and transformed values of this dictionary.
    /// - Throws: Any error thrown by the closure.
    ///
    @inlinable public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> [Key: T] {
        var out: [Key: T] = [:]
        try forEach { e in out[e.key] = try transform(e.value) }
        return out
    }

    @inlinable public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        var out: [T] = []
        try forEach { out.append(try transform($0)) }
        return out
    }

    @inlinable public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Element) throws -> Result) rethrows -> Result {
        var accum: Result = initialResult
        try forEach { accum = try nextPartialResult(accum, $0) }
        return accum
    }

    @inlinable public func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Element) throws -> ()) rethrows -> Result {
        var accum: Result = initialResult
        try forEach { try updateAccumulatingResult(&accum, $0) }
        return accum
    }

    @inlinable public func compactMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        var out: [ElementOfResult] = []
        try forEach { if let r = try transform($0) { out.append(r) } }
        return out
    }

    @inlinable public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> TreeDictionary<Key, T> {
        let tree = TreeDictionary<Key, T>()
        try forEach { if let v = try transform($0.value) { tree[$0.key] = v } }
        return tree
    }

    @inlinable public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> [Key: T] {
        var out: [Key:T] = [:]
        try forEach { if let v = try transform($0.value) { out[$0.key] = v } }
        return out
    }

    @inlinable public func sorted(by: (Element, Element) throws -> Bool) rethrows -> [Element] {
        var out: [Element] = map { $0 }
        try out.sort(by: by)
        return out
    }

    @inlinable public func shuffled() -> [Element] {
        var out: [Element] = map { $0 }
        out.shuffle()
        return out
    }

    @inlinable public func shuffled<T>(using generator: inout T) -> [Element] where T: RandomNumberGenerator {
        var out: [Element] = map { $0 }
        out.shuffle(using: &generator)
        return out
    }

    @inlinable public var underestimatedCount: Int { count }

    /*==========================================================================================================*/
    /// Tree dictionaries are not suitable for this method as the nodes are not stored in contiguous memory. As
    /// such this method simply returns nil without calling the clousre.
    /// 
    /// - Parameter body: The closure to call.
    /// - Returns: The value returned by the closure.
    /// - Throws: Any error thrown by the closure.
    ///
    @inlinable public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? { nil }
}
