/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeNode.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 17, 2021
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

@usableFromInline let RedMask:                UInt   = (1 << (UInt.bitWidth - 1))
@usableFromInline let ColorMask:              [UInt] = [ 0, RedMask ]
@usableFromInline let ErrorMsgGhostParent:    String = "Inconsistent state: ghost parent."
@usableFromInline let ErrorMsgMisColored:     String = "Inconsistent state: mis-colored node."
@usableFromInline let ErrorMsgMissingSibling: String = "Inconsistent state: missing sibling node."
@usableFromInline let ErrorMsgLeftOrRight:    String = "Invalid Argument: side must be either left or right."
@usableFromInline let ErrorMsgNoRotLeft:      String = "Invalid Argument: Cannot rotate node to the left because there is no right child node."
@usableFromInline let ErrorMsgNoRotRight:     String = "Invalid Argument: Cannot rotate node to the right because there is no left child node."
@usableFromInline let ErrorMsgParentIsChild:  String = "Invalid Argument: Node cannot be a child of itself."

@usableFromInline class TreeNode<T> where T: Comparable {
    //@f:0
    /// The field that holds the value.
    ///
    @usableFromInline var value:      T
    /// The field that holds the reference to the parent node.
    ///
    @usableFromInline var parentNode: TreeNode<T>? = nil
    /// The field that holds the reference to the right child node.
    ///
    @usableFromInline var _rightNode: TreeNode<T>? = nil
    /// The field that holds the reference to the left child node.
    ///
    @usableFromInline var _leftNode:  TreeNode<T>? = nil
    /// To save space this field holds both the color and the count.
    ///
    @usableFromInline var _data:      UInt         = 1
    //@f:1

    /// Default constructor.
    ///
    /// - Parameter v: The value.
    ///
    @usableFromInline init(value v: T) {
        value = v
    }

    @usableFromInline func makeNewNode(value: T) -> TreeNode<T> { TreeNode<T>(value: value, color: .Red) }

    @usableFromInline func makeNewNode(value: T, data: UInt) -> TreeNode<T> { TreeNode<T>(value: value, data: data) }

    @usableFromInline func postRemoveHook(root: TreeNode<T>?) -> TreeNode<T>? { root }

    @usableFromInline func swapNodeBeforeRemove(other: TreeNode<T>) { swap(&value, &other.value) }
}

extension TreeNode {

    @usableFromInline enum Color: Int {
        case Black = 0
        case Red

        @inlinable var isRed:   Bool { self == .Red }
        @inlinable var isBlack: Bool { self == .Black }

        @inlinable static func isRed(_ n: TreeNode?) -> Bool { n?.color.isRed ?? false }

        @inlinable static func isBlack(_ n: TreeNode?) -> Bool { n?.color.isBlack ?? true }

        @inlinable static func maskLo(_ n: UInt) -> UInt {
            let m: UInt = ~RedMask
            let r: UInt = (n & m)
            return r
        }

        @inlinable static func maskLo(_ n: Int) -> UInt { maskLo(UInt(bitPattern: n)) }

        @inlinable static func maskHi(_ n: UInt) -> UInt {
            let m: UInt = RedMask
            let r: UInt = (n & m)
            return r
        }
    }

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
}

extension TreeNode {
    //@f:0
    @inlinable var rootNode:   TreeNode<T>  { foo(start: self) { $0.parentNode } }
    @inlinable var leftNode:   TreeNode<T>? { self[.Left] }
    @inlinable var rightNode:  TreeNode<T>? { self[.Right] }
    @inlinable var index:      Index        { forPSide(ifNeither: Index(index: leftCount), ifLeft: { $0.index - rightCount - 1 }, ifRight: { $0.index + leftCount + 1 }) }
    @inlinable var leftCount:  Int          { with(node: _leftNode, default: 0) { $0.count } }
    @inlinable var rightCount: Int          { with(node: _rightNode, default: 0) { $0.count } }
    @inlinable var count:      Int          { get { Int(bitPattern: Color.maskLo(_data)) } set { _data = (Color.maskHi(_data) | Color.maskLo(newValue)) } }
    @inlinable var color:      Color        { get { ((Color.maskHi(_data) == 0) ? Color.Black : Color.Red) } set { _data = (Color.maskLo(_data) | ColorMask[newValue.rawValue]) } }
    //@f:1

