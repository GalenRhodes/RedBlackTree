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

open class TreeDictionary<Key, Value>: ExpressibleByDictionaryLiteral, BidirectionalCollection, Sequence where Key: Comparable {
    public typealias Element = (key: Key, value: Value)

    //@f:0
    public            let capacity:   Int                   = Int.max
    public            let startIndex: Index                 = Index(index: 0)
    public            var endIndex:   Index                 { lock.withLock { Index(index: count) } }
    /// A Boolean value that indicates whether the dictionary is empty.
    ///
    /// Dictionaries are empty when created with an initializer or an empty dictionary literal.
    /// ```
    /// var frequencies: TreeDictionary<String, Int> = TreeDictionary()
    /// print(frequencies.isEmpty)
    /// // Prints "true"
    /// ```
    ///
    public            var isEmpty:    Bool                  { lock.withLock { (rootNode == nil) } }
    /// The number of key-value pairs in the dictionary.
    ///
    /// Complexity: O(1).
    ///
    public            var count:      Int                   { lock.withLock { (rootNode?.count ?? 0) } }

    @usableFromInline var rootNode:   TreeNode<Key, Value>? = nil
    @usableFromInline var descCache:  String?               = nil
    @usableFromInline let lock:       NSLocking             = NSRecursiveLock()
    @usableFromInline var changed:    Int                   = 0
    //@f:1

    /*==========================================================================================================*/
    /// Create a new, empty binary tree dictionary.
    ///
    public init() {}

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary with all the elements from this dictionary. It does not create a copy
    /// of the elements themselves. The original binary tree dictionary is left unchanged.
    ///
    /// - Parameter tree: The binary tree dictionary to take the elements from.
    ///
    public init(treeDictionary tree: TreeDictionary<Key, Value>) { tree.forEach { self[$0.key] = $0.value } }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary with the elements from the given hashable dictionary.
    ///
    /// - Parameter dictionary: The source dictionary.
    ///
    public init(dictionary: [Key: Value]) where Key: Hashable { for e in dictionary { self[e.key] = e.value } }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary with the elements given.
    ///
    /// - Parameter elements: The list of initial elements to put in the dictionary.
    ///
    public required convenience init(dictionaryLiteral elements: (Key, Value)...) { self.init(elements: elements) }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary with the elements given.
    ///
    /// - Parameter elements: The list of initial elements to put in the dictionary.
    ///
    public init(elements: [(Key, Value)]) { for (key, value) in elements { self[key] = value } }

    /*==========================================================================================================*/
    /// Accesses the key-value pair at the specified position.
    ///
    /// This subscript takes an index into the dictionary, instead of a key, and returns the corresponding
    /// key-value pair as a tuple. When performing collection-based operations that return an index into a
    /// dictionary, use this subscript with the resulting value.
    ///
    /// For example, to find the key for a particular value in a dictionary, use the firstIndex(where:) method.
    ///
    /// ```
    /// let countryCodes = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
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
    /// - Parameter position: The position of the key-value pair to access. position must be a valid index of the
    ///                       dictionary and not equal to `endIndex`.
    /// - Returns: A two-element tuple with the key and value corresponding to position.
    ///
    open subscript(position: Index) -> Element {
        lock.withLock {
            guard let root = rootNode else { fatalError("Index out of bounds.") }
            let n = root.node(forIndex: position.index)
            return (key: n.key, value: n.value)
        }
    }

    /*==========================================================================================================*/
    /// Accesses the value associated with the given key for reading and writing.
    ///
    /// This key-based subscript returns the value for the given key if the key is found in the dictionary, or nil
    /// if the key is not found.
    ///
    /// The following example creates a new dictionary and prints the value of a key found in the dictionary
    /// ("Coral") and a key not found in the dictionary ("Cerise").
    ///
    /// ```
    /// var hues = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    /// print(hues["Coral"])
    /// // Prints "Optional(16)"
    /// print(hues["Cerise"])
    /// // Prints "nil"
    /// ```
    ///
    /// When you assign a value for a key and that key already exists, the dictionary overwrites the existing
    /// value. If the dictionary doesn’t contain the key, the key and value are added as a new key-value pair.
    ///
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
    /// If you assign nil as the value for the given key, the dictionary removes that key and its associated value.
    ///
    /// In the following example, the key-value pair for the key "Aquamarine" is removed from the dictionary by
    /// assigning nil to the key-based subscript.
    ///
    /// ```
    /// hues["Aquamarine"] = nil
    /// print(hues)
    /// // Prints "["Coral": 18, "Heliotrope": 296, "Cerise": 330]"
    /// ```
    ///
    /// - Parameter key: The key to find in the dictionary.
    /// - Returns: The value associated with key if key is in the dictionary; otherwise, nil.
    ///
    open subscript(key: Key) -> Value? {
        get { lock.withLock { rootNode?[key]?.value } }
        set {
            lock.withLock {
                if let v = newValue { updateValue(v, forKey: key) }
                else { removeValue(forKey: key) }
            }
        }
    }

