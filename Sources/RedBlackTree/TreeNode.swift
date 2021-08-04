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

@usableFromInline class TreeNode<Key, Value> where Key: Comparable {
    /*==========================================================================================================*/
    /// Colors for the nodes.
    ///
    @usableFromInline enum NodeColor { case Red, Black }

    /*==========================================================================================================*/
    /// Left, Right, or Orphan/None
    ///
    @usableFromInline enum NodeDirection { case Left, Right, Orphan }

    //@f:0
    /*==========================================================================================================*/
    /// Key
    ///
    @usableFromInline private(set)      var key:        Key
    /*==========================================================================================================*/
    /// Value
    ///
    @usableFromInline                   var value:      Value
    /*==========================================================================================================*/
    /// Color
    ///
    @usableFromInline private(set)      var color:      NodeColor
    /*==========================================================================================================*/
    /// Count of this node (includes all of it's children).
    ///
    @usableFromInline private(set)      var count:      Int             = 1
    /*==========================================================================================================*/
    /// This node's parent.
    ///
    @usableFromInline private(set) weak var parentNode: TreeNode<Key, Value>? = nil
    /*==========================================================================================================*/
    /// This node's left child.
    ///
    @usableFromInline private(set)      var leftNode:   TreeNode<Key, Value>? = nil { willSet { onWillSet(leftNode, newValue)  } didSet { onDidSet(oldValue, leftNode)  } }
    /*==========================================================================================================*/
    /// This node's right child.
    ///
    @usableFromInline private(set)      var rightNode:  TreeNode<Key, Value>? = nil { willSet { onWillSet(rightNode, newValue) } didSet { onDidSet(oldValue, rightNode) } }
    //@f:1

    @inlinable var data: (key: Key, value: Value) { (key: key, value: value) }

    /*==========================================================================================================*/
    /// Creates a new node with the given key, value, and color.
    /// 
    /// - Parameters:
    ///   - key: The key.
    ///   - value: The value.
    ///   - color: The color. Defaults to `NodeColor.Black`.
    ///
    @usableFromInline init(key: Key, value: Value, color: NodeColor = .Black) {
        self.key = key
        self.value = value
        self.color = color
    }

    /*==========================================================================================================*/
    /// Get the element associated with the given key.
    /// 
    /// - Parameter key: The key.
    /// - Returns: The value or `nil` if there is no value for that key.
    ///
    @usableFromInline subscript(key: Key) -> TreeNode<Key, Value>? { ((key == self.key) ? self : ((key < self.key) ? leftNode : rightNode)?[key]) }

    /*==========================================================================================================*/
    /// Insert the given value associated with the given key into this tree branch.
    /// 
    /// - Parameters:
    ///   - key: The key.
    ///   - value: The value.
    /// - Returns: The new root node for the entire tree.
    ///
    @usableFromInline func insertNode(key: Key, value: Value) -> TreeNode<Key, Value> {
        if key == self.key {
            self.value = value
        }
        else if key < self.key {
            if let ln = leftNode { return ln.insertNode(key: key, value: value) }
            let node = TreeNode<Key, Value>(key: key, value: value, color: .Red)
            leftNode = node
            node.insertBalance()
        }
        else {
            if let rn = rightNode { return rn.insertNode(key: key, value: value) }
            let node = TreeNode<Key, Value>(key: key, value: value, color: .Red)
            rightNode = node
            node.insertBalance()
        }
        return rootNode
    }

    /*==========================================================================================================*/
    /// Re-balance the tree after the insertion of a new node.
    ///
    private func insertBalance() {
        if let p = parentNode {
            if p.color.isRed {
                if let g = p.parentNode {
                    if let u = p.siblingNode, u.color.isRed {
                        u.color = .Black
                        p.color = .Black
                        g.color = .Red
                        g.insertBalance()
                    }
                    else {
                        let pSide = p.parentSide
                        if parentSide != pSide { p.rotate(toThe: pSide) }
                        g.rotate(toThe: !pSide)
                    }
                }
                else {
                    p.color = .Black
                }
            }
        }
        else if color.isRed {
            // This node is the root so it needs to be black.
            color = .Black
        }
    }

