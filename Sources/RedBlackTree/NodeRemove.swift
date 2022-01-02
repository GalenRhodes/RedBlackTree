/*===============================================================================================================================================================================*
 *     PROJECT: RedBlackTree
 *    FILENAME: NodeRemove.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 1/2/22
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

extension Node {
    @usableFromInline typealias tup1 = (Side, ND, ND?, ND?)
    @usableFromInline typealias tup2 = (ND, ND?, ND?)

    @usableFromInline func removeAll() {
        leftNode?.removeAll()
        rightNode?.removeAll()
        leftNode = nil
        rightNode = nil
        parentNode = nil
        data = 0
    }

    @usableFromInline func remove() -> ND? {
        //@f:0
        doWith(default: nil,
               ([ leftNode, rightNode ],     { (a: [ND]) -> ND? in self._r1(left: a[0], right: a[1]) }),
               ([ (leftNode ?? rightNode) ], { (a: [ND]) -> ND? in self._r2(child: a[0])             }),
               ([ parentNode ],              { (a: [ND]) -> ND? in self._r3(parent: a[0])            }))
        //@f:1
    }

    @inlinable func _r1(left l: ND, right r: ND) -> ND? {
        let n = Bool.random() ? l.farRightNode : r.farLeftNode
        swap(&item, &n.item)
        return n.remove()
    }

    @inlinable func _r2(child c: ND) -> ND? {
        c.color = .Black
        _withParent { $0[$1] = c }
        return c.root
    }

    @inlinable func _r3(parent p: ND) -> ND? {
        if self == Color.Black { _r4() }
        p[self ?= p] = nil
        return p.root
    }

    @usableFromInline func _r4() {
        if let parent = parentNode {
            var (side, sibling, closeNephew, distantNephew) = _r5(parent: parent, side: self ?= parent)

            if sibling == Color.Red { (sibling, closeNephew, distantNephew) = _r6(parent: parent, nSide: side, node: parent, dir: side) }

            if sibling == Color.Black && closeNephew == Color.Black && distantNephew == Color.Black {
                sibling.color = .Red
                guard parent == Color.Black else { return parent.color = .Black }
                return parent._r4()
            }

            if closeNephew == Color.Red { (sibling, closeNephew, distantNephew) = _r6(parent: parent, nSide: side, node: sibling, dir: !side) }
            _with(node: distantNephew, ERR_NO_DISTANT_NEPHEW) { $0.color = .Black }
            parent._rotate(side)
        }
    }

    @inlinable func _r5(parent p: ND, side: Side) -> tup1 { assertNotNil(p[!side], ERR_NO_SIBLING) { (s: ND) -> tup1 in (side, s, s[side], s[!side]) } }

    /// Performs a rotation that, in some way, is going to affect this node's sibling. Once the rotation is done this
    /// method will return this nodes new sibling, close nephew, and distant nephew.
    ///
    /// - Parameters:
    ///   - p: This nodes parent node.
    ///   - nSide: Which side of its parent node this node is on - Side.Left or Side.Right.
    ///   - n: The node to be rotated.
    ///   - dir: The direction of rotation.
    /// - Returns: A tuple that includes the new sibling, close nephew, and distant nephew.
    ///
    @inlinable func _r6(parent p: ND, nSide: Side, node n: ND, dir: Side) -> tup2 {
        n._rotate(dir)
        let t = _r5(parent: p, side: nSide)
        return (t.1, t.2, t.3)
    }
}