    /*==========================================================================================================*/
    /// Accesses the value with the given key, falling back to the given default value if the key isn’t found.
    ///
    /// Use this subscript when you want either the value for a particular key or, when that key is not present in
    /// the dictionary, a default value. This example uses the subscript with a message to use in case an HTTP
    /// response code isn’t recognized:
    ///
    /// ```
    /// var responseMessages = [200: "OK",
    ///                         403: "Access forbidden",
    ///                         404: "File not found",
    ///                         500: "Internal server error"]
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
    /// var letterCounts: [Character: Int] = [:]
    /// for letter in message {
    ///     letterCounts[letter, default: 0] += 1
    /// }
    /// // letterCounts == ["H": 1, "e": 2, "l": 4, "o": 1, ...]
    /// ```
    ///
    /// When letterCounts[letter, default: 0] += 1 is executed with a value of letter that isn’t already a key in
    /// letterCounts, the specified default value (0) is returned from the subscript, incremented, and then added
    /// to the dictionary under that key.
    ///
    /// > Note > Do not use this subscript to modify dictionary values if the dictionary’s Value type is a class.
    /// > In that case, the default value and key are not written back to the dictionary after an operation.
    ///
    /// - Parameters:
    ///   - key: The key the look up in the dictionary.
    ///   - defaultValue: The default value to use if key doesn’t exist in the dictionary.
    /// - Returns: The value associated with key in the dictionary; otherwise, `defaultValue`.
    ///
    open subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        lock.withLock {
            guard let v = self[key] else { return defaultValue() }
            return v
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
    open func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> [Key: T] {
        var out: [Key: T] = [:]
        try forEach { e in out[e.key] = try transform(e.value) }
        return out
    }

    open func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? {
        lock.withLock {
            guard let r = rootNode else { return try body(UnsafeBufferPointer<Element>(start: nil, count: 0)) }
            let cc  = r.count
            let ptr = UnsafeMutablePointer<Element>.allocate(capacity: cc)
            defer { ptr.deallocate() }

            var pIdx = 0
            r.forEach { node in
                if pIdx < cc {
                    (ptr + pIdx).initialize(to: (key: node.key, value: node.value))
                    pIdx += 1
                }
            }
            defer { ptr.deinitialize(count: pIdx) }

            return try body(UnsafeBufferPointer<Element>(start: ptr, count: pIdx))
        }
    }

    open func forEach(_ body: (Element) throws -> Void) rethrows {
        lock.withLock {
            guard let r = rootNode else { return }
            try r.forEach { node in try body((key: node.key, value: node.value)) }
        }
    }

    /*==========================================================================================================*/
    /// The position of a key-value pair in a dictionary.
    ///
    /// Dictionary has two subscripting interfaces:
    ///
    /// 1) Subscripting with a key, yielding an optional value:
    ///    ```
    ///    v = d[k]!
    ///    ```
    /// 2) Subscripting with an index, yielding a key-value pair:
    ///    ```
    ///    (k, v) = d[i]
    ///    ```
    ///
    @frozen public struct Index: Comparable, Hashable {
        @usableFromInline let index: Int

        @inlinable init(index: Int) { self.index = index }

        @inlinable public static func < (lhs: Index, rhs: Index) -> Bool { (lhs.index < rhs.index) }

        @inlinable public static func == (lhs: Index, rhs: Index) -> Bool { (lhs.index == rhs.index) }

        @inlinable public func hash(into hasher: inout Hasher) { hasher.combine(index) }
    }

    open func distance(from start: Index, to end: Index) -> Int { (end.index - start.index) }

    open func index(after i: Index) -> Index { index(i, offsetBy: 1) }

    open func index(before i: Index) -> Index { index(i, offsetBy: -1) }

    open func index(_ i: Index, offsetBy distance: Int) -> Index {
        let xi = (i.index + distance)
        guard xi >= startIndex.index && xi <= endIndex.index else { fatalError("Index out of bounds.") }
        return Index(index: xi)
    }

    open func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
        let _i = (i.index + distance)
        if distance < 0 { guard _i >= limit.index else { return nil } }
        else if distance > 0 { guard _i <= limit.index else { return nil } }
        return Index(index: _i)
    }

