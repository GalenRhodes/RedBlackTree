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

@usableFromInline class TreeNode<K, V> where K: Comparable & Hashable {
    @usableFromInline enum NodeColor { case Red, Black }

    @usableFromInline enum NodeDirection { case Left, Right, Orphan }

    //@f:0
    @usableFromInline private(set) var key:        K
    @usableFromInline private(set) var value:      V
    @usableFromInline private(set) var color:      NodeColor
    @usableFromInline private(set) var count:      Int             = 1
    @usableFromInline private(set) var parentNode: TreeNode<K, V>? = nil
    @usableFromInline private(set) var leftNode:   TreeNode<K, V>? = nil { willSet { onWillSet(leftNode, newValue)  } didSet { onDidSet(oldValue, leftNode)  } }
    @usableFromInline private(set) var rightNode:  TreeNode<K, V>? = nil { willSet { onWillSet(rightNode, newValue) } didSet { onDidSet(oldValue, rightNode) } }
    //@f:1

    init(key: K, value: V, color: NodeColor = .Black) {
        self.key = key
        self.value = value
        self.color = color
    }

    subscript(key: K) -> TreeNode<K, V>? { ((key == self.key) ? self : ((key < self.key) ? leftNode : rightNode)?[key]) }

    @usableFromInline func insertNode(key: K, value: V) -> TreeNode<K, V> {
        if key == self.key {
            self.value = value
        }
        else if key < self.key {
            if let ln = leftNode { return ln.insertNode(key: key, value: value) }
            let node = TreeNode<K, V>(key: key, value: value, color: .Red)
            leftNode = node
            node.insertBalance()
        }
        else {
            if let rn = rightNode { return rn.insertNode(key: key, value: value) }
            let node = TreeNode<K, V>(key: key, value: value, color: .Red)
            rightNode = node
            node.insertBalance()
        }
        return rootNode
    }

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

