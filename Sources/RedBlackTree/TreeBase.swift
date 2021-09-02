/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeBase.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 29, 2021
 *
  * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided
 * that the above copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
 * NEGIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//*****************************************************************************************************************************/

import Foundation
import CoreFoundation

@usableFromInline class TreeBase<Element>: BidirectionalCollection, Equatable where Element: Comparable {
    public typealias Index = TreeIndex

    @usableFromInline enum CodingKeys: String, CodingKey { case concurrent, trackInsertOrder, elements }

    //@f:0
    @usableFromInline      let trackInsertOrder: Bool
    @usableFromInline      var updateCount:      Int                  = 0
    fileprivate            var firstNode:        IOTreeNode<Element>? = nil
    fileprivate            var lastNode:         IOTreeNode<Element>? = nil
    fileprivate(set)       var rootNode:         TreeNode<Element>?   = nil
    @usableFromInline lazy var queue:            DispatchQueue        = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
    @usableFromInline      let startIndex:       Index                = Index(index: 0)
    //@f:1

    @usableFromInline init(trackInsertOrder: Bool) { self.trackInsertOrder = trackInsertOrder }

    @usableFromInline convenience required init(from decoder: Decoder) throws where Element: Decodable {
        try self.init(from: try decoder.container(keyedBy: CodingKeys.self))
    }

    @usableFromInline init(from container: KeyedDecodingContainer<CodingKeys>) throws where Element: Decodable {
        trackInsertOrder = (try container.decodeIfPresent(Bool.self, forKey: .trackInsertOrder) ?? false)
        var elemList = try container.nestedUnkeyedContainer(forKey: .elements)
        while !elemList.isAtEnd { insert(element: try elemList.decode(Element.self)) }
    }

    @usableFromInline init(_ other: TreeBase<Element>) {
        trackInsertOrder = other.trackInsertOrder
        rootNode = other.rootNode?.copyTree()
    }

    @usableFromInline init<S>(trackInsertOrder: Bool, _ sequence: S) where S: Sequence, S.Element == Element {
        self.trackInsertOrder = trackInsertOrder
        for e in sequence { insert(element: e) }
    }

    @usableFromInline init(trackInsertOrder: Bool, _ items: [Element]) {
        self.trackInsertOrder = trackInsertOrder
        for e in items { insert(element: e) }
    }

    deinit { removeAll(fast: false) }

    @usableFromInline func copy() -> TreeBase<Element> { TreeBase<Element>(self) }

    //@f:0
    @usableFromInline var count:     Int      { (rootNode?.count ?? 0)                                                                    }
    @usableFromInline var startNode: Element? { if let r = rootNode { return foo(start: r, { $0._leftNode  }).value } else { return nil } }
    @usableFromInline var endNode:   Element? { if let r = rootNode { return foo(start: r, { $0._rightNode }).value } else { return nil } }
    //@f:1

    @usableFromInline func first(reverse: Bool, where predicate: (Element) throws -> Bool) rethrows -> Element? {
        guard let r = rootNode, let n = try r.firstNode(reverse: reverse, where: { try predicate($0.value) }) else { return nil }
        return n.value
    }

    @usableFromInline enum UpdateViolation: Error { case Violation }

    @usableFromInline func forEach(fast: Bool, reverse: Bool, _ body: (Element) throws -> Void) rethrows {
        guard let r = rootNode else { return }
        try withoutActuallyEscaping({ () -> Void in
            let startingUpdateCount: Int = self.updateCount
            do {
                if fast && !reverse {
                    try r.forEachFast {
                        guard startingUpdateCount == self.updateCount else { throw UpdateViolation.Violation }
                        try body($0.value)
                    }
                }
                else {
                    try r.forEachNode(reverse: reverse) {
                        guard startingUpdateCount == self.updateCount else { throw UpdateViolation.Violation }
                        try body($0.value)
                    }
                }
            }
            catch UpdateViolation.Violation {
                /* Ignore */
            }
            catch let e {
                throw e
            }
        }) { try $0() }
    }

    @usableFromInline func forEachInOrder(reverse: Bool, _ body: (Element) throws -> Void) rethrows {
        guard let r = rootNode else { return }
        if let ro = (r as? IOTreeNode<Element>) { try ro.forEachNode(insertOrder: true, reverse: reverse) { try body($0.value) } }
        else { try forEach(fast: false, reverse: reverse, body) }
    }

    @usableFromInline func node(forElement e: Element) -> TreeNode<Element>? {
        guard let r = rootNode else { return nil }
        return r[e]
    }

    @usableFromInline func node(forIndex index: Index) -> TreeNode<Element> {
        guard let r = rootNode else { fatalError("Index out of bounds.") }
        return r[index]
    }

    @usableFromInline func searchNode(compareWith comp: (Element) throws -> ComparisonResults) rethrows -> TreeNode<Element>? { try rootNode?.search(compareWith: comp) }

    @usableFromInline @discardableResult func insert(element: Element) -> Element? {
        guard trackInsertOrder else { return insertNonIONode(element: element) }
        guard let r = rootNode else { insertFirstIONode(element: element); return nil }
        guard let n = r[element] else { insertNewIONode(root: r, element: element); return nil }
        return replace(node: n, with: element)
    }

