/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeNode_Side.swift
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

    @usableFromInline enum Side {
        case Neither
        case Left
        case Right

        @inlinable static prefix func ! (s: Self) -> Self {
            switch s {
                case .Neither: return .Neither
                case .Left:    return .Right
                case .Right:   return .Left
            }
        }
    }

    @inlinable func _forSide<R>(parent p: TreeNode<T>, ifLeft l: @autoclosure () throws -> R, ifRight r: @autoclosure () throws -> R) rethrows -> R {
        try _forPSide(parent: p, ifLeft: { _ in try l() }, ifRight: { _ in try r() })
    }

    @inlinable func _forPSide<R>(ifNeither n: @autoclosure () throws -> R, ifLeft l: (TreeNode<T>) throws -> R, ifRight r: (TreeNode<T>) throws -> R) rethrows -> R {
        guard let p = _parentNode else { return try n() }
        return try _forPSide(parent: p, ifLeft: l, ifRight: r)
    }

    @inlinable func _forPSide<R>(parent p: TreeNode<T>, ifLeft l: (TreeNode<T>) throws -> R, ifRight r: (TreeNode<T>) throws -> R) rethrows -> R {
        if self === p._leftNode { return try l(p) }
        if self === p._rightNode { return try r(p) }
        fatalError(ErrorMsgGhostParent)
    }
}
