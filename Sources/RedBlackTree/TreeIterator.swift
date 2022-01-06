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

@usableFromInline class TreeIterator<O, E>: TreeListener, IteratorProtocol where O: TreeIteratorOwner, O.E == E {
    @usableFromInline typealias Element = E
    @usableFromInline typealias N = Node<E>

    @usableFromInline var owner: O
    @usableFromInline var stack: [N] = []

    @usableFromInline init(owner: O) {
        self.owner = owner
        spelunk(startingAt: owner.treeRoot as N?)
    }
}

extension TreeIterator {
    @inlinable func next() -> E? {
        guard let n = stack.popLast() else { return nil }
        spelunk(startingAt: n.rightNode)
        return n.item
    }

    @inlinable func spelunk(startingAt node: N?) {
        var _n = node
        while let n = _n {
            stack.append(n)
            _n = n.leftNode
        }
    }

    @inlinable func allRemoved() { stack.removeAll() }

    @inlinable func nodeRemoved(node: N) {

    }

    @inlinable func nodeInserted(node: N) {

    }
}
