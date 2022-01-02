/*===============================================================================================================================================================================*
 *     PROJECT: RedBlackTree
 *    FILENAME: NodeUtils.swift
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
    @inlinable @discardableResult func _withParent(do action: (ND, Side) throws -> Void) rethrows -> ND {
        try _withParent(none: {}, do: action); return self
    }

    @inlinable func _withParent<R>(none noneAction: () throws -> R, do action: (ND, Side) throws -> R) rethrows -> R {
        guard let p = parentNode else { return try noneAction() }
        return try action(p, (self ?= p))
    }

    @inlinable func _withParent<R>(_ msg: @autoclosure () -> String, _ action: (ND, Side) throws -> R) rethrows -> R { try assertNotNil(parentNode, msg()) { try action($0, (self ?= $0)) } }

    @inlinable func _with(node: ND?, do action: (ND) throws -> Void) rethrows { if let n = node { try action(n) } }

    @inlinable func _with<R>(node: ND?, _ msg: @autoclosure () -> String, _ action: (ND) throws -> R) rethrows -> R { try assertNotNil(node, msg(), action) }

    @inlinable func _with<R>(node: ND?, do action: (ND) throws -> R, else noAction: () throws -> R) rethrows -> R {
        guard let n = node else { return try noAction() }
        return try action(n)
    }

    @inlinable func _get<R>(from node: ND?, default defaultValue: @autoclosure () -> R, _ getter: (ND) throws -> R) rethrows -> R {
        guard let n = node else { return defaultValue() }
        return try getter(n)
    }

    @usableFromInline func _recount() {
        count = (1 + leftCount + rightCount)
        _withParent { p, _ in p._recount() }
    }

    @inlinable func _rotate(_ sd: Side) {
        assertNotNil(self[!sd], sd == .Left ? ERR_ROT_LEFT : ERR_ROT_RIGHT) { (c: ND) -> Void in
            _withParent { p, s in p[s] = c }
            self[!sd] = c[sd]
            c[sd] = self
            swap(&color, &c.color)
        }
    }

    @inlinable func _foo(_ newNode: ND?, _ oldNode: ND?) {
        guard newNode !== oldNode else { return }
        _with(node: oldNode) { $0.parentNode = nil }
        _with(node: newNode) {
            $0._withParent { p, s in p[s] = nil }
            $0.parentNode = self
        }
    }

    @inlinable func _bar(_ newNode: ND?, _ oldNode: ND?) { if newNode !== oldNode { _recount() } }

    @inlinable static func ?= (lhs: ND, rhs: ND) -> Side {
        if lhs.parentNode === rhs {
            return lhs === rhs.leftNode ? .Left : .Right
        }
        else if rhs.parentNode === lhs {
            return rhs === lhs.leftNode ? .Left : .Right
        }
        fatalError("ERROR: Hierarchy Error")
    }
}