    @usableFromInline func remove(node n: TreeNode<Element>) -> Element {
        rootNode = n.remove()
        guard trackInsertOrder, let r = rootNode, let ior = (r as? IOTreeNode<Element>) else { return n.value }
        lastNode = foo(start: ior) { $0.nextNode }
        if firstNode == nil { firstNode = foo(start: ior) { $0.prevNode } } // Repair just in case.
        return n.value
    }

    @usableFromInline func removeAll(fast: Bool) {
        guard let r = rootNode else { return }
        rootNode = nil
        firstNode = nil
        lastNode = nil
        if fast { queue.async { r.removeAll() } }
        else { r.removeAll() }
    }

    @usableFromInline func makeIterator() -> Iterator { Iterator(self) }

    @usableFromInline func makeInsertOrderIterator() -> InsertOrderIterator { InsertOrderIterator(self) }
}

extension TreeBase {
    @inlinable var endIndex: Index { Index(index: count) }

    @inlinable subscript(element: Element) -> Element? { node(forElement: element)?.value }

    @inlinable subscript(position: TreeIndex) -> Element { node(forIndex: position).value }

    @inlinable func contains(_ element: Element) -> Bool { self[element] != nil }

    @inlinable func search(compareWith comp: (Element) throws -> ComparisonResults) rethrows -> Element? { try searchNode(compareWith: comp)?.value }

    fileprivate func insertNonIONode(element: Element) -> Element? {
        guard let r = rootNode else { rootNode = TreeNode<Element>(value: element); return nil }
        guard let n = r[element] else { rootNode = r.insert(value: element).rootNode; return nil }
        return replace(node: n, with: element)
    }

    fileprivate func insertFirstIONode(element: Element) {
        firstNode = IOTreeNode<Element>(value: element)
        lastNode = firstNode
        rootNode = firstNode
    }

    fileprivate func insertNewIONode(root r: TreeNode<Element>, element: Element) {
        guard let n = r.insert(value: element) as? IOTreeNode<Element> else { return }
        rootNode = n.rootNode
        n.prevNode = lastNode
        lastNode?.nextNode = n
        lastNode = n
    }

    @inlinable func replace(node n: TreeNode<Element>, with element: Element) -> Element {
        let v = remove(node: n)
        insert(element: element)
        return v
    }

    @inlinable func remove(where predicate: (Element) throws -> ComparisonResults) rethrows -> Element? {
        guard let n = try searchNode(compareWith: predicate) else { return nil }
        return remove(node: n)
    }

    @inlinable func remove(element: Element) -> Element? {
        guard let n = node(forElement: element) else { return nil }
        return remove(node: n)
    }

    @inlinable func index(before i: Index) -> Index {
        guard i > startIndex else { fatalError("Index out of bounds.") }
        return i - 1
    }

    @inlinable func index(after i: Index) -> Index {
        guard i < endIndex else { fatalError("Index out of bounds.") }
        return i + 1
    }

    @inlinable static func == (lhs: TreeBase<Element>, rhs: TreeBase<Element>) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for i in (lhs.startIndex ..< lhs.endIndex) { guard lhs[i] == rhs[i] else { return false } }
        return true
    }

    @usableFromInline struct Iterator: IteratorProtocol {
        @usableFromInline let tree:  TreeBase<Element>
        @usableFromInline var stack: [TreeNode<Element>] = []

        @usableFromInline init(_ tree: TreeBase<Element>) {
            self.tree = tree
            go(start: self.tree.rootNode)
        }

        @inlinable mutating func go(start: TreeNode<Element>?) {
            var node = start
            while let n = node {
                stack.append(n)
                node = n.leftNode
            }
        }

        @inlinable mutating func next() -> Element? {
            guard let n = stack.popLast() else { return nil }
            go(start: n.rightNode)
            return n.value
        }
    }

    @usableFromInline struct InsertOrderIterator: IteratorProtocol {
        @usableFromInline let tree:     TreeBase<Element>
        @usableFromInline var nextNode: IOTreeNode<Element>?

        @usableFromInline init(_ tree: TreeBase<Element>) {
            self.tree = tree
            nextNode = self.tree.firstNode
        }

        @inlinable mutating func next() -> Element? {
            guard let n = nextNode else { return nil }
            nextNode = n.nextNode
            return n.value
        }
    }
}

extension TreeBase: Encodable where Element: Encodable {
    @inlinable func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trackInsertOrder, forKey: .trackInsertOrder)
        try container.encode(((self as? ConcurrentTreeBase<Element>) != nil), forKey: .concurrent)
        var elemList = container.nestedUnkeyedContainer(forKey: .elements)
        if trackInsertOrder { try forEachInOrder(reverse: false) { try elemList.encode($0) } }
        else { try forEach(fast: false, reverse: false) { try elemList.encode($0) } }
    }
}

extension TreeBase: Decodable where Element: Decodable {}

extension TreeBase: Hashable where Element: Hashable {
    @inlinable func hash(into hasher: inout Hasher) { forEach { hasher.combine($0) } }
}
