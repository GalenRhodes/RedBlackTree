/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeNode.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: July 30, 2021
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

public class TreeNode<Key, Value> where Key: Comparable {
    @usableFromInline typealias TNode = TreeNode<Key, Value>

    /*==========================================================================================================*/
    /// Colors for the nodes.
    ///
    @usableFromInline enum NodeColor { case Red, Black }

    /*==========================================================================================================*/
    /// Left, Right, or None
    ///
    @usableFromInline enum NodeDirection { case Left, Right, Neither }

    /*==========================================================================================================*/
    /// Key
    ///
    public internal(set) var key:   Key
    /*==========================================================================================================*/
    /// Value
    ///
    public internal(set) var value: Value

    @usableFromInline var _count:     UInt   = 1
    @usableFromInline var _leftNode:  TNode? = nil
    @usableFromInline var _rightNode: TNode? = nil
    @usableFromInline weak var _parentNode: TNode? = nil

    /*==========================================================================================================*/
    /// Creates a new node with the given key, value, and color.
    /// 
    /// - Parameters:
    ///   - key: The key.
    ///   - value: The value.
    ///
    public convenience init(key: Key, value: Value) {
        self.init(key: key, value: value, color: .Black)
    }

    /*==========================================================================================================*/
    /// Creates a new node with the given key, value, and color.
    /// 
    /// - Parameters:
    ///   - key: The key.
    ///   - value: The value.
    ///   - color: The color. Defaults to `NodeColor.Black`.
    ///
    @usableFromInline init(key: Key, value: Value, color: NodeColor) {
        self.key = key
        self.value = value
        self.color = color
    }

    deinit {
        // print("Discarding \(key): \(value)")
    }

    /*==========================================================================================================*/
    /// Get the element associated with the given key.
    /// 
    /// - Parameter key: The key.
    /// - Returns: The value or `nil` if there is no value for that key.
    ///
    public subscript(key: Key) -> TreeNode<Key, Value>? {
        switch compare(key, self.key) {
            case .LessThan:    return leftNode?[key]
            case .GreaterThan: return rightNode?[key]
            case .Equal:       return self
        }
    }

    /*==========================================================================================================*/
    /// Insert the given value associated with the given key into this tree branch.
    /// 
    /// - Parameters:
    ///   - key: The key.
    ///   - value: The value.
    /// - Returns: The new root node for the entire tree.
    ///
    public func insertNode(key: Key, value: Value) -> TreeNode<Key, Value> {
        switch compare(key, self.key) {
            case .LessThan:
                return insertNode(side: .Left, key: key, value: value)
            case .GreaterThan:
                return insertNode(side: .Right, key: key, value: value)
            case .Equal:
                self.value = value
                return rootNode
        }
    }

    /*==========================================================================================================*/
    /// Remove this node.
    /// 
    /// - Returns: The new root node for the entire tree.
    ///
    public func removeNode() -> TreeNode<Key, Value>? {
        if let l = leftNode, let _ = rightNode {
            // The node has two children.
            let n = l.last
            key = n.key
            value = n.value
            return n.removeNode()
        }
        else if let c = leftNode ?? rightNode {
            // The node has one child.
            if c.isRed { c.color = .Black }
            simpleSwap(with: c)
            return c.rootNode
        }
        else if let p = parentNode {
            // The node has no children.
            if isBlack { removeRepair() }
            simpleSwap(with: nil)
            return p.rootNode
        }
        // I have no parent and no children so I just go away.
        return nil
    }

    /*==========================================================================================================*/
    /// Iterate over this branch in-order.
    /// 
    /// - Parameters:
    ///   - backwards: If `true` then the nodes will be iterated in reverse order.
    ///   - body: The closure to execute for each node.
    /// - Throws: Any error thrown by the closure.
    ///
    public func forEach(backwards: Bool = false, _ body: (TreeNode<Key, Value>) throws -> Void) rethrows {
        if backwards {
            if let n = rightNode { try n.forEach(body) }
            try body(self)
            if let n = leftNode { try n.forEach(body) }
        }
        else {
            if let n = leftNode { try n.forEach(body) }
            try body(self)
            if let n = rightNode { try n.forEach(body) }
        }
    }

