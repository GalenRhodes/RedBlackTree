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

@usableFromInline let RedMask:                  UInt   = (1 << (UInt.bitWidth - 1))
@usableFromInline let CountMask:                UInt   = ~RedMask
@usableFromInline let ColorMask:                [UInt] = [ 0, RedMask ]
@usableFromInline let ErrorMsgGhostParent:      String = "Inconsistent state: ghost parent."
@usableFromInline let ErrorMsgMisColored:       String = "Inconsistent state: mis-colored node."
@usableFromInline let ErrorMsgMissingSibling:   String = "Inconsistent state: missing sibling node."
@usableFromInline let ErrorMsgMissingParent:    String = "Inconsistent state: missing parent node."
@usableFromInline let ErrorMsgLeftOrRight:      String = "Invalid Argument: side must be either left or right."
@usableFromInline let ErrorMsgNoRotLeft:        String = "Invalid Argument: Cannot rotate node to the left because there is no right child node."
@usableFromInline let ErrorMsgNoRotRight:       String = "Invalid Argument: Cannot rotate node to the right because there is no left child node."
@usableFromInline let ErrorMsgParentIsChild:    String = "Invalid Argument: Node cannot be a child of itself."
@usableFromInline let ErrorMsgIndexOutOfBounds: String = "Index out of bounds."

@usableFromInline class TreeNode<T> where T: Comparable {
    @usableFromInline typealias TNode = TreeNode<T>
    @usableFromInline typealias Index = TreeIndex
    @usableFromInline typealias InsertResults = (node: TNode, inserted: Bool, existed: Bool, oldValue: T)

    //@f:0
    /*==========================================================================================================*/
    /// The field that holds the value.
    ///
    @usableFromInline                  var value:      T
    /*==========================================================================================================*/
    /// The field that holds the reference to the parent node.
    ///
    @usableFromInline fileprivate(set) var parentNode: TNode? = nil
    /*==========================================================================================================*/
    /// The field that holds the reference to the right child node.
    ///
    @usableFromInline fileprivate(set) var rightNode:  TNode? = nil
    /*==========================================================================================================*/
    /// The field that holds the reference to the left child node.
    ///
    @usableFromInline fileprivate(set) var leftNode:   TNode? = nil
    /*==========================================================================================================*/
    /// To save space this field holds both the color and the count.
    ///
    @usableFromInline fileprivate(set) var data:       UInt         = 1
    //@f:1

    /*==========================================================================================================*/
    /// Default constructor.
    ///
    /// - Parameter v: The value.
    ///
    @usableFromInline init(value v: T) { value = v }

    @usableFromInline func makeNewNode(value: T) -> TNode { TNode(value: value, color: .Red) }

    @usableFromInline func makeNewNode(value: T, data: UInt) -> TNode { TNode(value: value, data: data) }

    @usableFromInline func postRemoveHook(root: TNode?) -> TNode? { root }

    @usableFromInline func swapNodeBeforeRemove(other: TNode) {
        let v = value
        value = other.value
        other.value = v
    }

    @usableFromInline func removeAll() {
        with(leftNode) { $0.removeAll() }
        with(rightNode) { $0.removeAll() }
        parentNode = nil
        rightNode = nil
        leftNode = nil
    }

    @usableFromInline enum Color: Int {
        case Black = 0, Red = 1
    }

    @usableFromInline enum Side {
        case Neither, Left, Right
    }
}

extension TreeNode {
    //@f:0
    @inlinable                  var lc:         Int    { nilTest(rightNode,  whenNil: 0)    { (n: TNode) in n.count    }                                                                     }
    @inlinable                  var rc:         Int    { nilTest(leftNode,   whenNil: 0)    { (n: TNode) in n.count    }                                                                     }
    @inlinable                  var rootNode:   TNode  { nilTest(parentNode, whenNil: self) { (n: TNode) in n.rootNode }                                                                     }
    @inlinable                  var index:      Index  { Index(nilTest(parentNode, whenNil: rc) { (n: TNode) in ((self === n.leftNode) ? (n.index.idx - lc - 1) : (n.index.idx + rc + 1)) }) }
    @inlinable fileprivate(set) var count:      Int    { get { Int(bitPattern: data & CountMask)         } set { data = ((data & RedMask) | (UInt(bitPattern: newValue) & CountMask)) }      }
    @inlinable fileprivate(set) var color:      Color  { get { (((data & RedMask) == 0) ? .Black : .Red) } set { data = ((data & CountMask) | ColorMask[newValue.rawValue])           }      }
    //@f:1

    @inlinable convenience init(value v: T, data: UInt) {
        self.init(value: v)
        self.data = data
    }

    @inlinable convenience init(value v: T, color c: Color) {
        self.init(value: v)
        color = c
    }

