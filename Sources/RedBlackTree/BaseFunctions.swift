/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: BaseFunctions.swift
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

    @inlinable var _first: Element? {
        guard let r = rootNode else { return nil }
        let n = r.nextFalling
        return n.data
    }

    @inlinable var _last: Element? {
        guard let r = rootNode else { return nil }
        let n = r.prevFalling
        return n.data
    }

    @inlinable func _forEach(body: (Element) throws -> Void) rethrows { if let r = rootNode { try r.forEach { node in try body(node.data) } } }

    @inlinable func _firstNode(where predicate: (TreeNode<Key, Value>) throws -> Bool) rethrows -> TreeNode<Key, Value>? {
        guard let r = rootNode else { return nil }
        return try r.firstNode(where: predicate)
    }

    @inlinable @discardableResult func _remove(at index: Index) -> Element {
        let node = _getNode(forIndex: index)
        rootNode = node.removeNode()
        __showChange()
        return node.data
    }

    @inlinable @discardableResult func _removeValue(forKey key: Key) -> Value? {
        guard let node = _getNode(forKey: key) else { return nil }
        rootNode = node.removeNode()
        __showChange()
        return node.value
    }

    @inlinable @discardableResult func _update(_ elem: Element) -> Value? { _update(value: elem.value, forKey: elem.key) }

    @inlinable @discardableResult func _update(value: Value, forKey key: Key) -> Value? {
        var v: Value? = nil
        if let root = rootNode {
            if let node = root[key] {
                v = node.value
                node.value = value
            }
            else {
                rootNode = root.insertNode(key: key, value: value)
            }
        }
        else {
            rootNode = TreeNode<Key, Value>(key: key, value: value, color: .Black)
        }
        __showChange()
        return v
    }

    @inlinable func __showChange() {
        descCache = nil
        changed += 1
    }

    @inlinable func _getValue(forKey key: Key) -> Value? { _getNode(forKey: key)?.value }

    @inlinable func _getNode(forKey key: Key) -> TreeNode<Key, Value>? {
        guard let r = rootNode else { return nil }
        return r[key]
    }

    @inlinable func _getNode(forIndex idx: Index) -> TreeNode<Key, Value> {
        guard let r = rootNode else { fatalError("Index out of bounds.") }
        return r.node(forIndex: idx.index)
    }

    @inlinable func _combine(_ elem: Element, combine: (Value, Value) throws -> Value) rethrows {
        if let v = _getValue(forKey: elem.key) { self[elem.key] = try combine(v, elem.value) }
        else { _update(elem) }
    }
}