    /*==========================================================================================================*/
    /// Find the node with the given index. Causes a fatal error if the index is out-of-bounds.
    /// 
    /// - Parameter index: The numeric index.
    /// - Returns: The node with the given index.
    ///
    public func node(forIndex idx: Int) -> TreeNode<Key, Value> {
        func foo(_ n: TNode?) -> TNode {
            guard let n = n else { fatalError("Index out of bounds: \(idx)") }
            return n.node(forIndex: idx)
        }

        return ((idx == index) ? self : foo((idx < index) ? leftNode : rightNode))
    }

    /*==========================================================================================================*/
    /// Returns the first node for which the given predicate returns `true`.
    /// 
    /// - Parameter predicate: The predicate.
    /// - Returns: The node or nil if the predicate never returns `true`.
    /// - Throws: Any error thrown by the closure.
    ///
    public func firstNode(where predicate: (TreeNode<Key, Value>) throws -> Bool) rethrows -> TreeNode<Key, Value>? {
        if let l = leftNode, let n = try l.firstNode(where: predicate) { return n }
        if try predicate(self) { return self }
        if let r = rightNode, let n = try r.firstNode(where: predicate) { return n }
        return nil
    }
}

extension TreeNode {
    /*==========================================================================================================*/
    /// Convenience calculated field to convert the node into a tuple.
    ///
    @inlinable public var       data:       (key: Key, value: Value) { (key: key, value: value) }
    @inlinable public var       isRed:      Bool { color.isRed }
    @inlinable public var       isBlack:    Bool { color.isBlack }
    /*==========================================================================================================*/
    /// This node's index.
    ///
    @inlinable public var       index:      Int {
        switch nSide {
            case .Left:    return parentIndex - rightCount - 1
            case .Right:   return parentIndex + leftCount + 1
            case .Neither: return leftCount
        }
    }
    /*==========================================================================================================*/
    /// The node just before this node (in-order).
    ///
    @inlinable public var       previous:   TreeNode<Key, Value>? { (leftNode?.last ?? previousRising) }
    /*==========================================================================================================*/
    /// The node just after this node (in-order).
    ///
    @inlinable public var       next:       TreeNode<Key, Value>? { (rightNode?.first ?? nextRising) }
    @inlinable public var       first:      TreeNode<Key, Value> { (leftNode?.first ?? self) }
    @inlinable public var       last:       TreeNode<Key, Value> { (rightNode?.last ?? self) }
    /*==========================================================================================================*/
    /// Color
    ///
    @inlinable private(set) var color:      NodeColor {
        get { NodeColor.color(_count & NodeColor.Red.value) }
        set { _count = (newValue.value | (_count & ~NodeColor.Red.value)) }
    }
    /*==========================================================================================================*/
    /// Count of this node (includes all of it's children).
    ///
    @inlinable private(set) var count:      Int {
        get { Int(bitPattern: _count & ~NodeColor.Red.value) }
        set { _count = ((_count & NodeColor.Red.value) | (UInt(bitPattern: newValue) & ~NodeColor.Red.value)) }
    }
    @inlinable public var       parentNode: TreeNode<Key, Value>? { _parentNode }
    @inlinable public private(set) var leftNode:  TreeNode<Key, Value>? {
        get { _leftNode }
        set {
            guard self !== newValue else { fatalError("A node cannot be a child of itself.") }
            guard _leftNode !== newValue else { return }
            if let n = _leftNode { n._parentNode = nil }
            if let n = newValue {
                n.simpleSwap(with: nil)
                n._parentNode = self
            }
            _leftNode = newValue
            recount()
        }
    }
    @inlinable public private(set) var rightNode: TreeNode<Key, Value>? {
        get { _rightNode }
        set {
            guard self !== newValue else { fatalError("A node cannot be a child of itself.") }
            guard _rightNode !== newValue else { return }
            if let n = _rightNode { n._parentNode = nil }
            if let n = newValue {
                n.simpleSwap(with: nil)
                n._parentNode = self
            }
            _rightNode = newValue
            recount()
        }
    }
    /*==========================================================================================================*/
    /// Which side of it's parent is this node on? `NodeDirection.Left`, `NodeDirection.Right`, or
    /// `NodeDirection.Neither` (no parent).
    ///
    @inlinable var nSide:          NodeDirection {
        guard let p = parentNode else { return .Neither }
        return (self === p.leftNode ? .Left : .Right)
    }
    /*==========================================================================================================*/
    /// The number of child nodes on the left side of this node.
    ///
    @inlinable var leftCount:      Int {
        guard let n = leftNode else { return 0 }
        return n.count
    }
    /*==========================================================================================================*/
    /// The number of child nodes on the right side of this node.
    ///
    @inlinable var rightCount:     Int {
        guard let n = rightNode else { return 0 }
        return n.count
    }
    /*==========================================================================================================*/
    /// The index of this node's parent or zero (0) if this node is the root.
    ///
    @inlinable var parentIndex:    Int {
        guard let p = parentNode else { return 0 }
        return p.index
    }
    /*==========================================================================================================*/
    /// This node's sibling.
    ///
    @inlinable var siblingNode:    TNode? {
        guard let p = parentNode else { return nil }
        return p[!nSide]
    }
    /*==========================================================================================================*/
    /// The root node for the tree this node is part of.
    ///
    @inlinable var rootNode:       TNode {
        guard let p = parentNode else { return self }
        return p.rootNode
    }
    /*==========================================================================================================*/
    /// The next node (in-order) going up the tree.
    ///
    @inlinable var nextRising:     TNode? {
        guard let p = parentNode else { return nil }
        return ((self === p.leftNode) ? p : p.nextRising)
    }
    /*==========================================================================================================*/
    /// The previous node (in-order) going up the tree.
    ///
    @inlinable var previousRising: TNode? {
        guard let p = parentNode else { return nil }
        return ((self === p.rightNode) ? p : p.previousRising)
    }

