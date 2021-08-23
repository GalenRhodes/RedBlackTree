/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeNode.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 17, 2021
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

public class TreeNode<T>: Comparable where T: Comparable & Equatable {

    public internal(set) var value: T

    @usableFromInline init(value v: T, color c: Color) {
        value = v
        _color = c
    }

    private init(value v: T, data: UInt) {
        value = v
        _data = data
    }

    //@f:0
    /// The field that holds the reference to the parent node.
    ///
    @usableFromInline var _parentNode: TreeNode<T>? = nil
    /// The field that holds the reference to the right child node.
    ///
    @usableFromInline var _rightNode:  TreeNode<T>? = nil
    /// The field that holds the reference to the left child node.
    ///
    @usableFromInline var _leftNode:   TreeNode<T>? = nil
    /// To save space this field holds both the color and the count.
    ///
    @usableFromInline var _data:       UInt         = 1
    //@f:1

    /// Copy this tree.  If this node is not the root then this call is transferred to the root.
    ///
    /// @Returns: The root node of the copy.
    ///
    public func copyTree() -> TreeNode<T> {
        if let p = parentNode { return p.copyTree() }
        let queue = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
        return _copyTree(limit: 2, queue: queue)
    }

    private func _copyTree(limit: Int, queue: DispatchQueue?) -> TreeNode<T> {
        let copy = TreeNode<T>(value: value, data: _data)
        if let queue = queue, limit > 0 {
            let group = DispatchGroup()
            queue.async(group: group) { copy._leftNode = self._copyChildNode(parentCopy: copy, childNode: self._leftNode, limit: (limit - 1), queue: queue) }
            queue.async(group: group) { copy._rightNode = self._copyChildNode(parentCopy: copy, childNode: self._rightNode, limit: (limit - 1), queue: queue) }
            group.wait()
        }
        else {
            copy._leftNode = _copyChildNode(parentCopy: copy, childNode: _leftNode)
            copy._rightNode = _copyChildNode(parentCopy: copy, childNode: _rightNode)
        }
        return copy
    }

    private func _copyChildNode(parentCopy copy: TreeNode<T>, childNode: TreeNode<T>?, limit: Int = 0, queue: DispatchQueue? = nil) -> TreeNode<T>? {
        guard let c = childNode else { return nil }
        let cc = c._copyTree(limit: limit, queue: queue)
        cc._parentNode = copy
        return cc
    }
}

