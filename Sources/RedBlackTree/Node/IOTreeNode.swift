/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: IOTreeNode.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 28, 2021
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

public class IOTreeNode<T>: TreeNode<T> where T: Comparable & Equatable {
    public internal(set) var prevNode: IOTreeNode<T>? = nil
    public internal(set) var nextNode: IOTreeNode<T>? = nil

    @usableFromInline func forEachNode(insertOrder io: Bool, reverse: Bool = false, _ body: (TreeNode<T>) throws -> Void) rethrows {
        if io {
            if reverse {
                let n = foo(start: self) { $0.nextNode }
                _ = try foo(start: n) {
                    try body($0)
                    return $0.prevNode
                }
            }
            else {
                let n = foo(start: self) { $0.prevNode }
                _ = try foo(start: n) {
                    try body($0)
                    return $0.nextNode
                }
            }
        }
        else {
            try forEachNode(reverse: reverse, body)
        }
    }

    @usableFromInline override func _insert(value: T, side: Side) -> TreeNode<T> {
        let newNode = super._insert(value: value, side: side)
        guard let _newNode = (newNode as? IOTreeNode<T>) else { return newNode }
        let n1: IOTreeNode<T> = foo(start: self) { $0.nextNode }
        n1.nextNode = _newNode
        _newNode.prevNode = n1
        return _newNode
    }

    @usableFromInline override func _makeNewNode(value: T) -> TreeNode<T> { IOTreeNode<T>(value: value, color: .Red) }

    @usableFromInline override func _swapNodeBeforeRemove(other: TreeNode<T>) {
        super._swapNodeBeforeRemove(other: other)
        guard let _other = (other as? IOTreeNode<T>) else { return }
        // We also need to swap our place in the insert order with this node
        let sPrev = prevNode
        let sNext = nextNode
        let oPrev = _other.prevNode
        let oNext = _other.nextNode
        prevNode = oPrev
        nextNode = oNext
        oPrev?.nextNode = self
        oNext?.prevNode = self
        _other.prevNode = sPrev
        _other.nextNode = sNext
        sPrev?.nextNode = _other
        sNext?.prevNode = _other
    }

    @usableFromInline override func _postRemoveHook(root: TreeNode<T>?) -> TreeNode<T>? {
        let sPrev = prevNode
        let sNext = nextNode
        prevNode = nil
        nextNode = nil
        sPrev?.nextNode = sNext
        sNext?.prevNode = sPrev
        return super._postRemoveHook(root: root)
    }
}