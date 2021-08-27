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

@usableFromInline let ErrorMsgGhostParent    = "Inconsistent state: ghost parent."
@usableFromInline let ErrorMsgMisColored     = "Inconsistent state: mis-colored node."
@usableFromInline let ErrorMsgMissingSibling = "Inconsistent state: missing sibling node."
@usableFromInline let ErrorMsgLeftOrRight    = "Invalid Argument: side must be either left or right."
@usableFromInline let ErrorMsgNoRotLeft      = "Invalid Argument: Cannot rotate node to the left because there is no right child node."
@usableFromInline let ErrorMsgNoRotRight     = "Invalid Argument: Cannot rotate node to the right because there is no left child node."
@usableFromInline let ErrorMsgParentIsChild  = "Invalid Argument: Node cannot be a child of itself."

extension TreeNode {
    //@f:0
    @inlinable var leftCount:  Int { with(node: _leftNode, default: 0)  { $0._count } }
    @inlinable var rightCount: Int { with(node: _rightNode, default: 0) { $0._count } }
    @inlinable var _count:     Int {
        get { Int(bitPattern: Color.maskLo(_data)) }
        set { _data = (Color.maskHi(_data) | Color.maskLo(newValue)) }
    }
    //@f:1

    @inlinable convenience init(value v: T, color c: Color) {
        self.init(value: v)
        color = c
    }

    @inlinable subscript(side: Side) -> TreeNode<T>? {
        get {
            switch side {
                case .Left:    return _leftNode
                case .Right:   return _rightNode
                case .Neither: fatalError(ErrorMsgLeftOrRight)
            }
        }
        set {
            func _setChild(_ oc: TreeNode<T>?, _ nc: TreeNode<T>?, _ side: Side) {
                guard self !== nc else { fatalError(ErrorMsgParentIsChild) }
                guard oc !== nc else { return }
                with(node: oc) { $0._parentNode = nil }
                with(node: nc) { $0._removeFromParent()._parentNode = self }
                if side == .Left { _leftNode = nc }
                else { _rightNode = nc }
                _recount()
            }

            switch side {
                case .Left:    _setChild(_leftNode, newValue, side)
                case .Right:   _setChild(_rightNode, newValue, side)
                case .Neither: fatalError(ErrorMsgLeftOrRight)
            }
        }
    }

    @usableFromInline func _recount() {
        _count = (1 + leftCount + rightCount)
        with(node: _parentNode) { $0._recount() }
    }

    @usableFromInline func _swapMe(with node: TreeNode<T>?) {
        if let p = _parentNode { _forPSide(parent: p, ifLeft: { pp in pp[.Left] = node }, ifRight: { pp in pp[.Right] = node }) }
        else if let node = node { node._removeFromParent() }
    }

    @discardableResult @usableFromInline func _removeFromParent() -> TreeNode<T> {
        _swapMe(with: nil)
        return self
    }

    @usableFromInline func _removeRepair() {
        if let p = parentNode {
            let side: Side        = _forSide(parent: p, ifLeft: .Left, ifRight: .Right)
            var sib:  TreeNode<T> = _mustHave(p[!side], message: ErrorMsgMissingSibling)

            if sib.color.isRed {
                p._rotate(dir: side)
                sib = _mustHave(p[!side], message: ErrorMsgMissingSibling)
            }

            if sib.color.isBlack && Color.isBlack(sib.leftNode) && Color.isBlack(sib.rightNode) {
                sib.color = .Red
                if p.color.isRed { p.color = .Black }
                else { p._removeRepair() }
            }
            else {
                if Color.isRed(sib[side]) { sib._rotate(dir: !side) }
                p._rotate(dir: side)
                if let ps = p._forPSide(ifNeither: nil, ifLeft: { $0._rightNode }, ifRight: { $0._leftNode }) { ps.color = .Black }
            }
        }
    }

    @inlinable func _rotate(dir: Side) {
        let c1 = _mustHave(self[!dir], message: ((dir == .Left) ? ErrorMsgNoRotLeft : ErrorMsgNoRotRight))
        _swapMe(with: c1)
        self[!dir] = c1[dir]
        c1[dir] = self
        swap(&color, &c1.color)
    }

    @usableFromInline func _insertRepair() {
        if let p = _parentNode {
            if p.color.isRed {
                guard let g = p.parentNode, g.color.isBlack else { fatalError(ErrorMsgMisColored) }
                let nSide = _forSide(parent: p, ifLeft: Side.Left, ifRight: Side.Right)
                let pSide = p._forSide(parent: g, ifLeft: Side.Left, ifRight: Side.Right)

                if let u = g[!pSide], u.color.isRed {
                    u.color = .Black
                    p.color = .Black
                    g.color = .Red
                    g._insertRepair()
                }
                else {
                    let q = !nSide
                    if pSide == q {
                        p._rotate(dir: pSide)
                    }
                    g._rotate(dir: !pSide)
                }
            }
        }
        else if color.isRed {
            // This node is the root node so it has to be black.
            color = .Black
        }
    }

    @inlinable func _mustHave<P>(_ p: P?, message: String) -> P {
        guard let pp = p else { fatalError(message) }
        return pp
    }
}

@inlinable func with<T, R>(node: TreeNode<T>?, default def: @autoclosure () throws -> R, _ body: (TreeNode<T>) throws -> R) rethrows -> R where T: Comparable & Equatable {
    guard let r = try with(node: node, body) else { return try def() }
    return r
}

@discardableResult @inlinable func with<T, R>(node: TreeNode<T>?, _ body: (TreeNode<T>) throws -> R) rethrows -> R? where T: Comparable & Equatable {
    guard let n = node else { return nil }
    return try body(n)
}
