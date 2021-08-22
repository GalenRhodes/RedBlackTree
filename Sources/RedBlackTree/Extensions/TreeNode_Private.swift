/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeNode_Private.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 20, 2021
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
    @inlinable var leftCount:   Int          { (leftNode?.count ?? 0)                }
    @inlinable var rightCount:  Int          { (rightNode?.count ?? 0)               }
    @inlinable var nodeSide:    Side         { _bar(default: .Neither) { _, s in s } }
    @inlinable var siblingNode: TreeNode<T>? { _bar(default: nil)      { $0[!$1]   } }
    //@f:1

    @inlinable subscript(side: Side) -> TreeNode<T>? {
        get {
            switch side {
                case .Neither: fatalError("Invalid Argument: side must be either Left or Right.")
                case .Left:    return _leftNode
                case .Right:   return _rightNode
            }
        }
        set {
            let curr: TreeNode<T>? = self[side]
            guard curr !== newValue else { return }
            if let n = curr { n._parentNode = nil }
            if let n = newValue { n._removeFromParent()._parentNode = self }
            if side == .Left { _leftNode = newValue }
            else { _rightNode = newValue }
            _recount()
        }
    }

    @usableFromInline func _recount() {
        _count = (1 + leftCount + rightCount)
        if let p = parentNode { p._recount() }
    }

    @inlinable func _swapMe(with node: TreeNode<T>) { if !_bar({ $0[$1] = node }) { node._removeFromParent() } }

    @discardableResult @inlinable func _removeFromParent() -> TreeNode<T> { _bar(default: self) { $0[$1] = nil; return self } }

    @usableFromInline func _removeRepair() {
        if let p = parentNode {
            var s    = _mustHave(siblingNode, message: "Inconsistent state: missing sibling node.")
            let side = nodeSide

            if s.color.isRed {
                p._rotate(dir: side)
                s = _mustHave(siblingNode, message: "Inconsistent state: missing sibling node.")
            }

            if s.color.isBlack && Color.isBlack(s.leftNode) && Color.isBlack(s.rightNode) {
                s._color = .Red
                if p.color.isRed { p._color = .Black }
                else { p._removeRepair() }
            }
            else {
                if Color.isRed(s[side]) { s._rotate(dir: !side) }
                p._rotate(dir: side)
                if let ps = p.siblingNode { ps._color = .Black }
            }
        }
    }

    @inlinable func _rotate(dir: Side) {
        guard dir != .Neither else { fatalError("Invalid Argument: side must be either Left or Right.") }
        let c1 = _mustHave(self[!dir], message: "Cannot rotate node to the \(dir) because there is no \(!dir) child node.")
        let c2 = c1[dir]
        _swapMe(with: c1)
        c1[dir] = self
        self[!dir] = c2
        swap(&_color, &c1._color)
    }

    @usableFromInline func _insert(value: T, side: Side) -> TreeNode<T> {
        if let n = self[side] { return n.insert(value: value) }
        let n = TreeNode<T>(value: value, color: .Red)
        self[side] = n
        n._insertRepair()
        return n
    }

    @usableFromInline func _insertRepair() {
        if let p = parentNode {
            if p.color.isRed {
                let g = _mustHave(p.parentNode, message: "Inconsistent state: mis-colored node.")

                if let u = p.siblingNode, u.color.isRed {
                    u._color = .Black
                    p._color = .Black
                    g._color = .Red
                    g._insertRepair()
                }
                else {
                    let pSide = p.nodeSide
                    if pSide != nodeSide { p._rotate(dir: pSide) }
                    g._rotate(dir: !pSide)
                }
            }
        }
        else {
            _color = .Black
        }
    }

    @inlinable func _foo(_ body: (TreeNode<T>) throws -> TreeNode<T>?) rethrows -> TreeNode<T> {
        var n = self
        while true {
            guard let _n = try body(n) else { return n }
            n = _n
        }
    }

    @inlinable func _bar<R>(default def: R, _ body: (TreeNode<T>, Side) throws -> R) rethrows -> R {
        guard let p = parentNode else { return def }
        for s in _sx { if self === p[s] { return try body(p, s) } }
        fatalError("Inconsistent state: ghost parent.")
    }

    @inlinable func _bar(_ body: (TreeNode<T>, Side) throws -> Void) rethrows -> Bool {
        guard let p = parentNode else { return false }
        for s in _sx { if self === p[s] { try body(p, s); return true } }
        fatalError("Inconsistent state: ghost parent.")
    }

    @inlinable func _mustHave<P>(_ p: P?, message: String) -> P {
        guard let pp = p else { fatalError(message) }
        return pp
    }
}