    /*==========================================================================================================*/
    /// Remove this node.
    /// 
    /// - Returns: The new root node for the entire tree.
    ///
    @usableFromInline func removeNode() -> TreeNode<Key, Value>? {
        if var c = leftNode, let _ = rightNode {
            // The node has two children.
            while let r = c.rightNode { c = r }
            key = c.key
            value = c.value
            return c.removeNode()
        }
        else if let c = leftNode ?? rightNode {
            // The node has one child.
            if c.color.isRed { c.color = .Black }
            swap(with: c)
            return c.rootNode
        }
        else if let p = parentNode {
            // The node has no children.
            if color.isBlack { removeBalance() }
            makeOrphan()
            return p.rootNode
        }
        // I have no parent and no children so I just go away.
        return nil
    }

    /*==========================================================================================================*/
    /// Re-balance the tree after the removal of a node.
    ///
    private func removeBalance() {
        if let p = parentNode {
            let pSide = parentSide
            guard siblingNode != nil else { fatalError("Binary Tree Inconsistent.") }

            if NodeColor.isRed(siblingNode) { p.rotate(toThe: pSide) }
            guard let s = siblingNode else { fatalError("Binary Tree Inconsistent.") }

            if NodeColor.isBlack(s) && NodeColor.isBlack(s.leftNode) && NodeColor.isBlack(s.rightNode) {
                if NodeColor.isBlack(p) { p.removeBalance() }
                else { Swift.swap(&p.color, &s.color) }
            }
            else {
                if NodeColor.isRed(pSide.isLeft ? s.leftNode : s.rightNode) { s.rotate(toThe: !pSide) }
                p.rotate(toThe: pSide)
                p.siblingNode?.color = .Black
            }
        }
    }

    /*==========================================================================================================*/
    /// Iterate over this branch in-order.
    /// 
    /// - Parameters:
    ///   - backwards: If `true` then the nodes will be iterated in reverse order.
    ///   - body: The closure to execute for each node.
    /// - Throws: Any error thrown by the closure.
    ///
    @usableFromInline func forEach(backwards: Bool = false, _ body: (TreeNode<Key, Value>) throws -> Void) rethrows {
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
    @usableFromInline func node(forIndex idx: Int) -> TreeNode<Key, Value> {
        if idx < self.index {
            guard let n = leftNode else { fatalError("Index out of bounds: \(idx)") }
            return n.node(forIndex: idx)
        }
        if idx > self.index {
            guard let n = rightNode else { fatalError("Index out of bounds: \(idx)") }
            return n.node(forIndex: idx)
        }
        return self
    }
}

extension TreeNode {
    //@f:0
    /*==========================================================================================================*/
    /// The root node for the tree this node is part of.
    ///
    @inlinable var rootNode:    TreeNode<Key, Value>  { ((parentNode == nil) ? self : parentNode!.rootNode)                                                   }
    /*==========================================================================================================*/
    /// This node's sibling.
    ///
    @inlinable var siblingNode: TreeNode<Key, Value>? { forSide(l: { parentNode!.rightNode }, r: { parentNode!.leftNode }, o: { nil })                        }
    /*==========================================================================================================*/
    /// Which side of it's parent is this node on? `NodeDirection.Left`, `NodeDirection.Right`, or
    /// `NodeDirection.Orphan` (no parent).
    ///
    @inlinable var parentSide:  NodeDirection   { guard let p = parentNode else { return .Orphan }; return ((self === p.leftNode) ? .Left : .Right)     }
    /*==========================================================================================================*/
    /// The number of child nodes on the left side of this node.
    ///
    @inlinable var leftCount:   Int             { (leftNode?.count ?? 0)                                                                                }
    /*==========================================================================================================*/
    /// The number of child nodes on the right side of this node.
    ///
    @inlinable var rightCount:  Int             { (rightNode?.count ?? 0)                                                                               }
    /*==========================================================================================================*/
    /// The index of this node's parent or zero (0) if this node is the root.
    ///
    @inlinable var parentIndex: Int             { (parentNode?.index ?? 0)                                                                              }
    /*==========================================================================================================*/
    /// This node's index.
    ///
    @inlinable var index:       Int             { forSide(l: { (parentIndex - leftCount - 1) }, r: { (parentIndex + leftCount + 1) }, o: { leftCount }) }
    /*==========================================================================================================*/
    /// The node just before this node (in-order).
    ///
    @inlinable var previous:    TreeNode<Key, Value>? { (leftNode?.prevFalling ?? prevRising)                                                                 }
    /*==========================================================================================================*/
    /// The node just after this node (in-order).
    ///
    @inlinable var next:        TreeNode<Key, Value>? { (rightNode?.nextFalling ?? nextRising)                                                                }
    //@f:1

