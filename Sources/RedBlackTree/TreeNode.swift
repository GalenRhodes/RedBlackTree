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

enum NodeColor { case Red, Black }

class TreeNode<K, V> where K: Comparable & Hashable {

    //@f:0
    private(set) var key:        K
    private(set) var value:      V
    private(set) var color:      NodeColor
    private(set) var count:      Int             = 1
    private(set) var parentNode: TreeNode<K, V>? = nil
    private(set) var leftNode:   TreeNode<K, V>? = nil { willSet { onWillSet(newValue) } didSet { onDidSet(oldValue, leftNode)  } }
    private(set) var rightNode:  TreeNode<K, V>? = nil { willSet { onWillSet(newValue) } didSet { onDidSet(oldValue, rightNode) } }

    var rootNode: TreeNode<K, V> { ((parentNode == nil) ? self : parentNode!.rootNode) }
    //@f:1

    init(key: K, value: V, color: NodeColor = .Black) {
        self.key = key
        self.value = value
        self.color = color
    }

    subscript(key: K) -> TreeNode<K, V>? { ((key == self.key) ? self : ((key < self.key) ? leftNode : rightNode)?[key]) }

    func insertNode(key: K, value: V) -> TreeNode<K, V> {
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
            if p.color == .Red {
                if let g = p.parentNode {
                    let pl = (p === g.leftNode)

                    if let u = (pl ? g.rightNode : g.leftNode), u.color == .Red {
                        u.color = .Black
                        p.color = .Black
                        g.color = .Red
                        g.insertBalance()
                    }
                    else {
                        if pl && (self === p.rightNode) {
                            p.rotateLeft()
                            g.rotateRight()
                        }
                        else if (self === p.leftNode) && !pl {
                            p.rotateRight()
                            g.rotateLeft()
                        }
                        else {

                        }
                    }
                }
                else {
                    p.color = .Black
                }
            }
        }
        else {
            // This node is the root so it needs to be black.
            color = .Black
        }
    }

    private func recount() { count = (1 + (leftNode?.count ?? 0) + (rightNode?.count ?? 0)) }

    private func makeOrphan() {
        guard let p = parentNode else { return }
        if self === p.leftNode { p.leftNode = nil }
        else if self === p.rightNode { p.rightNode = nil }
        parentNode = nil
        p.recount()
    }

    private func onWillSet(_ newValue: TreeNode<K, V>?) {
        if let nv = newValue { nv.makeOrphan() }
    }

    private func onDidSet(_ oldValue: TreeNode<K, V>?, _ newValue: TreeNode<K, V>?) {
        if let ov = oldValue { ov.parentNode = nil }
        if let nv = newValue { nv.parentNode = self }
        recount()
    }

    private func rotateLeft() {
        guard let rn = rightNode else { fatalError("Cannot rotate left because there is no right child node to take this nodes place.") }
        rightNode = rn.leftNode
        if let p = parentNode {
            if self === p.leftNode { p.leftNode = rn }
            else { p.rightNode = rn }
        }
        rn.leftNode = self
        swap(&color, &rn.color)
    }

    private func rotateRight() {
        guard let ln = leftNode else { fatalError("Cannot rotate right because there is no left child node to take this nodes place.") }
        leftNode = ln.rightNode
        if let p = parentNode {
            if self === p.leftNode { p.leftNode = ln }
            else { p.rightNode = ln }
        }
        ln.rightNode = self
        swap(&color, &ln.color)
    }
}

extension TreeNode: Equatable where V: Equatable {
    static func == (lhs: TreeNode<K, V>, rhs: TreeNode<K, V>) -> Bool { ((lhs === rhs) || ((lhs.key == rhs.key) && (lhs.value == rhs.value))) }
}

extension TreeNode: Hashable where V: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(value)
    }
}

func isRed<K, V>(_ node: TreeNode<K, V>?) -> Bool { ((node?.color ?? NodeColor.Black) == NodeColor.Red) }

func isBlack<K, V>(_ node: TreeNode<K, V>?) -> Bool { ((node?.color ?? NodeColor.Black) == NodeColor.Black) }
