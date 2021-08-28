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

let RedMask:   UInt        = (1 << (UInt.bitWidth - 1))
let ColorMask: [UInt]      = [ 0, RedMask ]
let ErrorMsgGhostParent    = "Inconsistent state: ghost parent."
let ErrorMsgMisColored     = "Inconsistent state: mis-colored node."
let ErrorMsgMissingSibling = "Inconsistent state: missing sibling node."
let ErrorMsgLeftOrRight    = "Invalid Argument: side must be either left or right."
let ErrorMsgNoRotLeft      = "Invalid Argument: Cannot rotate node to the left because there is no right child node."
let ErrorMsgNoRotRight     = "Invalid Argument: Cannot rotate node to the right because there is no left child node."
let ErrorMsgParentIsChild  = "Invalid Argument: Node cannot be a child of itself."

public class TreeNode<T>: Comparable where T: Comparable & Equatable {
    //@f:0
    public var rootNode:   TreeNode<T>  { foo(start: self) { $0.parentNode } }
    public var parentNode: TreeNode<T>? { _parentNode                        }
    public var leftNode:   TreeNode<T>? { self[.Left]                        }
    public var rightNode:  TreeNode<T>? { self[.Right]                       }
    public var count:      Int          { _count                             }
    var leftCount:  Int { with(node: _leftNode, default: 0)  { $0._count } }
    var rightCount: Int { with(node: _rightNode, default: 0) { $0._count } }
    var _count:     Int {
        get { Int(bitPattern: Color.maskLo(_data)) }
        set { _data = (Color.maskHi(_data) | Color.maskLo(newValue)) }
    }
    /// The field that holds the value.
    ///
    public internal(set) var value: T
    /// The field that holds the reference to the parent node.
    ///
    var _parentNode: TreeNode<T>? = nil
    /// The field that holds the reference to the right child node.
    ///
    var _rightNode:  TreeNode<T>? = nil
    /// The field that holds the reference to the left child node.
    ///
    var _leftNode:   TreeNode<T>? = nil
    /// To save space this field holds both the color and the count.
    ///
    var _data:       UInt         = 1
    //@f:1

    /// Default public constructor.
    ///
    /// - Parameter v: The value.
    ///
    public init(value v: T) {
        value = v
    }

    convenience init(value v: T, data: UInt) {
        self.init(value: v)
        _data = data
    }

    func _insert(value: T, side: Side) -> TreeNode<T> {
        if let n = self[side] { return n.insert(value: value) }
        let n = _makeNewNode(value: value)
        self[side] = n
        n._insertRepair()
        return n
    }

    func _makeNewNode(value: T) -> TreeNode<T> { TreeNode<T>(value: value, color: .Red) }

    public func insert(value: T) -> TreeNode<T> {
        switch compare(a: value, b: self.value) {
            case .EqualTo:
                self.value = value
                return self
            case .LessThan:
                return _insert(value: value, side: .Left)
            case .GreaterThan:
                return _insert(value: value, side: .Right)
        }
    }

    public func remove() -> TreeNode<T>? {
        if let l = _leftNode, let r = _rightNode {
            // There are two child nodes so we need
            // to swap the value of this node with either
            // the child node that is just before this one
            // or just after this one (we'll randomly pick)
            // and then remove that child node instead.
            let other = (Bool.random() ? foo(start: l) { $0._rightNode } : foo(start: r) { $0._leftNode })
            _swapNodeBeforeRemove(other: other)
            return other.remove()
        }
        else if let c = (_leftNode ?? _rightNode) {
            // There is one child node. This means that this node is
            // black and the child node is red. That's the only way
            // it can be. So we'll just paint the child node black
            // and then remove this node.
            c.color = .Black
            _swapMe(with: c)
            return _postRemoveHook(root: c.rootNode)
        }
        else if let p = parentNode {
            // There are no child nodes but there is a parent node.
            // If this node is black then repair the tree before
            // removing this node.
            if color.isBlack { _removeRepair() }
            // Then remove this node.
            _removeFromParent()
            return _postRemoveHook(root: p.rootNode)
        }
        // There is no parent node and no child nodes which
        // means this is the only existing node so there is
        // nothing to do.
        return _postRemoveHook(root: nil)
    }

    func _postRemoveHook(root: TreeNode<T>?) -> TreeNode<T>? { root }

    func _swapNodeBeforeRemove(other: TreeNode<T>) { swap(&value, &other.value) }

    public enum Color: Int {
        case Black = 0
        case Red

        var isRed:   Bool { self == .Red }
        var isBlack: Bool { self == .Black }

        static func isRed(_ n: TreeNode?) -> Bool { n?.color.isRed ?? false }

        static func isBlack(_ n: TreeNode?) -> Bool { n?.color.isBlack ?? true }

        static func maskLo(_ n: UInt) -> UInt {
            let m: UInt = ~RedMask
            let r: UInt = (n & m)
            return r
        }