    func removeAll() {
        if let n = leftNode { n.removeAll() }
        if let n = rightNode { n.removeAll() }
        _leftNode = nil
        _rightNode = nil
        _parentNode = nil
        _count = 0
    }

    /*==========================================================================================================*/
    /// Rotate this node. If `NodeDirection.Neither` is given then nothing happens.
    /// 
    /// - Parameter dir: The direction to rotate this node - `NodeDirection.Left`, `NodeDirection.Right`.
    ///
    @inlinable func rotate(toThe dir: NodeDirection) {
        guard dir != .Neither else { fatalError("Which way did you want to rotate the node?") }
        guard let ch = self[!dir] else { fatalError("Cannot rotate \(dir) because there is no \(!dir) child node to take this nodes place.") }
        simpleSwap(with: ch)
        self[!dir] = ch[dir]
        ch[dir] = self
        swap(&color, &ch.color)
    }

    /*==========================================================================================================*/
    /// Insert a new key/value into the given branch.
    /// 
    /// - Parameters:
    ///   - field: The top node of the branch.
    ///   - key: The key.
    ///   - value: The value.
    /// - Returns: The root node.
    ///
    @inlinable func insertNode(side: NodeDirection, key: Key, value: Value) -> TNode {
        if let n = self[side] { return n.insertNode(key: key, value: value) }
        let n = TreeNode<Key, Value>(key: key, value: value, color: .Red)
        self[side] = n
        n.insertRepair()
        return rootNode
    }

    /*==========================================================================================================*/
    /// Re-balance the tree after the insertion of a new node.
    ///
    @usableFromInline func insertRepair() {
        if let p = parentNode {
            if p.isRed {
                if let g = p.parentNode {
                    if let u = p.siblingNode, u.isRed {
                        u.color = .Black
                        p.color = .Black
                        g.color = .Red
                        g.insertRepair()
                    }
                    else {
                        if nSide != p.nSide { p.rotate(toThe: p.nSide) }
                        g.rotate(toThe: !p.nSide)
                    }
                }
                else {
                    // This node's parent is the root so it needs to be black.
                    p.color = .Black
                }
            }
        }
        else if isRed {
            // This node is the root so it needs to be black.
            color = .Black
        }
    }

