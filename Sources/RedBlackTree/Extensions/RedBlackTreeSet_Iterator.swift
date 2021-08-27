/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: RedBlackTreeSet_Iterator.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 27, 2021
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

extension RedBlackTreeSet {
    @inlinable public func makeIterator() -> Iterator { Iterator(tree: self) }

    public struct Iterator: IteratorProtocol {
        @usableFromInline let tree:  RedBlackTreeSet<Element>
        @usableFromInline var stack: [TreeNode<Element>] = []

        @inlinable init(tree: RedBlackTreeSet<Element>) {
            self.tree = tree
            drop(start: tree.rootNode)
        }

        @inlinable mutating func drop(start: TreeNode<Element>?) {
            var n = start
            while let _n = n {
                stack.append(_n)
                n = _n.leftNode
            }
        }

        @inlinable public mutating func next() -> Element? {
            guard let n = stack.popLast() else { return nil }
            drop(start: n.rightNode)
            return n.value
        }
    }
}
