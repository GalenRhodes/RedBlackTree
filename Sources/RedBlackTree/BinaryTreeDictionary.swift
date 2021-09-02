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

public class BinaryTreeDictionary<Key, Value>: BidirectionalCollection, ExpressibleByDictionaryLiteral where Key: Comparable {
    public typealias Element = (key: Key, value: Value)
    public typealias Index = TreeIndex

    @usableFromInline let base: TreeBase<KV>

    /*==========================================================================================================*/
    /// Designated Initializer.
    /// 
    /// - Parameters:
    ///   - c: If `true` then the dictionary will be thread safe.
    ///   - o: If `true` the the order the items are inserted into the tree will be remembered.
    ///   - a: The array of instances of KV to populate the tree with.
    ///
    @usableFromInline init(concurrent c: Bool, trackInsertOrder o: Bool, _ a: [KV]) { base = (c ? ConcurrentTreeBase<KV>(trackInsertOrder: o, a) : TreeBase<KV>(trackInsertOrder: o, a)) }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary with the data from the provided binary tree dictionary.
    /// 
    /// - Parameter other: the binary tree dictionary to copy the data from.
    ///
    public init(_ other: BinaryTreeDictionary<Key, Value>) { base = other.base.copy() }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary with the data decoded from the decoder.
    /// 
    /// - Parameter decoder: the decoder.
    /// - Throws: if a decoding error occurs.
    ///
    public required init(from decoder: Decoder) throws where Key: Decodable, Value: Decodable {
        let container  = try decoder.container(keyedBy: TreeBase<KV>.CodingKeys.self)
        let concurrent = (try container.decodeIfPresent(Bool.self, forKey: .concurrent) ?? false)
        base = (concurrent ? try ConcurrentTreeBase<KV>(from: container) : try TreeBase<KV>(from: container))
    }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary with the given elements provided as a dictionary literal.
    /// 
    /// - Parameter elements: the elements.
    ///
    public convenience required init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(concurrent: false, trackInsertOrder: false, elements.map { KV(key: $0.0, value: $0.1) })
    }
}

extension BinaryTreeDictionary {
    //@f:0
    @inlinable public var firstInInsertOrder: Element? { base.startNode?.element }
    @inlinable public var lastInInsertOrder:  Element? { base.endNode?.element   }
    @inlinable public var insertOrder:        InOrder  { InOrder(base: base)     }
    @inlinable public var first:              Element? { base.startNode?.element }
    @inlinable public var last:               Element? { base.endNode?.element   }
    @inlinable public var startIndex:         Index    { base.startIndex         }
    @inlinable public var endIndex:           Index    { base.endIndex           }
    @inlinable public var count:              Int      { base.count              }
    //@f:1

    /*==========================================================================================================*/
    /// Create a new empty binary tree dictionary.
    ///
    @inlinable public convenience init() { self.init(concurrent: false, trackInsertOrder: false, []) }

    /*==========================================================================================================*/
    /// Create a new empty binary tree dictionary.
    /// 
    /// - Parameter c: If `true` then the dictionary will be thread safe.
    ///
    @inlinable public convenience init(concurrent c: Bool) { self.init(concurrent: c, trackInsertOrder: false, []) }

    /*==========================================================================================================*/
    /// Create a new empty binary tree dictionary.
    /// 
    /// - Parameters:
    ///   - c: If `true` then the dictionary will be thread safe.
    ///   - o: If `true` the the order the items are inserted into the tree will be remembered.
    ///
    @inlinable public convenience init(concurrent c: Bool = false, trackInsertOrder o: Bool) { self.init(concurrent: c, trackInsertOrder: o, []) }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary from the given sequence of elements.
    /// 
    /// - Parameters:
    ///   - c: If `true` then the dictionary will be thread safe.
    ///   - o: If `true` the the order the items are inserted into the tree will be remembered.
    ///   - s: The sequence of elements.
    ///
    @inlinable public convenience init<S>(concurrent c: Bool = false, trackInsertOrder o: Bool = false, _ s: S) where S: Sequence, S.Element == Element {
        self.init(concurrent: c, trackInsertOrder: o, s.map { KV(key: $0.key, value: $0.value) })
    }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary from the elements in the given
    /// <code>[Dictionary](https://developer.apple.com/documentation/swift/Dictionary)</code>.
    /// 
    /// - Parameters:
    ///   - c: If `true` then the dictionary will be thread safe.
    ///   - o: If `true` the the order the items are inserted into the tree will be remembered.
    ///   - d: The dictionary containing the keys and values to be put into this tree.
    ///
    @inlinable public convenience init(concurrent c: Bool = false, trackInsertOrder o: Bool = false, _ d: [Key: Value]) where Key: Hashable {
        self.init(concurrent: c, trackInsertOrder: o, d.map { KV(key: $0.key, value: $0.value) })
    }

