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

    func _forEach(body: (Element) throws -> Void) rethrows { if let r = rootNode { try r.forEach { node in try body(node.data) } } }

    func _firstNode(where predicate: (TreeNode<Key, Value>) throws -> Bool) rethrows -> TreeNode<Key, Value>? {
        guard let r = rootNode else { return nil }
        return try r.firstNode(where: predicate)
    }

    @discardableResult func _remove(at index: Index) -> Element {
        let node = _getNode(forIndex: index)
        defer { __showChange() }
        rootNode = node.removeNode()
        return node.data
    }

    @discardableResult func _removeValue(forKey key: Key) -> Value? {
        guard let node = _getNode(forKey: key) else { return nil }
        defer { __showChange() }
        rootNode = node.removeNode()
        return node.value
    }

    @discardableResult func _update(_ elem: Element) -> Value? {
        _update(value: elem.value, forKey: elem.key)
    }

    @discardableResult func _update(value: Value, forKey key: Key) -> Value? {
        defer { __showChange() }
        guard let r = rootNode else {
            rootNode = TreeNode<Key, Value>(key: key, value: value)
            return nil
        }
        let v = r[key]?.value
        rootNode = r.insertNode(key: key, value: value)
        return v
    }

    func __showChange() {
        descCache = nil
        changed += 1
    }

    func _getValue(forKey key: Key) -> Value? { _getNode(forKey: key)?.value }

    func _getNode(forKey key: Key) -> TreeNode<Key, Value>? {
        guard let r = rootNode else { return nil }
        return r[key]
    }

    func _getNode(forIndex idx: Index) -> TreeNode<Key, Value> {
        guard let r = rootNode else { fatalError("Index out of bounds.") }
        return r.node(forIndex: idx.index)
    }

    func _combine(_ elem: Element, combine: (Value, Value) throws -> Value) rethrows {
        if let v = _getValue(forKey: elem.key) { _update(value: try combine(v, elem.value), forKey: elem.key) }
        else { _update(elem) }
    }
}
