/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: RedBlackTreeSet.swift
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

let s: Set<String> = []

public class RedBlackTreeSet<Element>: BidirectionalCollection, ExpressibleByArrayLiteral, Equatable where Element: Comparable & Equatable {
    public typealias ArrayLiteralElement = Element
    public typealias Index = TreeNode<Element>.Index

    public let startIndex: Index = Index(index: 0)
    public var count:      Int { (rootNode?.count ?? 0) }

    private var rootNode: TreeNode<Element>? = nil

    public required init() {}

    public convenience required init(from decoder: Decoder) throws where Element: Decodable {
        self.init()
        var c = try decoder.unkeyedContainer()
        while !c.isAtEnd { insert(try c.decode(Element.self)) }
    }

    public convenience required init(arrayLiteral elements: Element...) {
        self.init()
        for e in elements { insert(e) }
    }

    public convenience required init<Source>(_ sequence: Source) where Element == Source.Element, Source: Sequence {
        self.init()
        for e: Element in sequence { insert(e) }
    }

    public convenience init(_ other: RedBlackTreeSet<Element>) {
        self.init()
        if let other = (other as? ConcurrentRedBlackTreeSet<Element>) {
            rootNode = other.lock.withLock { other.rootNode?.copyTree() }
        }
        else {
            rootNode = other.rootNode?.copyTree()
        }
    }

    public func contains(_ e: Element) -> Bool {
        guard let r = rootNode else { return false }
        return (r[e] != nil)
    }

    public func removeAll(keepingCapacity: Bool = false) {
        if let r = rootNode {
            rootNode = nil
            DispatchQueue(label: UUID().uuidString).async { r.removeAll() }
        }
    }

    public func remove(at position: Index) -> Element {
        guard let r = rootNode else { fatalError("Index out of bounds.") }
        let n = r[position]
        let v = n.value
        rootNode = n.remove()
        return v
    }

    public subscript(position: Index) -> Element {
        guard position >= startIndex && position < endIndex else { fatalError("Index out of bounds.") }
        return rootNode![position].value
    }

    @discardableResult public func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        if let r = rootNode {
            if let o = r[newMember] { return (inserted: false, memberAfterInsert: o.value) }
            rootNode = r.insert(value: newMember).rootNode
        }
        else {
            rootNode = TreeNode<Element>(value: newMember)
        }
        return (inserted: true, memberAfterInsert: newMember)
    }

    @discardableResult public func remove(_ member: Element) -> Element? {
        guard let r = rootNode, let n = r[member] else { return nil }
        rootNode = n.remove()
        return member
    }

    @discardableResult public func update(with newMember: Element) -> Element? {
        guard let r = rootNode else {
            rootNode = TreeNode<Element>(value: newMember)
            return nil
        }
        guard let n = r[newMember] else {
            rootNode = r.insert(value: newMember).rootNode
            return nil
        }
        let v = n.value
        rootNode = r.insert(value: newMember).rootNode
        return v
    }

    public func makeIterator() -> Iterator { Iterator(tree: self) }

    public struct Iterator: IteratorProtocol {
        @usableFromInline let tree:  RedBlackTreeSet<Element>
        @usableFromInline var stack: [TreeNode<Element>] = []

        init(tree: RedBlackTreeSet<Element>) {
            self.tree = tree
            drop(start: tree.rootNode)
        }

        @inlinable mutating func drop(start: TreeNode<Element>?) {
            var n = start
            while let _n = n {
                stack.append(_n)
                n = _n.leftNode
            }
        }

        @inlinable public mutating func next() -> Element? {
            guard let n = stack.popLast() else { return nil }
            drop(start: n.rightNode)
            return n.value
        }
    }
}