    /// I'm really blown away on the complete lack of information on how this class should act if the underlying Sequence is mutated. In Objective-C and Java such similar classes
    /// have a "fail-fast" model which halts the iteration if the underlying collection mutates. So, that is what we will do here.
    ///
    public struct Iterator: IteratorProtocol {
        @usableFromInline let tree:     TreeDictionary<Key, Value>
        @usableFromInline let changed:  Int
        @usableFromInline var nextNode: TreeNode<Key, Value>?

        @inlinable init(tree: TreeDictionary<Key, Value>) {
            self.tree = tree
            self.changed = tree.changed
            self.nextNode = tree.rootNode?.nextFalling
        }

        @inlinable public mutating func next() -> Element? {
            if tree.changed != changed { nextNode = nil }
            guard let node = nextNode else { return nil }
            nextNode = node.next
            return (key: node.key, value: node.value)
        }
    }

    open func makeIterator() -> Iterator { Iterator(tree: self) }

    open var first: Element? {
        lock.withLock {
            guard let r = rootNode else { return nil }
            let n = r.nextFalling
            return (key: n.key, value: n.value)
        }
    }

    open var last: Element? {
        lock.withLock {
            guard let r = rootNode else { return nil }
            let n = r.prevFalling
            return (key: n.key, value: n.value)
        }
    }

    open func reserveCapacity(_ minimumCapacity: Int) {}

    @discardableResult open func removeValue(forKey key: Key) -> Value? {
        lock.withLock {
            guard let node = rootNode?[key] else { return nil }
            let v = node.value
            rootNode = node.removeNode()
            descCache = nil
            return v
        }
    }

    open func removeAll(keepingCapacity: Bool = false) {
        lock.withLock {
            rootNode = nil
            descCache = "[]"
        }
    }

    @discardableResult open func remove(at index: Index) -> Element {
        lock.withLock {
            guard let root = rootNode else { fatalError("Index out of bounds.") }
            let node = root.node(forIndex: index.index)
            let elem = (key: node.key, value: node.value)
            rootNode = node.removeNode()
            descCache = nil
            return elem
        }
    }

    @discardableResult open func updateValue(_ value: Value, forKey key: Key) -> Value? {
        lock.withLock {
            var v: Value? = nil
            if let root = rootNode {
                if let node = root[key] {
                    v = node.value
                    node.value = value
                }
                else {
                    rootNode = rootNode?.insertNode(key: key, value: value)
                }
            }
            else {
                rootNode = TreeNode<Key, Value>(key: key, value: value, color: .Black)
            }
            descCache = nil
            return v
        }
    }
}

extension TreeDictionary: Equatable where Key: Equatable, Value: Equatable {

    @inlinable public static func == (lhs: TreeDictionary<Key, Value>, rhs: TreeDictionary<Key, Value>) -> Bool {
        if lhs === rhs { return true }
        return lhs.lock.withLock {
            rhs.lock.withLock {
                guard lhs.count == rhs.count else { return false }
                guard lhs.count > 0 else { return true }
                for (key, value) in lhs { guard let n = rhs[key], value == n else { return false } }
                return true
            }
        }
    }
}

extension TreeDictionary: Hashable where Key: Hashable, Value: Hashable {
    /// Hashes the essential components of this value by feeding them into the given hasher.Hashes the essential components of this value by feeding them into the given hasher.
    ///
    /// - Parameter hasher: The hasher.
    ///
    @inlinable public func hash(into hasher: inout Hasher) {
        lock.withLock {
            hasher.combine(count)
            guard let r = rootNode else { return }
            r.forEach { node in
                hasher.combine(node.key)
                hasher.combine(node.value)
            }
        }
    }
}

let d = Dictionary<String, String>()

extension TreeDictionary: CustomStringConvertible, CustomDebugStringConvertible {
    /// A string that represents the contents of the dictionary.
    ///
    @inlinable public var description: String {
        lock.withLock {
            if let d = descCache { return d }
            descCache = _description
            return descCache!
        }
    }

    /// A string that represents the contents of the dictionary, suitable for debugging.
    ///
    @inlinable public var debugDescription: String { description }

    @usableFromInline var _description: String {
        guard let root = rootNode else { return "[]" }
        var out: String = "[ "
        root.forEach { node in out.append("\"\(node.key)\": \"\(node.value)\", ") }
        return (out + "]")
    }
}