    /*==========================================================================================================*/
    /// A collection containing just the keys of the dictionary.
    /// 
    /// When iterated over, keys appear in this collection in the same order as they occur in the dictionary’s
    /// key-value pairs. Each key in the keys collection has a unique value.
    /// 
    /// ```
    /// let countryCodes: BinaryTreeDictionary<String, String> = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
    /// print(countryCodes)
    /// // Prints "["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]"
    /// 
    /// for k in countryCodes.keys {
    ///     print(k)
    /// }
    /// // Prints "BR"
    /// // Prints "GH"
    /// // Prints "JP"
    /// ```
    ///
    @inlinable public var keys:       Keys { Keys(self) }

    /*==========================================================================================================*/
    /// A collection containing just the values of the dictionary.
    /// 
    /// When iterated over, values appear in this collection in the same order as they occur in the dictionary’s
    /// key-value pairs.
    /// 
    /// ```
    /// let countryCodes: BinaryTreeDictionary<String, String> = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
    /// print(countryCodes)
    /// // Prints "["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]"
    /// 
    /// for v in countryCodes.values {
    ///     print(v)
    /// }
    /// // Prints "Brazil"
    /// // Prints "Ghana"
    /// // Prints "Japan"
    /// ```
    ///
    @inlinable public var values:     Values { Values(self) }

    /*==========================================================================================================*/
    /// Returns the index for the given key.
    /// 
    /// If the given key is found in the dictionary, this method returns an index into the dictionary that
    /// corresponds with the key-value pair.
    /// 
    /// ```
    /// let countryCodes: BinaryTreeDictionary<String, String> = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
    /// let index = countryCodes.index(forKey: "JP")
    /// 
    /// print("Country code for \(countryCodes[index!].value): '\(countryCodes[index!].key)'.")
    /// // Prints "Country code for Japan: 'JP'."
    /// ```
    /// 
    /// - Parameter key: The key to find in the dictionary.
    /// - Returns: The index for key and its associated value if key is in the dictionary; otherwise, nil.
    ///
    @inlinable public func index(forKey key: Key) -> Index? {
        guard let n = base.searchNode(compareWith: { compare(a: key, b: $0.key) }) else { return nil }
        return n.index
    }

    @inlinable public func index(after i: Index) -> Index { base.index(after: i) }

    @inlinable public func index(before i: Index) -> Index { base.index(before: i) }

    /*==========================================================================================================*/
    /// Accesses the key-value pair at the specified position.
    /// 
    /// This subscript takes an index into the dictionary, instead of a key, and returns the corresponding
    /// key-value pair as a tuple. When performing collection-based operations that return an index into a
    /// dictionary, use this subscript with the resulting value. For example, to find the key for a particular
    /// value in a dictionary, use the firstIndex(where:) method.
    /// ```
    /// let countryCodes: BinaryTreeDictionary<String, String> = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
    /// if let index = countryCodes.firstIndex(where: { $0.value == "Japan" }) {
    ///     print(countryCodes[index])
    ///     print("Japan's country code is '\(countryCodes[index].key)'.")
    /// } else {
    ///     print("Didn't find 'Japan' as a value in the dictionary.")
    /// }
    /// // Prints "(key: "JP", value: "Japan")"
    /// // Prints "Japan's country code is 'JP'."
    /// ```
    /// 
    /// - Parameter position: The position of the key-value pair to access. `position` must be a valid index of
    ///                       the dictionary and not equal to `endIndex`.
    /// - Returns: A two-element tuple with the key and value corresponding to `position`.
    /// - Complexity: O(log n), where n is the number of key-value pairs in the dictionary.
    ///
    @inlinable public subscript(position: Index) -> Element { base[position].element }

