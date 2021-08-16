/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: LinkedListTreeNode.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 16, 2021
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

public class LinkedListTreeNode<Key, Value>: TreeNode<Key, Value> where Key: Comparable {

    @usableFromInline var listNext: LinkedListTreeNode<Key, Value>? = nil
    @usableFromInline var listPrev: LinkedListTreeNode<Key, Value>? = nil

    @usableFromInline override init(key: Key, value: Value, color: NodeColor) { super.init(key: key, value: value, color: color) }

    @usableFromInline override func makeNewNode(key: Key, value: Value) -> TreeNode<Key, Value> {
        let last = foobar(start: self) { $0.listNext }
        let node = LinkedListTreeNode<Key, Value>(key: key, value: value, color: .Red)
        node.listPrev = last
        last.listNext = node
        return node
    }

    @usableFromInline override func postRemove(_ orig: TNode?) {
        if let oo = orig {
            let o = (oo as! LinkedListTreeNode<Key, Value>)
            let ln = listNext
            let lp = listPrev

            listNext = nil
            listPrev = nil

            o.removeFromList()

            if let n = ln { n.listPrev = o }
            if let p = lp { p.listNext = o }

            o.listNext = ln
            o.listPrev = lp
        }
        else {
            removeFromList()
        }
    }

    func removeFromList() {
        let ln = listNext
        let lp = listPrev
        if let n = ln { n.listPrev = lp }
        if let p = lp { p.listNext = ln }
        listNext = nil
        listPrev = nil
    }
}
