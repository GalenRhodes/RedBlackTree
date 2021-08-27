/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: RedBlackTreeDictionary.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 18, 2021
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

public class RedBlackTreeDictionary<Key, Value>: Collection, BidirectionalCollection, ExpressibleByDictionaryLiteral where Key: Comparable & Equatable {

    @usableFromInline enum CodingKeys: String, CodingKey {
        case trackOrder, elements
    }

    public typealias Element = (Key, Value)

    //@f:0
    public            var count:      Int             { (rootNode?.count ?? 0) }
    public            let startIndex: Index           = Index(index: 0)
    @usableFromInline var rootNode:   TreeNode<KV>?   = nil
    @usableFromInline var firstNode:  IOTreeNode<KV>? = nil
    @usableFromInline var lastNode:   IOTreeNode<KV>? = nil
    @usableFromInline let trackOrder: Bool
    //@f:1

    public init() { trackOrder = false }

    public init(trackOrder: Bool) { self.trackOrder = trackOrder }

    public convenience required init(dictionaryLiteral elements: SequenceElement...) { self.init(trackOrder: false, elements: elements) }

    public convenience init(trackOrder: Bool = false, elements: [SequenceElement]) {
        self.init(trackOrder: trackOrder)
        for e in elements { updateValue(e.1, forKey: e.0) }
    }

    public convenience required init(from decoder: Decoder) throws where Key: Decodable, Value: Decodable {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(trackOrder: try container.decode(Bool.self, forKey: .trackOrder))
        var elemList = try container.nestedUnkeyedContainer(forKey: .elements)
        while !elemList.isAtEnd {
            let e = try elemList.decode(KV.self)
            updateValue(e.value, forKey: e.key)
        }
    }

    public convenience init(trackOrder: Bool = false, _ other: RedBlackTreeDictionary<Key, Value>) {
        self.init(trackOrder: trackOrder)
        if let _other = (other as? ConcurrentRedBlackTreeDictionary<Key, Value>) { rootNode = _other.lock.withLock { _other.rootNode?.copyTree() } }
        else { rootNode = other.rootNode?.copyTree() }
    }

    deinit { removeAll() }

    /// Encode the tree.
    ///
    /// - Parameter encoder: the encoder.
    /// - Throws: if there was an error during encoding.
    ///
    public func encode(to encoder: Encoder) throws where Key: Encodable, Value: Encodable {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(trackOrder, forKey: .trackOrder)
        var elemList = c.nestedUnkeyedContainer(forKey: .elements)

        if trackOrder {
            if let n = firstNode { try n.forEachNode(insertOrder: true) { try elemList.encode($0.value) } }
        }
        else if let r = rootNode {
            try r.forEachNode { try elemList.encode($0.value) }
        }
    }

    @usableFromInline func node(forKey key: Key) -> TreeNode<KV>? {
        guard let r = rootNode else { return nil }
        return r.find(with: { compare(a: key, b: $0.key) })
    }

    @usableFromInline func node(at index: Index) -> TreeNode<KV> {
        guard let r = rootNode else { fatalError("Index out of bounds.") }
        return r[TreeNode<KV>.Index(index: index.idx)]
    }

    @usableFromInline func remove(node n: TreeNode<KV>) { rootNode = n.remove() }

    @discardableResult public func updateValue(_ value: Value, forKey key: Key) -> Value? {
        let elem = KV(key: key, value: value)

        if let n = node(forKey: key) {
            let v = n.value.value
            n.value.value = value
            return v
        }

        if let r = rootNode {
            let n = r.insert(value: elem)
            rootNode = n.rootNode
            if trackOrder, let _n = (n as? IOTreeNode<KV>) { lastNode = _n }
        }
        else if trackOrder {
            firstNode = IOTreeNode<KV>(value: elem)
            lastNode = firstNode
            rootNode = firstNode
        }
        else {
            rootNode = TreeNode<KV>(value: elem)
        }

        return nil
    }

    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        guard let r = rootNode else { return }
        rootNode = nil
        DispatchQueue(label: UUID().uuidString).async { r.removeAll() }
    }

    public func forEach(reverse: Bool, _ body: (Element) throws -> Void) rethrows {
        guard let r = rootNode else { return }
        try r.forEachNode(reverse: reverse) { try body($0.value.data) }
    }

    @usableFromInline func _first(reverse f: Bool, where predicate: (Element) throws -> Bool) rethrows -> Element? {
        guard let r = rootNode, let e = try r.firstNode(reverse: f, where: { try predicate($0.value.data) }) else { return nil }
        return e.value.data
    }

    @usableFromInline func _forEachFast(_ body: (Element) throws -> Void) rethrows {
        guard let r = rootNode else { return }
        try r.forEachFast { try body($0.value.data) }
    }
}