    /*==========================================================================================================*/
    /// Not available. Returns `nil`.
    /// 
    /// - Parameter body: Ignored.
    /// - Returns: `nil`
    /// - Throws: Never.
    ///
    @inlinable public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? { nil }

    /*==========================================================================================================*/
    /// Returns an iterator over the dictionary’s key-value pairs.
    /// 
    /// Iterating over a dictionary yields the key-value pairs as two-element tuples. You can decompose the tuple
    /// in a for-in loop, which calls makeIterator() behind the scenes, or when calling the iterator’s next()
    /// method directly.
    /// 
    /// ```
    /// let hues: BinaryTreeDictionary<String, Int> = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    /// for (name, hueValue) in hues {
    ///     print("The hue of \(name) is \(hueValue).")
    /// }
    /// // Prints "The hue of Heliotrope is 296."
    /// // Prints "The hue of Coral is 16."
    /// // Prints "The hue of Aquamarine is 156."
    /// ```
    /// 
    /// - Returns: An iterator over the dictionary with elements of type (key: Key, value: Value).
    ///
    @inlinable public func makeIterator() -> Iterator { Iterator(base.makeIterator()) }

    @inlinable public func makeInsertOrderIterator() -> InsertOrderIterator { InsertOrderIterator(base.makeInsertOrderIterator()) }

    @inlinable public func randomElement() -> Element? { self[Index(index: Int.random(in: startIndex.idx ..< endIndex.idx))] }

    @inlinable public func randomElement<T>(using generator: inout T) -> Element? where T: RandomNumberGenerator {
        self[Index(index: Int.random(in: startIndex.idx ..< endIndex.idx, using: &generator))]
    }

    /*==========================================================================================================*/
    /// Does nothing in a binary tree.
    /// 
    /// - Parameter minimumCapacity: ignored.
    ///
    @inlinable public func reserveCapacity(_ minimumCapacity: Int) {}

    @inlinable public func filter(fast: Bool = false, _ isIncluded: (Element) throws -> Bool) rethrows -> BinaryTreeDictionary<Key, Value> {
        let other = BinaryTreeDictionary<Key, Value>()
        if fast {
            let lock = NSRecursiveLock()
            try forEach(fast: fast) { e in if try isIncluded(e) { lock.withLock { other.updateValue(e.value, forKey: e.key) } } }
        }
        else {
            try forEach(fast: fast) { if try isIncluded($0) { other.updateValue($0.value, forKey: $0.key) } }
        }
        return other
    }

    @inlinable public func compactMapValues<T>(fast: Bool = false, _ transform: (Value) throws -> T?) rethrows -> BinaryTreeDictionary<Key, T> {
        let other = BinaryTreeDictionary<Key, T>()
        if fast {
            let lock = NSRecursiveLock()
            try forEach(fast: fast) { e in if let v = try transform(e.value) { lock.withLock { other.updateValue(v, forKey: e.key) } } }
        }
        else {
            try forEach(fast: fast) { if let v = try transform($0.value) { other.updateValue(v, forKey: $0.key) } }
        }
        return other
    }

    @inlinable public func mapValues<T>(fast: Bool = false, _ transform: (Value) throws -> T) rethrows -> BinaryTreeDictionary<Key, T> {
        let other = BinaryTreeDictionary<Key, T>()
        if fast {
            let lock = NSRecursiveLock()
            try forEach(fast: fast) { e in
                let v = try transform(e.value)
                lock.withLock { other.updateValue(v, forKey: e.key) }
            }
        }
        else {
            try forEach(fast: fast) { other.updateValue(try transform($0.value), forKey: $0.key) }
        }
        return other
    }