    @usableFromInline func removeNode() -> TreeNode<K, V>? {
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

    @usableFromInline func forEach(backwards: Bool = false, _ body: (TreeNode<K, V>) throws -> Void) rethrows -> Void {
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

    @usableFromInline func find(index: Int) -> TreeNode<K, V> {
        if index < self.index {
            guard let n = leftNode else { fatalError("Index out of bounds: \(index)") }
            return n.find(index: index)
        }
        if index > self.index {
            guard let n = rightNode else { fatalError("Index out of bounds: \(index)") }
            return n.find(index: index)
        }
        return self
    }
}

extension TreeNode {
    //@f:0
    @inlinable var rootNode:    TreeNode<K, V>  { ((parentNode == nil) ? self : parentNode!.rootNode)                                                   }
    @inlinable var siblingNode: TreeNode<K, V>? { forSide(l: { parentNode!.rightNode }, r: { parentNode!.leftNode }, o: { nil })                        }
    @inlinable var parentSide:  NodeDirection   { guard let p = parentNode else { return .Orphan }; return ((self === p.leftNode) ? .Left : .Right)     }
    @inlinable var leftCount:   Int             { (leftNode?.count ?? 0)                                                                                }
    @inlinable var rightCount:  Int             { (rightNode?.count ?? 0)                                                                               }
    @inlinable var parentIndex: Int             { (parentNode?.index ?? 0)                                                                              }
    @inlinable var index:       Int             { forSide(l: { (parentIndex - leftCount - 1) }, r: { (parentIndex + leftCount + 1) }, o: { leftCount }) }
    @inlinable var previous:    TreeNode<K, V>? { (leftNode?.prevFalling ?? prevRising)                                                                 }
    @inlinable var next:        TreeNode<K, V>? { (rightNode?.nextFalling ?? nextRising)                                                                }
    //@f:1

    @usableFromInline var nextFalling: TreeNode? {
        guard let l = leftNode else { return self }
        return l.nextFalling
    }

    @usableFromInline var nextRising: TreeNode? {
        guard let p = parentNode else { return nil }
        return ((self === p.leftNode) ? p : p.nextRising)
    }

    @usableFromInline var prevFalling: TreeNode<K, V>? {
        guard let r = rightNode else { return self }
        return r.prevFalling
    }

    @usableFromInline var prevRising: TreeNode<K, V>? {
        guard let p = parentNode else { return nil }
        return ((self === p.rightNode) ? p : p.prevRising)
    }

    @usableFromInline func recount() {
        count = (1 + leftCount + rightCount)
        if let p = parentNode { p.recount() }
    }

    @inlinable func makeOrphan() {
        guard let p = parentNode else { return }
        if self === p.leftNode { p.leftNode = nil }
        else { p.rightNode = nil }
        parentNode = nil
        p.recount()
    }

    @inlinable func onWillSet(_ oldValue: TreeNode<K, V>?, _ newValue: TreeNode<K, V>?) {
        guard oldValue !== newValue else { return }
        if let nv = newValue { nv.makeOrphan() }
    }

    @inlinable func onDidSet(_ oldValue: TreeNode<K, V>?, _ newValue: TreeNode<K, V>?) {
        guard oldValue !== newValue else { return }
        if let ov = oldValue { ov.parentNode = nil }
        if let nv = newValue { nv.parentNode = self }
        recount()
    }

    @inlinable func forSide<T>(side: NodeDirection, l: () -> T, r: () -> T, o: () -> T) -> T {
        switch side {
            case .Left:   return l()
            case .Right:  return r()
            case .Orphan: return o()
        }
    }

    @inlinable func forSide<T>(l: () -> T, r: () -> T, o: () -> T) -> T { forSide(side: parentSide, l: l, r: r, o: o) }

    @inlinable func swap(with node: TreeNode<K, V>?) { forSide(l: { parentNode!.leftNode = node }, r: { parentNode!.rightNode = node }, o: {}) }

    @inlinable func rotate(toThe dir: NodeDirection) { forSide(side: dir, l: { rotateLeft() }, r: { rotateRight() }, o: {}) }

    @usableFromInline func rotateLeft() {
        guard let rn = rightNode else { fatalError("Cannot rotate left because there is no right child node to take this nodes place.") }
        swap(with: rn)
        rightNode = rn.leftNode
        rn.leftNode = self
        Swift.swap(&color, &rn.color)
    }

    @usableFromInline func rotateRight() {
        guard let ln = leftNode else { fatalError("Cannot rotate right because there is no left child node to take this nodes place.") }
        swap(with: ln)
        leftNode = ln.rightNode
        ln.rightNode = self
        Swift.swap(&color, &ln.color)
    }
}

extension TreeNode: Equatable where V: Equatable {
    @usableFromInline static func == (lhs: TreeNode<K, V>, rhs: TreeNode<K, V>) -> Bool { ((lhs === rhs) || ((lhs.key == rhs.key) && (lhs.value == rhs.value))) }
}

extension TreeNode: Hashable where V: Hashable {
    @inlinable func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(value)
    }
}

extension TreeNode.NodeDirection {
    @inlinable var isLeft:  Bool { self == .Left }
    @inlinable var isRight: Bool { self == .Right }

    @inlinable static prefix func ! (op: TreeNode.NodeDirection) -> TreeNode.NodeDirection {
        switch op {
            case .Left:   return .Right
            case .Right:  return .Left
            case .Orphan: return .Orphan
        }
    }
}

extension TreeNode.NodeColor {
    @inlinable var isRed:   Bool { self == .Red }
    @inlinable var isBlack: Bool { self == .Black }

    @inlinable static func isRed<K, V>(_ node: TreeNode<K, V>?) -> Bool { (node?.color.isRed ?? false) }

    @inlinable static func isBlack<K, V>(_ node: TreeNode<K, V>?) -> Bool { (node?.color.isBlack ?? true) }
}
