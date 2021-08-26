/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeNode_Extension.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 19, 2021
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
    //@f:0
    @inlinable public var rootNode:   TreeNode<T>  { _foo { $0.parentNode }               }
    @inlinable public var parentNode: TreeNode<T>? { _parentNode                          }
    @inlinable public var leftNode:   TreeNode<T>? { self[.Left]                          }
    @inlinable public var rightNode:  TreeNode<T>? { self[.Right]                         }
    @inlinable public var count:      Int          { _count                               }
    //@f:1

    @inlinable public static func < (lhs: TreeNode<T>, rhs: TreeNode<T>) -> Bool { (lhs.value < rhs.value) }

    @inlinable public static func == (lhs: TreeNode<T>, rhs: TreeNode<T>) -> Bool { (lhs.value == rhs.value) }

    @inlinable public subscript(value: T) -> TreeNode<T>? {
        switch compare(a: value, b: self.value) {
            case .EqualTo:     return self
            case .LessThan:    return leftNode?[value]
            case .GreaterThan: return rightNode?[value]
        }
    }

    public func find(with comp: (T) throws -> ComparisonResults) rethrows -> TreeNode<T>? {
        switch try comp(value) {
            case .EqualTo: return self
            case .LessThan: return try leftNode?.find(with: comp)
            case .GreaterThan: return try rightNode?.find(with: comp)
        }
    }

    public func removeAll() {
        if let l = _leftNode {
            l.removeAll()
            _leftNode = nil
        }
        if let r = _rightNode {
            r.removeAll()
            _rightNode = nil
        }
        _parentNode = nil
        _count = 1
        color = .Black
    }

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
        if let l = leftNode, let _ = rightNode {
            let other = l._foo { $0.rightNode }
            swap(&value, &other.value)
            return other.remove()
        }
        else if let c = (leftNode ?? rightNode) {
            c.color = .Black
            _swapMe(with: c)
            return c.rootNode
        }
        else if let p = parentNode {
            // There are no child nodes but there is a parent node.
            if color.isBlack { _removeRepair() }
            _removeFromParent()
            return p.rootNode
        }
        // This is the only node so it can just go away.
        return nil
    }

    public func forEachNode(reverse f: Bool = false, _ body: (TreeNode<T>) throws -> Void) rethrows {
        if let n = (f ? _rightNode : _leftNode) { try n.forEachNode(reverse: f, body) }
        try body(self)
        if let n = (f ? _leftNode : _rightNode) { try n.forEachNode(reverse: f, body) }
    }

    public func firstNode(reverse f: Bool = false, where predicate: (TreeNode<T>) throws -> Bool) rethrows -> TreeNode<T>? {
        if let n = (f ? _rightNode : _leftNode), let m = try n.firstNode(reverse: f, where: predicate) { return m }
        if try predicate(self) { return self }
        if let n = (f ? _leftNode : _rightNode), let m = try n.firstNode(reverse: f, where: predicate) { return m }
        return nil
    }
}