    /*==========================================================================================================*/
    /// Re-balance the tree after the removal of a node.
    ///
    @usableFromInline func removeRepair() {
        if let p = parentNode {
            let pSide = nSide
            guard siblingNode != nil else { fatalError("Binary Tree Inconsistent.") }

            if (siblingNode?.isRed ?? false) { p.rotate(toThe: pSide) }
            guard let s = siblingNode else { fatalError("Binary Tree Inconsistent.") }

            if s.isBlack && (s.leftNode?.isBlack ?? true) && (s.rightNode?.isBlack ?? true) {
                s.color = .Red
                if p.isBlack { p.removeRepair() }
                else { p.color = .Black }
            }
            else {
                if (s[pSide]?.isRed ?? false) { s.rotate(toThe: !pSide) }
                p.rotate(toThe: pSide)
                p.siblingNode?.color = .Black
            }
        }
    }

    /*==========================================================================================================*/
    /// Force this node and all of it's parent to recount.
    ///
    @usableFromInline func recount() {
        count = (1 + leftCount + rightCount)
        if let p = parentNode { p.recount() }
    }

    /*==========================================================================================================*/
    /// With respect to it's parent, swap this node with the given node. This node will become an orphan. Does not
    /// affect the child nodes of this node nor the other node.
    /// 
    /// - Parameter node: The node to take the place of this node.
    ///
    @inlinable func simpleSwap(with node: TNode?) {
        guard self !== node else { fatalError("Cannot swap a node with itself.") }
        if let p = parentNode { p[nSide] = node }
        else if let n = node, let p = n.parentNode { p[n.nSide] = nil }
    }

    /*==========================================================================================================*/
    /// Get one of this node's children.
    /// 
    /// - Parameter side: Which child node to get.
    /// - Returns: The child node or `nil` if there was no child node on that side or `NodeDirection.Neither` was
    ///            given.
    ///
    @inlinable subscript(side: NodeDirection) -> TNode? {
        get {
            switch side {
                case .Left:    return leftNode
                case .Right:   return rightNode
                case .Neither: return nil
            }
        }
        set {
            switch side {
                case .Left:    leftNode = newValue
                case .Right:   rightNode = newValue
                case .Neither: fatalError("Cannot put a child node on \(side) side of it's parent.")
            }
        }
    }
}

extension TreeNode.NodeDirection {
    /*==========================================================================================================*/
    /// Returns `true` if this node direction is `NodeDirection.Left`.
    ///
    @inlinable var isLeft:  Bool { self == .Left }
    /*==========================================================================================================*/
    /// Returns `true` if this node direction is `NodeDirection.Right`.
    ///
    @inlinable var isRight: Bool { self == .Right }

    /*==========================================================================================================*/
    /// Returns the opposite direction of this node direction.
    /// 
    /// - Parameter op: The `NodeDirection`.
    /// - Returns: `NodeDirection.Left` if `op` is `NodeDirection.Right`. `NodeDirection.Right` if `op` is
    ///            `NodeDirection.Left`. `NodeDirection.Neither` is returned unchanged.
    ///
    @inlinable static prefix func ! (op: TreeNode.NodeDirection) -> TreeNode.NodeDirection {
        switch op {
            case .Left:    return .Right
            case .Right:   return .Left
            case .Neither: return .Neither
        }
    }
}

extension TreeNode.NodeDirection: CustomStringConvertible {
    @inlinable var description: String {
        switch self {
            case .Left:    return "left"
            case .Right:   return "right"
            case .Neither: return "neither"
        }
    }
}

extension TreeNode.NodeColor {
    /*==========================================================================================================*/
    /// Returns `true` if this node color is `NodeColor.Red`.
    ///
    @inlinable var isRed:   Bool { self == .Red }
    /*==========================================================================================================*/
    /// Returns `true` if this node color is `NodeColor.Black`.
    ///
    @inlinable var isBlack: Bool { self == .Black }

    @inlinable var value: UInt {
        switch self {
            case .Red:   return (UInt(1) << (UInt.bitWidth - 1))
            case .Black: return 0
        }
    }

    @inlinable static func color(_ n: UInt) -> Self { (n == 0 ? .Black : .Red) }
}

extension TreeNode.NodeColor: CustomStringConvertible {
    @inlinable var description: String {
        switch self {
            case .Red:   return "red"
            case .Black: return "black"
        }
    }
}

extension TreeNode: CustomStringConvertible {
    @inlinable public var description: String {
        "Node: [ key = \"\(key)\"; value = \"\(value)\"; color = \(color); count = \(count) ]"
    }
}