        static func maskLo(_ n: Int) -> UInt { maskLo(UInt(bitPattern: n)) }

        static func maskHi(_ n: UInt) -> UInt {
            let m: UInt = RedMask
            let r: UInt = (n & m)
            return r
        }
    }

    var color: Color {
        get { ((Color.maskHi(_data) == 0) ? Color.Black : Color.Red) }
        set { _data = (Color.maskLo(_data) | ColorMask[newValue.rawValue]) }
    }
    /// Copy this tree.  If this node is not the root then this call is transferred to the root.
    ///
    /// - Returns: The root node of the copy.
    ///
    public func copyTree() -> TreeNode<T> {
        if let p = parentNode { return p.copyTree() }
        let queue = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
        return _copyTree(limit: 2, queue: queue)
    }

    func _copyTree(limit: Int, queue: DispatchQueue?) -> TreeNode<T> {
        let copy = TreeNode<T>(value: value, data: _data)
        if let _queue = queue, limit > 0 {
            let group = DispatchGroup()
            _queue.async(group: group) { copy._leftNode = copy._copyChildNode(self._leftNode, limit: limit, queue: _queue) }
            _queue.async(group: group) { copy._rightNode = copy._copyChildNode(self._rightNode, limit: limit, queue: _queue) }
            group.wait()
        }
        else {
            copy._leftNode = copy._copyChildNode(_leftNode)
            copy._rightNode = copy._copyChildNode(_rightNode)
        }
        return copy
    }

    func _copyChildNode(_ c: TreeNode<T>?, limit: Int, queue: DispatchQueue) -> TreeNode<T>? {
        guard let _c = c else { return nil }
        let cc = _c._copyTree(limit: (limit - 1), queue: queue)
        cc._parentNode = self
        return cc
    }

    func _copyChildNode(_ c: TreeNode<T>?) -> TreeNode<T>? {
        guard let _c = c else { return nil }
        let cc = _c._copyTree(limit: 0, queue: nil)
        cc._parentNode = self
        return cc
    }

    public static func < (lhs: TreeNode<T>, rhs: TreeNode<T>) -> Bool { (lhs.value < rhs.value) }

    public static func == (lhs: TreeNode<T>, rhs: TreeNode<T>) -> Bool { (lhs.value == rhs.value) }

    public subscript(value: T) -> TreeNode<T>? {
        switch compare(a: value, b: self.value) {
            case .EqualTo:     return self
            case .LessThan:    return leftNode?[value]
            case .GreaterThan: return rightNode?[value]
        }
    }

    public func find(with comp: (T) throws -> ComparisonResults) rethrows -> TreeNode<T>? {
        switch try comp(value) {
            case .EqualTo: return self
            case .LessThan: return try leftNode?.find(with: comp)
            case .GreaterThan: return try rightNode?.find(with: comp)
        }
    }

    public func removeAll() {
        if let l = _leftNode {
            l.removeAll()
            _leftNode = nil
        }
        if let r = _rightNode {
            r.removeAll()
            _rightNode = nil
        }
        _parentNode = nil
        _count = 1
        color = .Black
    }

    public func forEachNode(reverse f: Bool = false, _ body: (TreeNode<T>) throws -> Void) rethrows {
        if let n = (f ? _rightNode : _leftNode) { try n.forEachNode(reverse: f, body) }
        try body(self)
        if let n = (f ? _leftNode : _rightNode) { try n.forEachNode(reverse: f, body) }
    }

    public func firstNode(reverse f: Bool = false, where predicate: (TreeNode<T>) throws -> Bool) rethrows -> TreeNode<T>? {
        if let n = (f ? _rightNode : _leftNode), let m = try n.firstNode(reverse: f, where: predicate) { return m }
        if try predicate(self) { return self }
        if let n = (f ? _leftNode : _rightNode), let m = try n.firstNode(reverse: f, where: predicate) { return m }
        return nil
    }

    public func forEachFast(_ body: (TreeNode<T>) throws -> Void) rethrows {
        if let p = parentNode { try p.forEachFast(body) }
        else { try forEachFast(DispatchQueue(label: UUID().uuidString, attributes: .concurrent), 2, body) }
    }

    func forEachFast(_ queue: DispatchQueue, _ limit: Int, _ body: (TreeNode<T>) throws -> Void) rethrows {
        if limit > 0 { try forEachFastThreaded(queue, limit - 1, body) }
        else { try forEachSlow(body) }
    }

    func forEachSlow(_ body: (TreeNode<T>) throws -> Void) rethrows {
        try body(self)
        if let n = _leftNode { try n.forEachSlow(body) }
        if let n = _rightNode { try n.forEachSlow(body) }
    }

