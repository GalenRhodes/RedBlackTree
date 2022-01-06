/*===============================================================================================================================================================================*
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeIterator.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 1/5/22
 *
 * Copyright © 2022. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation

/// An iterator that is immune to changes in the tree.
///
@usableFromInline class TreeIterator<O, E>: TreeListener, IteratorProtocol where E: Hashable & Comparable, O: TreeIteratorOwner, O.E == E {
    @usableFromInline typealias Element = E

    @usableFromInline var owner:     O
    @usableFromInline var nextNode:  Node<E>? = nil
    @usableFromInline var nextIndex: Int      = -1

    /// Create a new iterator with the TreeMap or TreeSet that owns it.
    ///
    /// - Parameter owner: The TreeMap or TreeSet that owns it.
    ///
    @usableFromInline init(owner: O) {
        self.owner = owner
        nextNode = (owner.treeRoot as Node<E>?)?.farLeftNode
    }

    /// Get the item from the next node.  If there is no next node then nil is returned.
    ///
    /// - Returns: The item from the next node or nil if there is no next node.
    ///
    @usableFromInline func next() -> E? {
        owner.lock.withReadLock {
            guard let n = nextNode else {
                nextIndex = -1
                return nil
            }
            nextNode = n.nextNode
            nextIndex = n.index + 1
            return n.item
        }
    }

    /// If all the nodes got removed then there is no next node and this iterator is finished.
    ///
    @usableFromInline func allRemoved() {
        owner.lock.withReadLock {
            nextNode = nil
            nextIndex = -1
        }
    }

    /// If a new node is inserted then there is nothing for us to do.
    ///
    /// - Parameter node: The inserted node.
    ///
    @usableFromInline func nodeInserted(node: Node<E>) {
        /* Nothing to do. */
    }

    /// If the node that was removed was our next node then attempt to find that node's next node using the index. We
    /// can do this because if a node is removed then it's index is simply taken over by it's next node.
    ///
    /// - Parameter node: The node that was removed.
    ///
    @usableFromInline func nodeRemoved(node: Node<E>) {
        owner.lock.withReadLock {
            if node === nextNode {
                nextNode = ((nextIndex < 0) ? nil : unwrap(owner.treeRoot as Node<E>?, def: nil, { (r: Node<E>) -> Node<E>? in r.nodeWith(index: nextIndex) }))
            }
        }
    }
}
