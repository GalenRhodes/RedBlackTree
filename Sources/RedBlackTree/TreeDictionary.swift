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
    public typealias Indices = DefaultIndices<TreeDictionary<Key, Value>>

    //@f:0
    /*==========================================================================================================*/
    /// Exists to provide compatability with
    /// <code>[Dictionary](https://developer.apple.com/documentation/swift/Dictionary)</code>. Always returns
    /// <code>[Int.max](https://developer.apple.com/documentation/swift/Int.max)</code>.
    ///
    public      let capacity:   Int      = Int.max
    /*==========================================================================================================*/
    /// The position of the first element in a nonempty collection.
    /// 
    /// If the collection is empty, startIndex is equal to endIndex.
    ///
    public      let startIndex: Index    = Index(index: 0)
    /*==========================================================================================================*/
    /// The collection’s “past the end” position—that is, the position one greater than the last valid subscript
    /// argument.
    /// 
    /// When you need a range that includes the last element of a collection, use the half-open range operator
    /// (..<) with endIndex. The ..< operator creates a range that doesn’t include the upper bound, so it’s always
    /// safe to use with endIndex. For example:
    /// 
    /// ```
    /// let numbers = [10, 20, 30, 40, 50]
    /// if let index = numbers.firstIndex(of: 30) {
    ///     print(numbers[index ..< numbers.endIndex])
    /// }
    /// // Prints "[30, 40, 50]"
    /// ```
    /// 
    /// If the collection is empty, endIndex is equal to startIndex.
    ///
    open        var endIndex:   Index    { lock.withLock { Index(index: count)    } }
    /*==========================================================================================================*/
    /// A Boolean value that indicates whether the dictionary is empty.
    /// 
    /// Dictionaries are empty when created with an initializer or an empty dictionary literal.
    /// ```
    /// var frequencies: TreeDictionary<String, Int> = TreeDictionary()
    /// print(frequencies.isEmpty)
    /// // Prints "true"
    /// ```
    ///
    open        var isEmpty:    Bool     { lock.withLock { (rootNode == nil)      } }
    /*==========================================================================================================*/
    /// The number of key-value pairs in the dictionary.
    /// 
    /// Complexity: O(1).
    ///
    open        var count:      Int      { lock.withLock { (rootNode?.count ?? 0) } }
    open        var first:      Element? { lock.withLock { rootNode?.first.data   } }
    open        var last:       Element? { lock.withLock { rootNode?.last.data    } }
    public lazy var keys:       Keys     = { Keys(tree: self)   }()
    public lazy var values:     Values   = { Values(tree: self) }()

    @usableFromInline let trackOrder: Bool
    @usableFromInline var listFirst:  LinkedListTreeNode<Key, Value>? = nil
    @usableFromInline var listLast:   LinkedListTreeNode<Key, Value>? = nil
    @usableFromInline var rootNode:   TreeNode<Key, Value>?           = nil
    var                   descCache:  String?                         = nil
    var                   changed:    Int                             = 0

    lazy var lock:     NSLocking                   = NSRecursiveLock()
    lazy var random:   SystemRandomNumberGenerator = SystemRandomNumberGenerator()
    //@f:1

    /*==========================================================================================================*/
    /// Create a new, empty binary tree dictionary.
    ///
    public init(trackOrder: Bool = false) { self.trackOrder = trackOrder }

    public required init(from decoder: Decoder) throws where Key: Codable, Value: Codable {
        let values: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        trackOrder = try values.decode(Bool.self, forKey: .trackOrder)
        var elems: UnkeyedDecodingContainer = try values.nestedUnkeyedContainer(forKey: .elements)

        while !elems.isAtEnd {
            let kv: KVPair = try elems.decode(KVPair.self)
            updateValue(kv.value, forKey: kv.key)
        }
    }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary with all the elements from this dictionary. It does not create a copy
    /// of the elements themselves. The original binary tree dictionary is left unchanged.
    /// 
    /// - Parameter tree: The binary tree dictionary to take the elements from.
    ///
    public init(treeDictionary tree: TreeDictionary<Key, Value>, trackOrder: Bool = false) {
        self.trackOrder = trackOrder
        tree.forEach { updateValue($0.value, forKey: $0.key) }
    }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary with the elements from the given hashable dictionary.
    /// 
    /// - Parameter dictionary: The source dictionary.
    ///
    public init(dictionary: [Key: Value], trackOrder: Bool = false) where Key: Hashable {
        self.trackOrder = trackOrder
        for e in dictionary { updateValue(e.value, forKey: e.key) }
    }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary with the elements given.
    /// 
    /// - Parameter elements: The list of initial elements to put in the dictionary.
    ///
    public required convenience init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(elements: elements, trackOrder: false)
    }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary with the elements given.
    /// 
    /// - Parameters:
    ///   - trackOrder: If `true` the tree dictionary will track the order in which the elements where put in the
    ///                 tree.
    ///   - elements: The list of initial elements to put in the dictionary.
    ///
    public convenience init(trackOrder: Bool, dictionaryLiteral elements: (Key, Value)...) {
        self.init(elements: elements, trackOrder: trackOrder)
    }

    /*==========================================================================================================*/
    /// Create a new binary tree dictionary with the elements given.
    /// 
    /// - Parameter elements: The list of initial elements to put in the dictionary.
    ///
    public init(elements: [(Key, Value)], trackOrder: Bool = false) {
        self.trackOrder = trackOrder
        for (key, value) in elements { updateValue(value, forKey: key) }
    }

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
    open subscript(position: Index) -> Element { lock.withLock { _getNode(forIndex: position).data } }

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
        //@f:0
        get { lock.withLock { _getValue(forKey: key) } }
        set { if let v = newValue { updateValue(v, forKey: key) } else { removeValue(forKey: key) } }
        //@f:1
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
            guard let v = _getValue(forKey: key) else { return defaultValue() }
            return v
        }
    }

    open func forEach(reverse: Bool = false, _ body: (Element) throws -> Void) rethrows { try lock.withLock { try _forEach(reverse: reverse, body: body) } }

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
        let index: Int

        init(index: Int) { self.index = index }

        public static func < (lhs: Index, rhs: Index) -> Bool { (lhs.index < rhs.index) }

        public static func == (lhs: Index, rhs: Index) -> Bool { (lhs.index == rhs.index) }

        public func hash(into hasher: inout Hasher) { hasher.combine(index) }
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

    open func index(forKey key: Key) -> Index? {
        lock.withLock {
            guard let r = rootNode, let n = r[key] else { return nil }
            return Index(index: n.index)
        }
    }

    /*==========================================================================================================*/
    /// I'm really blown away on the complete lack of information on how this class should act if the underlying
    /// Sequence is mutated. In Objective-C and Java such similar classes have a "fail-fast" model which halts the
    /// iteration if the underlying collection mutates. So, that is what we will do here.
    ///
    public struct Iterator: IteratorProtocol {
        let tree:     TreeDictionary<Key, Value>
        let changed:  Int
        var nextNode: TreeNode<Key, Value>?

        init(tree: TreeDictionary<Key, Value>) {
            self.tree = tree
            changed = tree.changed
            nextNode = tree.rootNode?.first
        }

        public mutating func next() -> Element? {
            tree.lock.withLock {
                if tree.changed != changed { nextNode = nil }
                guard let node = nextNode else { return nil }
                nextNode = node.next
                return node.data
            }
        }
    }

    open func makeIterator() -> Iterator { lock.withLock { Iterator(tree: self) } }

    open func reserveCapacity(_ minimumCapacity: Int) {}

    @discardableResult open func removeValue(forKey key: Key) -> Value? { lock.withLock { _removeValue(forKey: key) } }

    open func removeAll(keepingCapacity: Bool = false) {
        lock.withLock {
            if let r = rootNode {
                rootNode = nil
                r.removeAll()
                descCache = "[]"
                changed += 1
            }
        }
    }

    @discardableResult open func remove(at index: Index) -> Element { lock.withLock { _remove(at: index) } }

    @discardableResult open func updateValue(_ value: Value, forKey key: Key) -> Value? { lock.withLock { _update(value: value, forKey: key) } }
}