    /*==========================================================================================================*/
    /// The next node (in-order) going down the tree.
    ///
    @usableFromInline var nextFalling: TreeNode {
        guard let l = leftNode else { return self }
        return l.nextFalling
    }

    /*==========================================================================================================*/
    /// The next node (in-order) going up the tree.
    ///
    @usableFromInline var nextRising: TreeNode? {
        guard let p = parentNode else { return nil }
        return ((self === p.leftNode) ? p : p.nextRising)
    }

    /*==========================================================================================================*/
    /// The previous node (in-order) going down the tree.
    ///
    @usableFromInline var prevFalling: TreeNode<Key, Value> {
        guard let r = rightNode else { return self }
        return r.prevFalling
    }

    /*==========================================================================================================*/
    /// The previous node (in-order) going up the tree.
    ///
    @usableFromInline var prevRising: TreeNode<Key, Value>? {
        guard let p = parentNode else { return nil }
        return ((self === p.rightNode) ? p : p.prevRising)
    }

    /*==========================================================================================================*/
    /// Force this node and all of it's parent to recount.
    ///
    @usableFromInline func recount() {
        count = (1 + leftCount + rightCount)
        if let p = parentNode { p.recount() }
    }

    /*==========================================================================================================*/
    /// Make this node an orphan - unlink it from it's parent.
    ///
    @inlinable func makeOrphan() {
        guard let p = parentNode else { return }
        if self === p.leftNode { p.leftNode = nil }
        else { p.rightNode = nil }
        parentNode = nil
        p.recount()
    }

    /*==========================================================================================================*/
    /// `willSet` handler for `TreeNode<Key,Value>.leftNode` and `TreeNode<Key,Value>.rightNode`.
    /// 
    /// - Parameters:
    ///   - oldValue: The old (current) value.
    ///   - newValue: The new value.
    ///
    @inlinable func onWillSet(_ oldValue: TreeNode<Key, Value>?, _ newValue: TreeNode<Key, Value>?) {
        guard oldValue !== newValue else { return }
        if let nv = newValue { nv.makeOrphan() }
    }

    /*==========================================================================================================*/
    /// `didSet` handler for `TreeNode<Key,Value>.leftNode` and `TreeNode<Key,Value>.rightNode`.
    /// 
    /// - Parameters:
    ///   - oldValue: The old value.
    ///   - newValue: The new (current) value.
    ///
    @inlinable func onDidSet(_ oldValue: TreeNode<Key, Value>?, _ newValue: TreeNode<Key, Value>?) {
        guard oldValue !== newValue else { return }
        if let ov = oldValue { ov.parentNode = nil }
        if let nv = newValue { nv.parentNode = self }
        recount()
    }

    /*==========================================================================================================*/
    /// Execute one of the three given closures depending on the value of `side` - `NodeDirection.Left`,
    /// `NodeDirection.Right`, or `NodeDirection.Orphan`.
    /// 
    /// - Parameters:
    ///   - side: The side.
    ///   - l: The closure to execute if `side` is `NodeDirection.Left`.
    ///   - r: The closure to execute if `side` is `NodeDirection.Right`.
    ///   - o: The closure to execute if `side` is `NodeDirection.Orphan`.
    /// - Returns: The results returned from the executed closure.
    ///
    @inlinable func forSide<T>(side: NodeDirection, l: () -> T, r: () -> T, o: () -> T) -> T {
        switch side {
            case .Left:   return l()
            case .Right:  return r()
            case .Orphan: return o()
        }
    }

    /*==========================================================================================================*/
    /// Execute one of the three given closures depending on which side of it's parent its on -
    /// `NodeDirection.Left`, `NodeDirection.Right`, or `NodeDirection.Orphan` (no parent).
    /// 
    /// - Parameters:
    ///   - l: The closure to execute if this node is on the left side of it's parent.
    ///   - r: The closure to execute if this node is on the right side of it's parent.
    ///   - o: The closure to execute if this node has no parent.
    /// - Returns: The results returned from the executed closure.
    ///
    @inlinable func forSide<T>(l: () -> T, r: () -> T, o: () -> T) -> T { forSide(side: parentSide, l: l, r: r, o: o) }

