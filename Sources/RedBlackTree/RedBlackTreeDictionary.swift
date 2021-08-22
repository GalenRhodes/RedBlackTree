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

    public typealias Element = (Key, Value)

    //@f:0
    public            var count:      Int           { (rootNode?.count ?? 0) }
    public            let startIndex: Index         = Index(index: 0)
    @usableFromInline var rootNode:   TreeNode<KV>? = nil
    //@f:1

    public init() {}

    public required init(dictionaryLiteral elements: SequenceElement...) {
        for e in elements { updateValue(e.1, forKey: e.0) }
    }

    public required init(from decoder: Decoder) throws where Key: Decodable, Value: Decodable {
        var c = try decoder.unkeyedContainer()
        while !c.isAtEnd {
            let e = try c.decode(KV.self)
            updateValue(e.value, forKey: e.key)
        }
    }

    deinit { removeAll() }

    public func index(forKey key: Key) -> Index? {
        guard let r = rootNode, let n = r.find(with: { compare(a: key, b: $0.key) }) else { return nil }
        return Index(index: n.index)
    }

    public subscript(position: Index) -> Element {
        guard let r = rootNode else { fatalError("Index out of bounds.") }
        let n = r[TreeNode<KV>.Index(index: position.idx)]
        return (n.value.key, n.value.value)
    }

    @discardableResult public func updateValue(_ value: Value, forKey key: Key) -> Value? {
        let newElement = KV(key: key, value: value)
        guard let r = rootNode else {
            rootNode = TreeNode<KV>(value: newElement)
            return nil
        }
        guard let n = r.find(with: { compare(a: key, b: $0.key) }) else {
            rootNode = r.insert(value: newElement).rootNode
            return nil
        }
        let v = n.value.value
        rootNode = r.insert(value: newElement).rootNode
        return v
    }

    @discardableResult public func remove(at index: Index) -> Element {
        guard let r = rootNode else { fatalError("Index out of bounds.") }
        let n = r[TreeNode<KV>.Index(index: index.idx)]
        let v = (n.value.key, n.value.value)
        rootNode = n.remove()
        return v
    }

    @discardableResult public func removeValue(forKey key: Key) -> Value? {
        guard let r = rootNode, let n = r.find(with: { compare(a: key, b: $0.key) }) else { return nil }
        return n.value.value
    }

    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        guard let r = rootNode else { return }
        rootNode = nil
        r.removeAll()
    }

    public func forEach(reverse: Bool, _ body: (Element) throws -> Void) rethrows {
        guard let r = rootNode else { return }
        try r.forEachNode(reverse: reverse) { try body(($0.value.key, $0.value.value)) }
    }

    @usableFromInline func _first(reverse f: Bool, where predicate: (Element) throws -> Bool) rethrows -> Element? {
        guard let r = rootNode, let e = try r.firstNode(reverse: f, where: { try predicate(($0.value.key, $0.value.value)) }) else { return nil }
        return (e.value.key, e.value.value)
    }

    @usableFromInline func _getValue(forKey key: Key) -> Value? {
        rootNode?.find(with: { compare(a: key, b: $0.key) })?.value.value
    }

    public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<(Key, Value)>) throws -> R) rethrows -> R? { nil }
}