extension TreeDictionary: Equatable where Key: Equatable, Value: Equatable {

    public static func == (lhs: TreeDictionary<Key, Value>, rhs: TreeDictionary<Key, Value>) -> Bool { lhs.lock.withLock { rhs.lock.withLock { areEqual(lhs, rhs) } } }

    @inlinable static func areEqual(_ lhs: TreeDictionary<Key, Value>, _ rhs: TreeDictionary<Key, Value>) -> Bool {
        ((lhs === rhs) || ((lhs.count == rhs.count) && ((lhs.count == 0) || lhs._allSatisfy({ rhs[$0.key] == $0.value }))))
    }
}

extension TreeDictionary: Hashable where Key: Hashable, Value: Hashable {
    /*==========================================================================================================*/
    /// Hashes the essential components of this value by feeding them into the given hasher.Hashes the essential
    /// components of this value by feeding them into the given hasher.
    /// 
    /// - Parameter hasher: The hasher.
    ///
    public func hash(into hasher: inout Hasher) {
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

extension TreeDictionary: CustomStringConvertible, CustomDebugStringConvertible {
    /*==========================================================================================================*/
    /// A string that represents the contents of the dictionary.
    ///
    public var description: String {
        lock.withLock {
            if let d = descCache { return d }
            descCache = _description
            return descCache!
        }
    }

    /*==========================================================================================================*/
    /// A string that represents the contents of the dictionary, suitable for debugging.
    ///
    public var debugDescription: String { description }

    var _description: String {
        guard let root = rootNode else { return "[]" }
        var out: String = "[ "
        root.forEach { node in out.append("\"\(node.key)\": \"\(node.value)\", ") }
        return (out + "]")
    }
}

extension TreeDictionary: Codable where Key: Codable, Value: Codable {

    enum CodingKeys: String, CodingKey {
        case elements, trackOrder
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trackOrder, forKey: .trackOrder)
        var elems = container.nestedUnkeyedContainer(forKey: .elements)
        if trackOrder { try forEachInInsertOrder { e in try elems.encode(KVPair(key: e.key, value: e.value)) } }
        else { try forEach { e in try elems.encode(KVPair(key: e.key, value: e.value)) } }
    }

    struct KVPair: Codable {
        let key:   Key
        let value: Value
    }
}
