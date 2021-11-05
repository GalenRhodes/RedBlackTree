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

internal var DoCopyFast: Bool = true

@usableFromInline class TreeBase<Element>: BidirectionalCollection, Equatable where Element: Comparable {
    public typealias Index = TreeIndex

    @usableFromInline typealias Node = TreeNode<Element>
    @usableFromInline typealias IONode = IOTreeNode<Element>

    @usableFromInline enum CodingKeys: String, CodingKey { case trackInsertOrder, elements }

    //@f:0
    @usableFromInline                  let trackInsertOrder: Bool
    @usableFromInline fileprivate(set) var firstNode:        IONode? = nil
    @usableFromInline fileprivate(set) var lastNode:         IONode? = nil
    @usableFromInline fileprivate(set) var rootNode:         Node?   = nil
    @usableFromInline                  let startIndex:       Index   = Index(0)
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
        with(other.rootNode) { self.rootNode = $0.copyTree(fast: DoCopyFast) }
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
}

extension TreeBase {
    //@f:0
    @inlinable var count:     Int      { (rootNode?.count ?? 0)                                                                 }
    @inlinable var startNode: Element? { nilTest(rootNode, whenNil: nil) { (r: Node) in foo(start: r, { $0.leftNode  }).value } }
    @inlinable var endNode:   Element? { nilTest(rootNode, whenNil: nil) { (r: Node) in foo(start: r, { $0.rightNode }).value } }
    @inlinable var endIndex:  Index    { Index(count)                                                                           }
    //@f:1

    @inlinable subscript(element: Element) -> Element? { node(forElement: element)?.value }

    @inlinable subscript(position: Index) -> Element { node(forIndex: position).value }

    @inlinable func contains(_ element: Element) -> Bool { self[element] != nil }

    @inlinable func search(compareWith comp: (Element) throws -> ComparisonResults) rethrows -> Element? { try searchNode(compareWith: comp)?.value }

    @inlinable func copy() -> TreeBase<Element> { TreeBase<Element>(self) }

    @inlinable func first(reverse: Bool, where predicate: (Element) throws -> Bool) rethrows -> Element? {
        guard let r = rootNode, let n = try r.firstNode(reverse: reverse, where: { try predicate($0.value) }) else { return nil }
        return n.value
    }

    @inlinable func forEach(reverse: Bool, _ body: (Element) throws -> Void) rethrows {
        try with(rootNode) { (r: Node) in try r.forEachNode(reverse: reverse) { (n: Node) in try body(n.value) } }
    }

    @inlinable func forEachInOrder(reverse: Bool, _ body: (Element) throws -> Void) rethrows {
        guard let r = rootNode else { return }
        if let ro = (r as? IONode) { try ro.forEachNode(insertOrder: true, reverse: reverse) { try body($0.value) } }
        else { try forEach(reverse: reverse, body) }
    }
    @inlinable func node(forIndex index: Index) -> Node {
        guard let n = _searchNode(compareWith: { RedBlackTree.compare(a: index, b: $0.index) }) else { fatalError(ErrorMsgIndexOutOfBounds) }
        return n
    }

    @inlinable func node(forElement e: Element) -> Node? { _searchNode { RedBlackTree.compare(a: e, b: $0.value) } }

    @inlinable func searchNode(compareWith comp: (Element) throws -> ComparisonResults) rethrows -> Node? { try _searchNode { try comp($0.value) } }

    @inlinable func _searchNode(compareWith comp: (Node) throws -> ComparisonResults) rethrows -> Node? {
        var _n = rootNode
        while let n = _n {
            switch try comp(n) {
                case .EqualTo:     return n
                case .LessThan:    _n = n.leftNode
                case .GreaterThan: _n = n.rightNode
            }
        }
        return nil
    }

    @inlinable @discardableResult func insert(element: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let x = (trackInsertOrder ? insertIONode(update: false, element: element) : insertNonIONode(update: false, element: element))
        return (x.inserted, x.oldValue)
    }

    @inlinable @discardableResult func update(element: Element) -> Element? {
        let x = (trackInsertOrder ? insertIONode(update: true, element: element) : insertNonIONode(update: true, element: element))
        return (x.existed ? x.oldValue : nil)
    }

    @inlinable func remove(node n: Node) -> Element {
        rootNode = n.remove()
        guard trackInsertOrder, let r = rootNode, let ior = (r as? IONode) else { return n.value }
        lastNode = foo(start: ior) { $0.nextNode }
        if firstNode == nil { firstNode = foo(start: ior) { $0.prevNode } } // Repair just in case.
        return n.value
    }

    @inlinable func removeAll(fast: Bool) {
        guard let r = rootNode else { return }
        rootNode = nil
        firstNode = nil
        lastNode = nil
        fast ? DispatchQueue(label: UUID.new, attributes: .concurrent).async { r.removeAll() } : r.removeAll()
    }

    @inlinable func makeIterator() -> Iterator { Iterator(self) }

    @inlinable func makeInsertOrderIterator() -> InsertOrderIterator { InsertOrderIterator(self) }

    @inlinable func insertNonIONode(update f: Bool, element: Element) -> Node.InsertResults {
        guard let r = rootNode else {
            let n = Node(value: element)
            rootNode = n
            return (n, true, false, element)
        }
        let x = r.insert(update: f, value: element)
        rootNode = x.node.rootNode
        return x
    }

    @inlinable func insertIONode(update f: Bool, element: Element) -> Node.InsertResults {
        guard let r = rootNode else {
            let n = IONode(value: element)
            firstNode = n
            lastNode = firstNode
            rootNode = firstNode
            return (n, true, false, element)
        }
        let x = r.insert(update: f, value: element)
        let n = (x.node as! IONode)
        n.prevNode = lastNode
        lastNode?.nextNode = n
        lastNode = n
        rootNode = n.rootNode
        return x
    }

    @inlinable func replace(node n: Node, with element: Element) -> Element {
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
        guard i > startIndex else { fatalError(ErrorMsgIndexOutOfBounds) }
        return i - 1
    }

    @inlinable func index(after i: Index) -> Index {
        guard i < endIndex else { fatalError(ErrorMsgIndexOutOfBounds) }
        return i + 1
    }

    @inlinable static func == (lhs: TreeBase<Element>, rhs: TreeBase<Element>) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for i in (lhs.startIndex ..< lhs.endIndex) { guard lhs[i] == rhs[i] else { return false } }
        return true
    }

    @usableFromInline struct Iterator: IteratorProtocol {
        @usableFromInline let tree:  TreeBase<Element>
        @usableFromInline var stack: [Node] = []

        @inlinable init(_ tree: TreeBase<Element>) {
            self.tree = tree
            go(start: self.tree.rootNode)
        }

        @inlinable mutating func go(start: Node?) {
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
        @usableFromInline var nextNode: IONode?

        @inlinable init(_ tree: TreeBase<Element>) {
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
        var elemList = container.nestedUnkeyedContainer(forKey: .elements)
        if trackInsertOrder { try forEachInOrder(reverse: false) { try elemList.encode($0) } }
        else { try forEach(reverse: false) { try elemList.encode($0) } }
    }
}

extension TreeBase: Decodable where Element: Decodable {}

extension TreeBase: Hashable where Element: Hashable {
    @inlinable func hash(into hasher: inout Hasher) { forEach { hasher.combine($0) } }
}