    @inlinable subscript(value: T) -> TNode? {
        switch compare(a: value, b: self.value) {
            case .EqualTo:     return self
            case .LessThan:    return nilTest(leftNode, whenNil: nil) { (n: TNode) in n[value] }
            case .GreaterThan: return nilTest(rightNode, whenNil: nil) { (n: TNode) in n[value] }
        }
    }

    @inlinable subscript(index: Index) -> TNode {
        guard index.idx >= 0 else { fatalError(ErrorMsgIndexOutOfBounds) }
        switch compare(a: index, b: self.index) {
            case .EqualTo:     return self
            case .LessThan:    return nilTest(leftNode, whenNil: ErrorMsgIndexOutOfBounds) { (n: TNode) in n[index] }
            case .GreaterThan: return nilTest(rightNode, whenNil: ErrorMsgIndexOutOfBounds) { (n: TNode) in n[index] }
        }
    }

    @usableFromInline func insert(update f: Bool, value v: T) -> InsertResults {
        switch compare(a: v, b: value) {
            case .EqualTo:
                guard f else { return (self, false, true, value) }
                let ov = value
                value = v
                return (self, true, true, ov)
            case .LessThan:
                return nilTest(leftNode, whenNil: add(value: v, toSide: .Left)) { (n: TNode) in n.insert(update: f, value: v) }
            case .GreaterThan:
                return nilTest(rightNode, whenNil: add(value: v, toSide: .Right)) { (n: TNode) in n.insert(update: f, value: v) }
        }
    }

    @inlinable func add(value v: T, toSide side: Side) -> InsertResults {
        let n = makeNewNode(value: v)
        self[side] = n
        n.insertRepair()
        return (n, true, false, v)
    }

