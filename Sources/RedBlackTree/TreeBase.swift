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

@usableFromInline struct TreeBase<Element>: BidirectionalCollection, Equatable where Element: Comparable {
    public typealias Index = TreeIndex

    //@f:0
    @usableFromInline      let trackOrder: Bool
    @usableFromInline      var firstNode:  IOTreeNode<Element>? = nil
    @usableFromInline      var lastNode:   IOTreeNode<Element>? = nil
    @usableFromInline      var rootNode:   TreeNode<Element>?   = nil
    @usableFromInline lazy var queue:      DispatchQueue        = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
    @usableFromInline      let startIndex: Index                = Index(index: 0)
    @inlinable             var endIndex:   Index                { Index(index: count) }
    @inlinable             var count:      Int                  { (rootNode?.count ?? 0) }
    //@f:1

    @inlinable init(trackOrder: Bool) { self.trackOrder = trackOrder }

    @inlinable init(_ other: TreeBase<Element>) {
        self.init(trackOrder: other.trackOrder)
        rootNode = other.rootNode?.copyTree()
    }

    @inlinable init<S>(trackOrder: Bool, elements: S) where S: Sequence, S.Element == Element {
        self.init(trackOrder: trackOrder)
        for e in elements { insert(element: e) }
    }

    @inlinable func first(reverse: Bool, where predicate: (Element) throws -> Bool) rethrows -> Element? {
        guard let r = rootNode, let n = try r.firstNode(reverse: reverse, where: { try predicate($0.value) }) else { return nil }
        return n.value
    }

    @inlinable func forEach(fast: Bool, reverse: Bool, _ body: (Element) throws -> Void) rethrows {
        guard let r = rootNode else { return }
        if fast && !reverse { try r.forEachFast { try body($0.value) } }
        else { try r.forEachNode(reverse: reverse) { try body($0.value) } }
    }

    @inlinable func forEachInOrder(reverse: Bool, _ body: (Element) throws -> Void) rethrows {
        guard let r = rootNode else { return }
        if let ro = (r as? IOTreeNode<Element>) { try ro.forEachNode(insertOrder: true, reverse: reverse) { try body($0.value) } }
        else { try forEach(fast: false, reverse: reverse, body) }
    }

    @inlinable func node(forElement e: Element) -> TreeNode<Element>? { rootNode?[e] }

    @inlinable func search(compareWith comp: (Element) throws -> ComparisonResults) rethrows -> Element? { try searchNode(compareWith: comp)?.value }

    @inlinable func searchNode(compareWith comp: (Element) throws -> ComparisonResults) rethrows -> TreeNode<Element>? { try rootNode?.search(compareWith: comp) }

    @inlinable @discardableResult mutating func insert(element: Element) -> Element? {
        guard trackOrder else { return insertNonIONode(element: element) }
        guard let r = rootNode else { insertFirstIONode(element: element); return nil }
        guard let n = r[element] else { insertNewIONode(root: r, element: element); return nil }
        return replace(node: n, with: element)
    }

    @inlinable mutating func insertNonIONode(element: Element) -> Element? {
        guard let r = rootNode else { rootNode = TreeNode<Element>(value: element); return nil }
        guard let n = r[element] else { rootNode = r.insert(value: element).rootNode; return nil }
        return replace(node: n, with: element)
    }

    @inlinable mutating func insertFirstIONode(element: Element) {
        firstNode = IOTreeNode<Element>(value: element)
        lastNode = firstNode
        rootNode = firstNode
    }

    @inlinable mutating func insertNewIONode(root r: TreeNode<Element>, element: Element) {
        guard let n = r.insert(value: element) as? IOTreeNode<Element> else { return }
        rootNode = n.rootNode
        n.prevNode = lastNode
        lastNode?.nextNode = n
        lastNode = n
    }

    @inlinable mutating func replace(node n: TreeNode<Element>, with element: Element) -> Element {
        let v = remove(node: n)
        insert(element: element)
        return v
    }

    @inlinable mutating func remove(node n: TreeNode<Element>) -> Element {
        rootNode = n.remove()
        guard trackOrder, let r = rootNode, let ior = (r as? IOTreeNode<Element>) else { return n.value }
        lastNode = foo(start: ior) { $0.nextNode }
        if firstNode == nil { firstNode = foo(start: ior) { $0.prevNode } } // Repair just in case.
        return n.value
    }

    @inlinable mutating func remove(where predicate: (Element) throws -> ComparisonResults) rethrows -> Element? {
        guard let n = try searchNode(compareWith: predicate) else { return nil }
        return remove(node: n)
    }

    @inlinable mutating func remove(element: Element) -> Element? {
        guard let n = node(forElement: element) else { return nil }
        return remove(node: n)
    }

    @inlinable mutating func removeAll(fast: Bool) {
        guard let r = rootNode else { return }
        rootNode = nil
        firstNode = nil
        lastNode = nil
        if fast { queue.async { r.removeAll() } }
        else { r.removeAll() }
    }

    @inlinable subscript(element: Element) -> Element? {
        guard let r = rootNode else { return nil }
        return r[element]?.value
    }

    @inlinable subscript(position: TreeIndex) -> Element {
        guard let r = rootNode else { fatalError("Index out of bounds.") }
        return r[position].value
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

    @usableFromInline enum CodingKeys: String, CodingKey { case trackOrder, elements }
}

extension TreeBase: Encodable where Element: Encodable {
    @inlinable func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trackOrder, forKey: .trackOrder)
        var elemList = container.nestedUnkeyedContainer(forKey: .elements)
        if trackOrder { try forEachInOrder(reverse: false) { try elemList.encode($0) } }
        else { try forEach(fast: false, reverse: false) { try elemList.encode($0) } }
    }
}

extension TreeBase: Decodable where Element: Decodable {
    @inlinable init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(trackOrder: try container.decode(Bool.self, forKey: .trackOrder))
        var elemList = try container.nestedUnkeyedContainer(forKey: .elements)
        while !elemList.isAtEnd { insert(element: try elemList.decode(Element.self)) }
    }
}

extension TreeBase: Hashable where Element: Hashable {
    @inlinable func hash(into hasher: inout Hasher) { forEach { hasher.combine($0) } }
}

extension TreeBase {
    @inlinable func makeIterator() -> Iterator { Iterator(self) }

    @usableFromInline struct Iterator: IteratorProtocol {
        @usableFromInline var stack: [TreeNode<Element>] = []
        @usableFromInline let tree:  TreeBase<Element>

        @inlinable init(_ tree: TreeBase<Element>) {
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
}
