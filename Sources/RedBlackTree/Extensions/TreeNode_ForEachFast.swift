/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeNode_ForEachFast.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 24, 2021
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

    public func forEachFast(_ body: (TreeNode<T>) throws -> Void) rethrows {
        if let p = parentNode { try p.forEachFast(body) }
        else { try forEachFast(DispatchQueue(label: UUID().uuidString, attributes: .concurrent), 2, body) }
    }

    @inlinable func forEachFast(_ queue: DispatchQueue, _ limit: Int, _ body: (TreeNode<T>) throws -> Void) rethrows {
        if limit > 0 { try forEachFastThreaded(queue, limit - 1, body) }
        else { try forEachSlow(body) }
    }

    @inlinable func forEachSlow(_ body: (TreeNode<T>) throws -> Void) rethrows {
        try body(self)
        if let n = _leftNode { try n.forEachSlow(body) }
        if let n = _rightNode { try n.forEachSlow(body) }
    }

    @usableFromInline func forEachFastThreaded(_ q: DispatchQueue, _ l: Int, _ b: (TreeNode<T>) throws -> Void) rethrows {
        try b(self)
        try withoutActuallyEscaping(b) { (sBody) -> Void in //@f:0
            func foo(_ n: TreeNode<T>?) -> Error? { if let n = n { do { try n.forEachFast(q, l, sBody) } catch let e { return e } }; return nil }
            //@f:1
            var _err: Error?        = nil
            let _grp: DispatchGroup = DispatchGroup()
            let _lck: NSLock        = NSLock()
            q.async(group: _grp) { let e = foo(self._leftNode); if let e = e { _lck.withLock { _err = e } } }
            q.async(group: _grp) { let e = foo(self._rightNode); if let e = e { _lck.withLock { _err = e } } }
            _grp.wait()
            if let e = _err { throw e }
        }
    }
}