    @usableFromInline func remove() -> TNode? {
        if let l = leftNode, let r = rightNode {
            // There are two child nodes so we need
            // to swap the value of this node with either
            // the child node that is just before this one
            // or just after this one (we'll randomly pick)
            // and then remove that child node instead.
            let other = (Bool.random() ? foo(start: l) { $0.rightNode } : foo(start: r) { $0.leftNode })
            swapNodeBeforeRemove(other: other)
            return other.remove()
        }
        else if let c = (leftNode ?? rightNode) {
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

    /*==========================================================================================================*/
    /// Copy this tree.  If this node is not the root then this call is transferred to the root.
    ///
    /// - Returns: The root node of the copy.
    ///
    @inlinable func copyTree(fast: Bool) -> TNode {
        if let p = parentNode { return p.copyTree(fast: fast) }
        guard fast && count > 100 else { return copyTreeSlow() }
        let queue = DispatchQueue(label: UUID.new, attributes: .concurrent)
        return copyTree(limit: 1, queue: queue)
    }

    /*==========================================================================================================*/
    /// Copy this tree slowly.  If this node is not the root then this call is transferred to the root.
    ///
    /// - Returns: The root node of the copy.
    ///
    @usableFromInline func copyTreeSlow() -> TNode {
        let copy = makeNewNode(value: value, data: data)
        copy.leftNode = copy.copyChild(child: leftNode)
        copy.rightNode = copy.copyChild(child: rightNode)
        return copy
    }

    @inlinable func copyTree(limit: Int, queue: DispatchQueue) -> TNode {
        let group = DispatchGroup()
        let copy  = makeNewNode(value: value, data: data)
        queue.async(group: group) { copy.leftNode = copy.copyChild(child: self.leftNode) }
        queue.async(group: group) { copy.rightNode = copy.copyChild(child: self.rightNode) }
        group.wait()
        return copy
    }

    @inlinable func copyChild(child: TNode?) -> TNode? {
        guard let c = child else { return nil }
        let cc = c.copyTreeSlow()
        cc.parentNode = self
        return cc
    }

    @usableFromInline func search(using comp: (T) throws -> ComparisonResults) rethrows -> TNode? {
        switch try comp(value) {
            case .EqualTo: return self
            case .LessThan: return try leftNode?.search(using: comp)
            case .GreaterThan: return try rightNode?.search(using: comp)
        }
    }

    @usableFromInline func forEachNode(reverse f: Bool = false, _ body: (TNode) throws -> Void) rethrows {
        try (f ? rightNode : leftNode)?.forEachNode(reverse: f, body)
        try body(self)
        try (f ? leftNode : rightNode)?.forEachNode(reverse: f, body)
    }

    @usableFromInline func firstNode(reverse f: Bool = false, where predicate: (TNode) throws -> Bool) rethrows -> TNode? {
        if let m = try (f ? rightNode : leftNode)?.firstNode(reverse: f, where: predicate) { return m }
        if try predicate(self) { return self }
        if let m = try (f ? leftNode : rightNode)?.firstNode(reverse: f, where: predicate) { return m }
        return nil
    }

    @usableFromInline func forEachFast(_ body: (TNode) -> Void) {
        if let p = parentNode { return p.forEachFast(body) }
        withoutActuallyEscaping(body) { (b: @escaping (TNode) -> Void) -> Void in
            let q = DispatchQueue(label: UUID.new, attributes: .concurrent)
            let g = DispatchGroup()
            q.async(group: g) { b(self) }
            q.async(group: g) { self.leftNode?.forEachNode(b) }
            q.async(group: g) { self.rightNode?.forEachNode(b) }
            g.wait()
        }
    }

    @usableFromInline func recount() {
        count = (1 + rc + lc)
        with(parentNode) { $0.recount() }
    }

    @inlinable func swapMe(with node: TNode?) { nilTest(parentNode, whenNil: with(node) { $0.removeFromParent() }) { (p: TNode) in p[Side.side(self)] = node } }

    @inlinable @discardableResult func removeFromParent() -> TNode { swapMe(with: nil); return self }

    @inlinable subscript(side: Side) -> TNode? {
        get {
            guard !side.isNeither else { fatalError(ErrorMsgLeftOrRight) }
            return (side.isLeft ? leftNode : rightNode)
        }
        set {
            guard self !== newValue else { fatalError(ErrorMsgParentIsChild) }
            let c = self[side]
            if newValue !== c {
                with(c) { $0.parentNode = nil }
                with(newValue) { $0.removeFromParent().parentNode = self }
                condExec(side.isLeft, yes: { leftNode = newValue }, no: { rightNode = newValue })
                recount()
            }
        }
    }

    @inlinable func rotate(dir: Side) {
        let c1 = mustHave(self[!dir], message: ((dir.isLeft) ? ErrorMsgNoRotLeft : ErrorMsgNoRotRight))
        swapMe(with: c1)
        self[!dir] = c1[dir]
        c1[dir] = self
        let c = color
        color = c1.color
        c1.color = c
    }

    @usableFromInline func removeRepair() {
        guard let p = parentNode else { return }
        let side = Side.side(self)
        if mustHave(p[!side], message: ErrorMsgMissingSibling).color.isRed { p.rotate(dir: side) }

        let sib = mustHave(p[!side], message: ErrorMsgMissingSibling)
        if sib.color.isBlack && Color.isBlack(sib.leftNode) && Color.isBlack(sib.rightNode) {
            sib.color = .Red
            condExec(p.color.isRed, yes: { p.color = .Black }, no: { p.removeRepair() })
        }
        else {
            if Color.isRed(sib[side]) { sib.rotate(dir: !side) }
            p.rotate(dir: side)
            p.parentNode![!side]!.color = .Black
        }
    }

    @usableFromInline func insertRepair() {
        guard let p = parentNode else { color = .Black; return }
        guard p.color.isRed else { return }
        guard let g = p.parentNode, g.color.isBlack else { fatalError(ErrorMsgMisColored) }

        let pSide = Side.side(p)
        guard let u = g[!pSide], u.color.isRed else {
            if pSide == !Side.side(self) { p.rotate(dir: pSide) }
            return g.rotate(dir: !pSide)
        }

        u.color = .Black
        p.color = .Black
        g.color = .Red
        g.insertRepair()
    }

    @inlinable func mustHave<P>(_ p: P?, message: String) -> P {
        if let pp = p { return pp }
        fatalError(message)
    }
}

extension TreeNode.Color {
    @inlinable var isRed:   Bool { self == .Red }
    @inlinable var isBlack: Bool { self == .Black }

    @inlinable static func isRed(_ n: TreeNode<T>?) -> Bool { nilTest(n, whenNil: false, whenNotNil: { (n: TreeNode<T>) in ((n.data & RedMask) == RedMask) }) }

    @inlinable static func isBlack(_ n: TreeNode<T>?) -> Bool { nilTest(n, whenNil: true, whenNotNil: { (n: TreeNode<T>) in ((n.data & RedMask) == 0) }) }
}

extension TreeNode.Side {
    @inlinable var isLeft:    Bool { self == .Left }
    @inlinable var isRight:   Bool { self == .Right }
    @inlinable var isNeither: Bool { self == .Neither }

    @inlinable static func side(_ node: TreeNode<T>) -> Self {
        nilTest(node.parentNode, whenNil: .Neither) { (p: TreeNode<T>) in
            ((node === p.leftNode) ? .Left : .Right)
        }
    }

    @inlinable static prefix func ! (s: Self) -> Self { (s.isLeft ? .Right : (s.isRight ? .Left : .Neither)) }
}
