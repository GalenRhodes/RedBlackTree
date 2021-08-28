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
    //@f:0
    /// The field that holds the value.
    ///
    public internal(set) var value: T
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

    /// Default public constructor.
    ///
    /// - Parameter v: The value.
    ///
    public init(value v: T) {
        value = v
    }

    @usableFromInline func _insert(value: T, side: Side) -> TreeNode<T> {
        if let n = self[side] { return n.insert(value: value) }
        let n = _makeNewNode(value: value)
        self[side] = n
        n._insertRepair()
        return n
    }

    @usableFromInline func _makeNewNode(value: T) -> TreeNode<T> { TreeNode<T>(value: value, color: .Red) }

    public func insert(value: T) -> TreeNode<T> {
        switch compare(a: value, b: self.value) {
            case .EqualTo:
                self.value = value
                return self
            case .LessThan:
                return _insert(value: value, side: .Left)
            case .GreaterThan:
                return _insert(value: value, side: .Right)
        }
    }

    public func remove() -> TreeNode<T>? {
        if let l = _leftNode, let r = _rightNode {
            // There are two child nodes so we need
            // to swap the value of this node with either
            // the child node that is just before this one
            // or just after this one (we'll randomly pick)
            // and then remove that child node instead.
            let other = (Bool.random() ? foo(start: l) { $0._rightNode } : foo(start: r) { $0._leftNode })
            _swapNodeBeforeRemove(other: other)
            return other.remove()
        }
        else if let c = (_leftNode ?? _rightNode) {
            // There is one child node. This means that this node is
            // black and the child node is red. That's the only way
            // it can be. So we'll just paint the child node black
            // and then remove this node.
            c.color = .Black
            _swapMe(with: c)
            return _postRemoveHook(root: c.rootNode)
        }
        else if let p = parentNode {
            // There are no child nodes but there is a parent node.
            // If this node is black then repair the tree before
            // removing this node.
            if color.isBlack { _removeRepair() }
            // Then remove this node.
            _removeFromParent()
            return _postRemoveHook(root: p.rootNode)
        }
        // There is no parent node and no child nodes which
        // means this is the only existing node so there is
        // nothing to do.
        return _postRemoveHook(root: nil)
    }

    @usableFromInline func _postRemoveHook(root: TreeNode<T>?) -> TreeNode<T>? { root }

    @usableFromInline func _swapNodeBeforeRemove(other: TreeNode<T>) { swap(&value, &other.value) }
}