    func forEachFastThreaded(_ q: DispatchQueue, _ l: Int, _ b: (TreeNode<T>) throws -> Void) rethrows {
        try b(self)
        try withoutActuallyEscaping(b) { (sBody) -> Void in //@f:0
            func foo(_ n: TreeNode<T>?) -> Error? { if let _n = n { do { try _n.forEachFast(q, l, sBody) } catch let e { return e } }; return nil }
            //@f:1
            var _err: Error?        = nil
            let _grp: DispatchGroup = DispatchGroup()
            let _lck: NSLock        = NSLock()
            q.async(group: _grp) { let e = foo(self._leftNode); if let _e = e { _lck.withLock { _err = _e } } }
            q.async(group: _grp) { let e = foo(self._rightNode); if let _e = e { _lck.withLock { _err = _e } } }
            _grp.wait()
            if let e = _err { throw e }
        }
    }

    var index: Index {
        Index(index: _forPSide(ifNeither: leftCount, ifLeft: { $0.index.idx - rightCount - 1 }, ifRight: { $0.index.idx + leftCount + 1 }))
    }

    subscript(index: Index) -> TreeNode<T> {
        guard index.idx >= 0 else { fatalError("Index out of bounds.") }
        switch compare(a: index, b: self.index) {
            case .EqualTo:     return self
            case .LessThan:    if let n = leftNode { return n[index] }
            case .GreaterThan: if let n = rightNode { return n[index] }
        }
        fatalError("Index out of bounds.")
    }

    @frozen public struct Index: Comparable, Hashable {
        let idx: Int

        init(index: Int) { idx = index }

        public func hash(into hasher: inout Hasher) { hasher.combine(idx) }

        public static func == (lhs: Self, rhs: Self) -> Bool { lhs.idx == rhs.idx }

        public static func < (lhs: Self, rhs: Self) -> Bool { lhs.idx < rhs.idx }

        static func + (lhs: Self, rhs: Self) -> Self { lhs + rhs.idx }

        static func - (lhs: Self, rhs: Self) -> Self { lhs - rhs.idx }

        static func + (lhs: Self, rhs: Int) -> Self { Index(index: lhs.idx + rhs) }

        static func + (lhs: Int, rhs: Self) -> Self { Index(index: lhs + rhs.idx) }

        static func - (lhs: Self, rhs: Int) -> Self { Index(index: lhs.idx - rhs) }

        static func - (lhs: Int, rhs: Self) -> Self { Index(index: lhs - rhs.idx) }
    }

    convenience init(value v: T, color c: Color) {
        self.init(value: v)
        color = c
    }

    subscript(side: Side) -> TreeNode<T>? {
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

    func _recount() {
        _count = (1 + leftCount + rightCount)
        with(node: _parentNode) { $0._recount() }
    }

    func _swapMe(with node: TreeNode<T>?) {
        if let p = _parentNode { _forPSide(parent: p, ifLeft: { pp in pp[.Left] = node }, ifRight: { pp in pp[.Right] = node }) }
        else if let n = node { n._removeFromParent() }
    }

    @discardableResult func _removeFromParent() -> TreeNode<T> {
        _swapMe(with: nil)
        return self
    }

    func _removeRepair() {
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

    func _rotate(dir: Side) {
        let c1 = _mustHave(self[!dir], message: ((dir == .Left) ? ErrorMsgNoRotLeft : ErrorMsgNoRotRight))
        _swapMe(with: c1)
        self[!dir] = c1[dir]
        c1[dir] = self
        swap(&color, &c1.color)
    }

    func _insertRepair() {
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

    func _mustHave<P>(_ p: P?, message: String) -> P {
        guard let pp = p else { fatalError(message) }
        return pp
    }

    enum Side {
        case Neither
        case Left
        case Right

        static prefix func ! (s: Self) -> Self {
            switch s {
                case .Neither: return .Neither
                case .Left:    return .Right
                case .Right:   return .Left
            }
        }
    }

    func _forSide<R>(parent p: TreeNode<T>, ifLeft l: @autoclosure () throws -> R, ifRight r: @autoclosure () throws -> R) rethrows -> R {
        try _forPSide(parent: p, ifLeft: { _ in try l() }, ifRight: { _ in try r() })
    }

    func _forPSide<R>(ifNeither n: @autoclosure () throws -> R, ifLeft l: (TreeNode<T>) throws -> R, ifRight r: (TreeNode<T>) throws -> R) rethrows -> R {
        guard let p = _parentNode else { return try n() }
        return try _forPSide(parent: p, ifLeft: l, ifRight: r)
    }

    func _forPSide<R>(parent p: TreeNode<T>, ifLeft l: (TreeNode<T>) throws -> R, ifRight r: (TreeNode<T>) throws -> R) rethrows -> R {
        if self === p._leftNode { return try l(p) }
        if self === p._rightNode { return try r(p) }
        fatalError(ErrorMsgGhostParent)
    }
}

extension TreeNode.Color: CustomStringConvertible, CustomDebugStringConvertible {
    public var description:      String { ((self == .Red) ? "red" : "black") }
    public var debugDescription: String { description }
}

extension TreeNode: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) where T: Hashable { hasher.combine(value) }
}