    /*==========================================================================================================*/
    /// With respect to it's parent, swap this node with the given node. This node will become an orphan. Does not
    /// affect the child nodes of this node nor the other node.
    /// 
    /// - Parameter node: The node to take the place of this node.
    ///
    @inlinable func swap(with node: TreeNode<Key, Value>?) { forSide(l: { parentNode!.leftNode = node }, r: { parentNode!.rightNode = node }, o: {}) }

    /*==========================================================================================================*/
    /// Rotate this node. If `NodeDirection.Orphan` is given then nothing happens.
    /// 
    /// - Parameter dir: The direction to rotate this node - `NodeDirection.Left`, `NodeDirection.Right`.
    ///
    @inlinable func rotate(toThe dir: NodeDirection) { forSide(side: dir, l: { rotateLeft() }, r: { rotateRight() }, o: {}) }

    /*==========================================================================================================*/
    /// Rotate this node to the left. This node must have a right child node or a fatal error is thrown.
    ///
    @usableFromInline func rotateLeft() {
        guard let rn = rightNode else { fatalError("Cannot rotate left because there is no right child node to take this nodes place.") }
        swap(with: rn)
        rightNode = rn.leftNode
        rn.leftNode = self
        Swift.swap(&color, &rn.color)
    }

    /*==========================================================================================================*/
    /// Rotate this node to the right. This node must have a left child node or a fatal error is thrown.
    ///
    @usableFromInline func rotateRight() {
        guard let ln = leftNode else { fatalError("Cannot rotate right because there is no left child node to take this nodes place.") }
        swap(with: ln)
        leftNode = ln.rightNode
        ln.rightNode = self
        Swift.swap(&color, &ln.color)
    }

    /*==========================================================================================================*/
    /// Returns the first node for which the given predicate returns `true`.
    /// 
    /// - Parameter predicate: The predicate.
    /// - Returns: The node or nil if the predicate never returns `true`.
    /// - Throws: Any error thrown by the closure.
    ///
    @inlinable func firstNode(where predicate: (TreeNode<Key, Value>) throws -> Bool) rethrows -> TreeNode<Key, Value>? {
        if let l = leftNode, let n = try l.firstNode(where: predicate) { return n }
        if try predicate(self) { return self }
        if let r = rightNode, let n = try r.firstNode(where: predicate) { return n }
        return nil
    }
}

extension TreeNode: Equatable where Value: Equatable {
    /*==========================================================================================================*/
    /// Test two nodes to see if their keys and values are equal.
    /// 
    /// - Parameters:
    ///   - lhs: The left-hand node.
    ///   - rhs: The right-hand node.
    /// - Returns: `true` if the two node's keys and values are equal.
    ///
    @usableFromInline static func == (lhs: TreeNode<Key, Value>, rhs: TreeNode<Key, Value>) -> Bool { ((lhs === rhs) || ((lhs.key == rhs.key) && (lhs.value == rhs.value))) }
}

extension TreeNode: Hashable where Key: Hashable, Value: Hashable {
    /*==========================================================================================================*/
    /// Gets the hash of this node.
    /// 
    /// - Parameter hasher: the hasher.
    ///
    @inlinable func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(value)
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
    ///            `NodeDirection.Left`. `NodeDirection.Orphan` is returned unchanged.
    ///
    @inlinable static prefix func ! (op: TreeNode.NodeDirection) -> TreeNode.NodeDirection {
        switch op {
            case .Left:   return .Right
            case .Right:  return .Left
            case .Orphan: return .Orphan
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

    /*==========================================================================================================*/
    /// Returns `true` if the given node's color is `NodeColor.Red`.
    /// 
    /// - Parameter node: the node to check.
    /// - Returns: `true` if the node's color is red or `false` if `nil` is passed or the given node is black.
    ///
    @inlinable static func isRed<K, V>(_ node: TreeNode<K, V>?) -> Bool { (node?.color.isRed ?? false) }

    /*==========================================================================================================*/
    /// Returns `true` if the given node's color is NodeColor.Black.
    /// 
    /// - Parameter node: the node to check.
    /// - Returns: `true` if `nil` or the given node's color is black or `false` if the given node is red.
    ///
    @inlinable static func isBlack<K, V>(_ node: TreeNode<K, V>?) -> Bool { (node?.color.isBlack ?? true) }
}
