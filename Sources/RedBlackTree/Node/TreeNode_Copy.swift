/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeNode_Copy.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 23, 2021
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

extension TreeNode {

    @inlinable convenience init(value v: T, data: UInt) {
        self.init(value: v)
        _data = data
    }

    /// Copy this tree.  If this node is not the root then this call is transferred to the root.
    ///
    /// - Returns: The root node of the copy.
    ///
    public func copyTree() -> TreeNode<T> {
        if let p = parentNode { return p.copyTree() }
        let queue = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
        return _copyTree(limit: 2, queue: queue)
    }

    @inlinable func _copyTree(limit: Int, queue: DispatchQueue?) -> TreeNode<T> {
        let copy = TreeNode<T>(value: value, data: _data)
        if let _queue = queue, limit > 0 {
            let group = DispatchGroup()
            _queue.async(group: group) { copy._leftNode = copy._copyChildNode(self._leftNode, limit: limit, queue: _queue) }
            _queue.async(group: group) { copy._rightNode = copy._copyChildNode(self._rightNode, limit: limit, queue: _queue) }
            group.wait()
        }
        else {
            copy._leftNode = copy._copyChildNode(_leftNode)
            copy._rightNode = copy._copyChildNode(_rightNode)
        }
        return copy
    }

    @inlinable func _copyChildNode(_ c: TreeNode<T>?, limit: Int, queue: DispatchQueue) -> TreeNode<T>? {
        guard let _c = c else { return nil }
        let cc = _c._copyTree(limit: (limit - 1), queue: queue)
        cc._parentNode = self
        return cc
    }

    @inlinable func _copyChildNode(_ c: TreeNode<T>?) -> TreeNode<T>? {
        guard let _c = c else { return nil }
        let cc = _c._copyTree(limit: 0, queue: nil)
        cc._parentNode = self
        return cc
    }
}