    @inlinable public func merge(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where Key: Hashable {
        try other.forEach { e in
            if let v = self[e.key] { updateValue(try combine(v, e.value), forKey: e.key) }
            else { updateValue(e.value, forKey: e.key) }
        }
    }

    @inlinable public func merge(fast: Bool = false, _ other: BinaryTreeDictionary<Key, Value>, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        if fast {
            let lock = NSRecursiveLock()
            try other.forEach(fast: fast) { key, value in
                if let v1 = lock.withLock({ self[key] }) {
                    let v2 = try combine(v1, value)
                    lock.withLock { updateValue(v2, forKey: key) }
                }
                else {
                    lock.withLock { updateValue(value, forKey: key) }
                }
            }
        }
        else {
            try other.forEach(fast: fast) { key, value in
                if let v = self[key] { updateValue(try combine(v, value), forKey: key) }
                else { updateValue(value, forKey: key) }
            }
        }
    }

    @inlinable public func merge<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S: Sequence, S.Element == Element {
        try other.forEach { e in
            if let v = self[e.key] { updateValue(try combine(v, e.value), forKey: e.key) }
            else { updateValue(e.value, forKey: e.key) }
        }
    }

    @inlinable public func merging(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> BinaryTreeDictionary<Key, Value> where Key: Hashable {
        let copy = BinaryTreeDictionary<Key, Value>(self)
        try copy.merge(other, uniquingKeysWith: combine)
        return copy
    }

    @inlinable public func merging(_ other: BinaryTreeDictionary<Key, Value>, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> BinaryTreeDictionary<Key, Value> {
        let copy = BinaryTreeDictionary<Key, Value>(self)
        try copy.merge(other, uniquingKeysWith: combine)
        return copy
    }

    @inlinable public func merging<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> BinaryTreeDictionary<Key, Value> where S: Sequence, S.Element == Element {
        let copy = BinaryTreeDictionary<Key, Value>(self)
        try copy.merge(other, uniquingKeysWith: combine)
        return copy
    }

    @inlinable public func forEach(fast: Bool = false, reverse: Bool = false, _ body: (Element) throws -> Void) rethrows {
        try base.forEach(fast: fast, reverse: reverse) { kv in try body(kv.element) }
    }

    /*==========================================================================================================*/
    /// Accesses the value associated with the given key for reading and writing.
    /// 
    /// This key-based subscript returns the value for the given key if the key is found in the dictionary, or nil
    /// if the key is not found. The following example creates a new dictionary and prints the value of a key
    /// found in the dictionary ("Coral") and a key not found in the dictionary ("Cerise").
    /// 
    /// ```
    /// var hues: BinaryTreeDictionary<String, Int> = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    /// print(hues["Coral"])
    /// // Prints "Optional(16)"
    /// print(hues["Cerise"])
    /// // Prints "nil"
    /// ```
    /// 
    /// When you assign a value for a key and that key already exists, the dictionary overwrites the existing
    /// value. If the dictionary doesn’t contain the key, the key and value are added as a new key-value pair.
    /// Here, the value for the key "Coral" is updated from 16 to 18 and a new key-value pair is added for the key
    /// "Cerise".
    /// 
    /// ```
    /// hues["Coral"] = 18
    /// print(hues["Coral"])
    /// // Prints "Optional(18)"
    /// 
    /// hues["Cerise"] = 330
    /// print(hues["Cerise"])
    /// // Prints "Optional(330)"
    /// ```
    /// 
    /// If you assign nil as the value for the given key, the dictionary removes that key and its associated
    /// value. In the following example, the key-value pair for the key "Aquamarine" is removed from the
    /// dictionary by assigning nil to the key-based subscript.
    /// 
    /// ```
    /// hues["Aquamarine"] = nil
    /// print(hues)
    /// // Prints "["Coral": 18, "Heliotrope": 296, "Cerise": 330]"
    /// ```
    /// 
    /// - Parameter key: The key to find in the dictionary.
    /// - Returns: The value associated with key if key is in the dictionary; otherwise, nil.
    /// - Complexity: O(log n), where n is the number of key-value pairs in the dictionary.
    ///
    @inlinable public subscript(key: Key) -> Value? {
        get {
            base.search(compareWith: { compare(a: key, b: $0.key) })?.value
        }
        set {
            if let v = newValue { updateValue(v, forKey: key) }
            else { removeValue(forKey: key) }
        }
    }

    /*==========================================================================================================*/
    /// Accesses the value with the given key. If the dictionary doesn’t contain the given key, accesses the
    /// provided default value as if the key and default value existed in the dictionary.
    /// 
    /// Use this subscript when you want either the value for a particular key or, when that key is not present in
    /// the dictionary, a default value. This example uses the subscript with a message to use in case an HTTP
    /// response code isn’t recognized:
    /// 
    /// ```
    /// var responseMessages: BinaryTreeDictionary<Int, String> = [200: "OK",
    ///                                                            403: "Access forbidden",
    ///                                                            404: "File not found",
    ///                                                            500: "Internal server error"]
    /// 
    /// let httpResponseCodes = [200, 403, 301]
    /// for code in httpResponseCodes {
    ///     let message = responseMessages[code, default: "Unknown response"]
    ///     print("Response \(code): \(message)")
    /// }
    /// // Prints "Response 200: OK"
    /// // Prints "Response 403: Access forbidden"
    /// // Prints "Response 301: Unknown response"
    /// ```
    /// 
    /// When a dictionary’s Value type has value semantics, you can use this subscript to perform in-place
    /// operations on values in the dictionary. The following example uses this subscript while counting the
    /// occurrences of each letter in a string:
    /// 
    /// ```
    /// let message = "Hello, Elle!"
    /// var letterCounts: BinaryTreeDictionary<Character, Int> = [:]
    /// for letter in message {
    ///     letterCounts[letter, default: 0] += 1
    /// }
    /// // letterCounts == ["H": 1, "e": 2, "l": 4, "o": 1, ...]
    /// ```
    /// 
    /// When letterCounts[letter, defaultValue: 0] += 1 is executed with a value of letter that isn’t already a
    /// key in letterCounts, the specified default value (0) is returned from the subscript, incremented, and then
    /// added to the dictionary under that key.
    /// 
    /// <blockquote> <b>Note</b> Do not use this subscript to modify dictionary values if the dictionary’s Value
    /// type is a class. In that case, the default value and key are not written back to the dictionary after an
    /// operation. </blockquote>
    /// 
    /// - Parameters:
    ///   - key: The `key` the look up in the dictionary.
    ///   - defaultValue: The default value to use if `key` doesn’t exist in the dictionary.
    /// - Returns: The value associated with `key` in the dictionary; otherwise, `defaultValue`.
    /// - Complexity: O(log n), where n is the number of key-value pairs in the dictionary.
    ///
    @inlinable public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            guard let kv = base.search(compareWith: { compare(a: key, b: $0.key) }) else { return defaultValue() }
            return kv.value
        }
        set {
            updateValue(newValue, forKey: key)
        }
    }

    /*==========================================================================================================*/
    /// Updates the value stored in the dictionary for the given key, or adds a new key-value pair if the key does
    /// not exist.
    /// 
    /// Use this method instead of key-based subscripting when you need to know whether the new value supplants
    /// the value of an existing key. If the value of an existing key is updated, updateValue(_:forKey:) returns
    /// the original value.
    /// 
    /// ```
    /// var hues: BinaryTreeDictionary<String, Int> = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    /// 
    /// if let oldValue = hues.updateValue(18, forKey: "Coral") {
    ///     print("The old value of \(oldValue) was replaced with a new one.")
    /// }
    /// // Prints "The old value of 16 was replaced with a new one."
    /// ```
    /// 
    /// If the given key is not present in the dictionary, this method adds the key-value pair and returns nil.
    /// 
    /// ```
    /// if let oldValue = hues.updateValue(330, forKey: "Cerise") {
    ///     print("The old value of \(oldValue) was replaced with a new one.")
    /// } else {
    ///     print("No value was found in the dictionary for that key.")
    /// }
    /// // Prints "No value was found in the dictionary for that key."
    /// ```
    /// 
    /// 
    /// - Parameters:
    ///   - value: The new `value` to add to the dictionary.
    ///   - key: The `key` to associate with `value`. If `key` already exists in the dictionary, `value` replaces
    ///          the existing associated `value`. If `key` isn’t already a `key` of the dictionary, the `(key,
    ///          value)` pair is added.
    /// - Returns: The value that was replaced, or nil if a new key-value pair was added.
    /// - Complexity: O(log n), where n is the number of key-value pairs in the dictionary.
    ///
    @inlinable @discardableResult public func updateValue(_ value: Value, forKey key: Key) -> Value? {
        base.insert(element: KV(key: key, value: value))?.value
    }

    /*==========================================================================================================*/
    /// Removes the given key and its associated value from the dictionary.
    /// 
    /// If the key is found in the dictionary, this method returns the key’s associated value. On removal, this
    /// method invalidates all indices with respect to the dictionary.
    /// 
    /// ```
    /// var hues: BinaryTreeDictionary<String, Int> = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    /// if let value = hues.removeValue(forKey: "Coral") {
    ///     print("The value \(value) was removed.")
    /// }
    /// // Prints "The value 16 was removed."
    /// ```
    /// 
    /// If the key isn’t found in the dictionary, removeValue(forKey:) returns nil.
    /// 
    /// ```
    /// if let value = hues.removeValue(forKey: "Cerise") {
    ///     print("The value \(value) was removed.")
    /// } else {
    ///     print("No value found for that key.")
    /// }
    /// // Prints "No value found for that key.""
    /// ```
    /// 
    /// - Parameter key: The key to remove along with its associated value.
    /// - Returns: The value that was removed, or nil if the key was not present in the dictionary.
    /// - Complexity: O(log n), where n is the number of key-value pairs in the dictionary.
    ///
    @inlinable @discardableResult public func removeValue(forKey key: Key) -> Value? {
        guard let n = base.searchNode(compareWith: { kv in compare(a: key, b: kv.key) }) else { return nil }
        return base.remove(node: n).value
    }

    /*==========================================================================================================*/
    /// Removes and returns the key-value pair at the specified index.
    /// 
    /// Calling this method invalidates any existing indices for use with this dictionary.
    /// 
    /// - Parameter index: The position of the key-value pair to remove. `index` must be a valid index of the
    ///                    dictionary, and must not equal the dictionary’s `endIndex`.
    /// - Returns: The key-value pair that correspond to index.
    /// - Complexity: O(log n), where n is the number of key-value pairs in the dictionary.
    ///
    @inlinable @discardableResult public func remove(at index: Index) -> Element { base.remove(node: base.node(forIndex: index)).element }

    /*==========================================================================================================*/
    /// Removes all key-value pairs from the dictionary.
    /// 
    /// - Parameter keepCapacity: Exists for compatibility with
    ///                           <code>[Dictionary](https://developer.apple.com/documentation/swift/Dictionary)</code>.
    ///                           Not applicable to a binary tree.
    /// - Complexity: O, the deallocation of the nodes happens on a background thread.
    ///
    @inlinable public func removeAll(keepingCapacity keepCapacity: Bool = false) { base.removeAll(fast: true) }

    @frozen public struct InsertOrderIterator: IteratorProtocol {
        @usableFromInline var baseIterator: TreeBase<KV>.InsertOrderIterator

        @inlinable init(_ baseIterator: TreeBase<KV>.InsertOrderIterator) { self.baseIterator = baseIterator }

        /*======================================================================================================*/
        /// Advances to the next element and returns it, or nil if no next element exists.
        /// 
        /// Once nil has been returned, all subsequent calls return nil.
        /// 
        /// - Returns: the next element or nil if there are no more elements.
        ///
        @inlinable public mutating func next() -> Element? { baseIterator.next()?.element }
    }

    /*==========================================================================================================*/
    /// An iterator over the members of a Dictionary<Key, Value>.
    ///
    @frozen public struct Iterator: IteratorProtocol {
        @usableFromInline var baseIterator: TreeBase<KV>.Iterator

        @inlinable init(_ baseIterator: TreeBase<KV>.Iterator) { self.baseIterator = baseIterator }

        /*======================================================================================================*/
        /// Advances to the next element and returns it, or nil if no next element exists.
        /// 
        /// Once nil has been returned, all subsequent calls return nil.
        /// 
        /// - Returns: the next element or nil if there are no more elements.
        ///
        @inlinable public mutating func next() -> Element? { baseIterator.next()?.element }
    }

    @frozen public struct InOrder: Sequence {
        @usableFromInline let _base: TreeBase<KV>

        @inlinable init(base: TreeBase<KV>) { self._base = base }

        @inlinable public func makeIterator() -> Iterator { Iterator(_base.makeInsertOrderIterator()) }

        @frozen public struct Iterator: IteratorProtocol {
            @usableFromInline var baseIterator: TreeBase<KV>.InsertOrderIterator

            @inlinable init(_ baseIterator: TreeBase<KV>.InsertOrderIterator) { self.baseIterator = baseIterator }

            @inlinable public mutating func next() -> Element? { baseIterator.next()?.element }
        }
    }

    @usableFromInline struct KV: Comparable {
        @usableFromInline enum CodingKeys: String, CodingKey { case key, value }

        @usableFromInline let key:     Key
        @usableFromInline var value:   Value
        @inlinable var        element: Element { (key: key, value: value) }

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

extension BinaryTreeDictionary {
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