    @inlinable convenience init(value v: T, data: UInt) {
        self.init(value: v)
        _data = data
    }

    @inlinable convenience init(value v: T, color c: Color) {
        self.init(value: v)
        color = c
    }

    @inlinable subscript(value: T) -> TreeNode<T>? {
        switch compare(a: value, b: self.value) {
            case .EqualTo:     return self
            case .LessThan:    return leftNode?[value]
            case .GreaterThan: return rightNode?[value]
        }
    }

    @usableFromInline typealias Index = TreeIndex

    @inlinable subscript(index: Index) -> TreeNode<T> {
        guard index.idx >= 0 else { fatalError("Index out of bounds.") }
        switch compare(a: index, b: self.index) {
            case .EqualTo:     return self
            case .LessThan:    if let n = leftNode { return n[index] }
            case .GreaterThan: if let n = rightNode { return n[index] }
        }
        fatalError("Index out of bounds.")
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
                with(node: oc) { $0.parentNode = nil }
                with(node: nc) { $0.removeFromParent().parentNode = self }
                if side == .Left { _leftNode = nc }
                else { _rightNode = nc }
                recount()
            }

            switch side {
                case .Left:    _setChild(_leftNode, newValue, side)
                case .Right:   _setChild(_rightNode, newValue, side)
                case .Neither: fatalError(ErrorMsgLeftOrRight)
            }
        }
    }

    @usableFromInline func insert(value: T) -> TreeNode<T> {
        switch compare(a: value, b: self.value) {
            case .EqualTo:
                self.value = value
                return self
            case .LessThan:
                return insert(value: value, side: .Left)
            case .GreaterThan:
                return insert(value: value, side: .Right)
        }
    }

    @usableFromInline func insert(value: T, side: Side) -> TreeNode<T> {
        if let n = self[side] { return n.insert(value: value) }
        let n = makeNewNode(value: value)
        self[side] = n
        n.insertRepair()
        return n
    }

    @usableFromInline func remove() -> TreeNode<T>? {
        if let l = _leftNode, let r = _rightNode {
            // There are two child nodes so we need
            // to swap the value of this node with either
            // the child node that is just before this one
            // or just after this one (we'll randomly pick)
            // and then remove that child node instead.
            let other = (Bool.random() ? foo(start: l) { $0._rightNode } : foo(start: r) { $0._leftNode })
            swapNodeBeforeRemove(other: other)
            return other.remove()
        }
        else if let c = (_leftNode ?? _rightNode) {
            // There is one child node. This means that this node is
            // black and the child node is red. That's the only way
            // it can be. So we'll just paint the child node black
            // and then remove this node.
            c.color = .Black
            swapMe(with: c)
            return postRemoveHook(root: c.rootNode)
        }
        else if let p = parentNode {
            // There are no child nodes but there is a parent node.
            // If this node is black then repair the tree before
            // removing this node.
            if color.isBlack { removeRepair() }
            // Then remove this node.
            removeFromParent()
            return postRemoveHook(root: p.rootNode)
        }
        // There is no parent node and no child nodes which
        // means this is the only existing node so there is
        // nothing to do.
        return postRemoveHook(root: nil)
    }

    /// Copy this tree.  If this node is not the root then this call is transferred to the root.
    ///
    /// - Returns: The root node of the copy.
    ///
    @usableFromInline func copyTree() -> TreeNode<T> {
        if let p = parentNode { return p.copyTree() }
        let queue = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
        return copyTree(limit: 2, queue: queue)
    }

    @usableFromInline func copyTree(limit: Int, queue: DispatchQueue?) -> TreeNode<T> {
        let copy = makeNewNode(value: value, data: _data)
        if let _queue = queue, limit > 0 {
            let group = DispatchGroup()
            _queue.async(group: group) { copy._leftNode = copy.copyChildNode(self._leftNode, limit: limit, queue: _queue) }
            _queue.async(group: group) { copy._rightNode = copy.copyChildNode(self._rightNode, limit: limit, queue: _queue) }
            group.wait()
        }
        else {
            copy._leftNode = copy.copyChildNode(_leftNode)
            copy._rightNode = copy.copyChildNode(_rightNode)
        }
        return copy
    }

    @usableFromInline func copyChildNode(_ c: TreeNode<T>?, limit: Int, queue: DispatchQueue) -> TreeNode<T>? {
        guard let _c = c else { return nil }
        let cc = _c.copyTree(limit: (limit - 1), queue: queue)
        cc.parentNode = self
        return cc
    }

    @usableFromInline func copyChildNode(_ c: TreeNode<T>?) -> TreeNode<T>? {
        guard let _c = c else { return nil }
        let cc = _c.copyTree(limit: 0, queue: nil)
        cc.parentNode = self
        return cc
    }

    @usableFromInline func search(compareWith comp: (T) throws -> ComparisonResults) rethrows -> TreeNode<T>? {
        switch try comp(value) {
            case .EqualTo: return self
            case .LessThan: return try leftNode?.search(compareWith: comp)
            case .GreaterThan: return try rightNode?.search(compareWith: comp)
        }
    }

    @usableFromInline func removeAll() {
        if let l = _leftNode {
            l.removeAll()
            _leftNode = nil
        }
        if let r = _rightNode {
            r.removeAll()
            _rightNode = nil
        }
        parentNode = nil
        count = 1
        color = .Black
    }

    @usableFromInline func forEachNode(reverse f: Bool = false, _ body: (TreeNode<T>) throws -> Void) rethrows {
        if let n = (f ? _rightNode : _leftNode) { try n.forEachNode(reverse: f, body) }
        try body(self)
        if let n = (f ? _leftNode : _rightNode) { try n.forEachNode(reverse: f, body) }
    }

    @usableFromInline func firstNode(reverse f: Bool = false, where predicate: (TreeNode<T>) throws -> Bool) rethrows -> TreeNode<T>? {
        if let n = (f ? _rightNode : _leftNode), let m = try n.firstNode(reverse: f, where: predicate) { return m }
        if try predicate(self) { return self }
        if let n = (f ? _leftNode : _rightNode), let m = try n.firstNode(reverse: f, where: predicate) { return m }
        return nil
    }

    @usableFromInline func forEachFast(_ body: (TreeNode<T>) throws -> Void) rethrows {
        if let p = parentNode { try p.forEachFast(body) }
        else { try forEachFast(DispatchQueue(label: UUID().uuidString, attributes: .concurrent), 2, body) }
    }

    @usableFromInline func forEachFast(_ queue: DispatchQueue, _ limit: Int, _ body: (TreeNode<T>) throws -> Void) rethrows {
        if limit > 0 { try forEachFastThreaded(queue, limit - 1, body) }
        else { try forEachNode(reverse: false, body) }
    }

    @usableFromInline func forEachFastThreaded(_ q: DispatchQueue, _ l: Int, _ b: (TreeNode<T>) throws -> Void) rethrows {
        try withoutActuallyEscaping(b) { (c) -> Void in
            var _err: Error?        = nil
            let _grp: DispatchGroup = DispatchGroup()
            let _lck: NSLock        = NSLock()
            q.async(group: _grp) { let e = bar(q, l, self, c); if let _e = e { _lck.withLock { _err = _e } } }
            q.async(group: _grp) { let e = foo(q, l, self._leftNode, c); if let _e = e { _lck.withLock { _err = _e } } }
            q.async(group: _grp) { let e = foo(q, l, self._rightNode, c); if let _e = e { _lck.withLock { _err = _e } } }
            _grp.wait()
            if let e = _err { throw e }
        }
    }

    @usableFromInline func recount() {
        count = (1 + leftCount + rightCount)
        with(node: parentNode) { $0.recount() }
    }

    @inlinable func swapMe(with node: TreeNode<T>?) {
        if let p = parentNode { forPSide(parent: p, ifLeft: { pp in pp[.Left] = node }, ifRight: { pp in pp[.Right] = node }) }
        else if let n = node { n.removeFromParent() }
    }

    @inlinable @discardableResult func removeFromParent() -> TreeNode<T> {
        swapMe(with: nil)
        return self
    }

    @usableFromInline func removeRepair() {
        if let p = parentNode {
            let side: Side        = forSide(parent: p, ifLeft: .Left, ifRight: .Right)
            var sib:  TreeNode<T> = mustHave(p[!side], message: ErrorMsgMissingSibling)

            if sib.color.isRed {
                p.rotate(dir: side)
                sib = mustHave(p[!side], message: ErrorMsgMissingSibling)
            }

            if sib.color.isBlack && Color.isBlack(sib.leftNode) && Color.isBlack(sib.rightNode) {
                sib.color = .Red
                if p.color.isRed { p.color = .Black }
                else { p.removeRepair() }
            }
            else {
                if Color.isRed(sib[side]) { sib.rotate(dir: !side) }
                p.rotate(dir: side)
                if let ps = p.forPSide(ifNeither: nil, ifLeft: { $0._rightNode }, ifRight: { $0._leftNode }) { ps.color = .Black }
            }
        }
    }

    @inlinable func rotate(dir: Side) {
        let c1 = mustHave(self[!dir], message: ((dir == .Left) ? ErrorMsgNoRotLeft : ErrorMsgNoRotRight))
        swapMe(with: c1)
        self[!dir] = c1[dir]
        c1[dir] = self
        swap(&color, &c1.color)
    }

    @usableFromInline func insertRepair() {
        if let p = parentNode {
            if p.color.isRed {
                guard let g = p.parentNode, g.color.isBlack else { fatalError(ErrorMsgMisColored) }
                let nSide = forSide(parent: p, ifLeft: Side.Left, ifRight: Side.Right)
                let pSide = p.forSide(parent: g, ifLeft: Side.Left, ifRight: Side.Right)

                if let u = g[!pSide], u.color.isRed {
                    u.color = .Black
                    p.color = .Black
                    g.color = .Red
                    g.insertRepair()
                }
                else {
                    let q = !nSide
                    if pSide == q {
                        p.rotate(dir: pSide)
                    }
                    g.rotate(dir: !pSide)
                }
            }
        }
        else if color.isRed {
            // This node is the root node so it has to be black.
            color = .Black
        }
    }

    @inlinable func mustHave<P>(_ p: P?, message: String) -> P {
        guard let pp = p else { fatalError(message) }
        return pp
    }

    @inlinable func forSide<R>(parent p: TreeNode<T>, ifLeft l: @autoclosure () throws -> R, ifRight r: @autoclosure () throws -> R) rethrows -> R {
        try forPSide(parent: p, ifLeft: { _ in try l() }, ifRight: { _ in try r() })
    }

    @inlinable func forPSide<R>(ifNeither n: @autoclosure () throws -> R, ifLeft l: (TreeNode<T>) throws -> R, ifRight r: (TreeNode<T>) throws -> R) rethrows -> R {
        guard let p = parentNode else { return try n() }
        return try forPSide(parent: p, ifLeft: l, ifRight: r)
    }

    @inlinable func forPSide<R>(parent p: TreeNode<T>, ifLeft l: (TreeNode<T>) throws -> R, ifRight r: (TreeNode<T>) throws -> R) rethrows -> R {
        if self === p._leftNode { return try l(p) }
        if self === p._rightNode { return try r(p) }
        fatalError(ErrorMsgGhostParent)
    }
}

@inlinable func foo<T>(_ q: DispatchQueue, _ l: Int, _ n: TreeNode<T>?, _ c: @escaping (TreeNode<T>) throws -> Void) -> Error? where T: Equatable & Comparable {
    guard let _n = n else { return nil }
    return bar(q, l, _n, c)
}

@inlinable func bar<T>(_ q: DispatchQueue, _ l: Int, _ n: TreeNode<T>, _ c: @escaping (TreeNode<T>) throws -> Void) -> Error? where T: Equatable & Comparable {
    do {
        try n.forEachFast(q, l, c)
        return nil
    }
    catch let e { return e }
}
