/*===============================================================================================================================================================================*
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeSet.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/24/21
 *
 * Copyright © 2021. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation
import ReadWriteLock

@usableFromInline let ERR_MSG_OUT_OF_BOUNDS: String = "Index out of bounds."

public class TreeSet<Element>: TreeIteratorOwner, BidirectionalCollection, SetAlgebra, Hashable where Element: Hashable & Comparable {

    @usableFromInline typealias E = Element
    @usableFromInline typealias L = Iterator

    /// I know it's a performance hit to do locking but binary trees do NOT recover well
    /// from concurrent updates. Bad things happen. So we will do locking so that we can
    /// use this class concurrently without having to worry about loosing data.
    @usableFromInline let lock: ReadWriteLock = ReadWriteLock()

    /// And since we're doing locking we might as well take advantage of multiple threads
    /// to make some tasks faster. For example, with multiple CPUs you can split the tree
    /// in half to do searches as long as you're not depending on the order.
    @usableFromInline lazy var queue: DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem)

    @usableFromInline var notificationCenter: NotificationCenter = NotificationCenter()

    /// The root of our tree.
    @usableFromInline var treeRoot: Node<Element>? = nil

    //@f:0
    public let capacity:   Int   = Int.max
    public let startIndex: Index = 0
    //@f:1

    public required init() {}

    public required convenience init<S>(_ s: S) where S: Sequence, S.Element == Element {
        self.init()
        insert(from: s)
    }

    public required init(from decoder: Decoder) throws where Element: Codable {
        var c = try decoder.unkeyedContainer()
        while !c.isAtEnd { try _insert(c.decode(Element.self)) }
    }

    @usableFromInline func addTreeIteratorListener(_ listener: Iterator) {}

    @usableFromInline func removeTreeIteratorListener(_ listener: Iterator) {}
}

extension TreeSet {
    //@f:0
    @inlinable public var endIndex: Index { Index(count)                            }
    @inlinable public var count:    Int   { lock.withReadLock { _count            } }
    @inlinable public var isEmpty:  Bool  { lock.withReadLock { (treeRoot == nil) } }
    //@f:1

    @inlinable public convenience init(tree: TreeSet<Element>) {
        self.init()
        tree.lock.withReadLock { if let r = tree.treeRoot { treeRoot = Node<Element>(node: r) } }
    }

    @inlinable public subscript(position: Index) -> Element {
        lock.withReadLock { _nodeWith(index: position).item }
    }

    @inlinable public func index(after i: Index) -> Index {
        precondition(i < endIndex, ERR_MSG_OUT_OF_BOUNDS)
        return i.advanced(by: 1)
    }

    @inlinable public func index(before i: Index) -> Index {
        precondition(i > startIndex, ERR_MSG_OUT_OF_BOUNDS)
        return i.advanced(by: -1)
    }

    @inlinable public func insert<S>(from src: S) where S: Sequence, S.Element == Element {
        lock.withWriteLock { for e: Element in src { _insert(e) } }
    }

    @inlinable @discardableResult public func insert(_ value: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        lock.withWriteLock { _insert(value) }
    }

    @inlinable @discardableResult public func update(with newMember: Element) -> Element? {
        lock.withWriteLock { _update(with: newMember) }
    }

    @inlinable @discardableResult public func remove(_ member: Element) -> Element? {
        lock.withWriteLock { unwrap(_node(forValue: member), def: nil) { n in _remove(node: n) } }
    }

    @inlinable @discardableResult public func remove(at position: Index) -> Element {
        lock.withWriteLock { _remove(node: _nodeWith(index: position)) }
    }

    @inlinable public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        lock.withWriteLock { _removeAll() }
    }

    @inlinable @discardableResult public func removeFirst() -> Element {
        lock.withWriteLock { preconditionNotNil(treeRoot, ERR_MSG_OUT_OF_BOUNDS) { r in _remove(node: r.farLeftNode) } }
    }

    @inlinable @discardableResult public func removeLast() -> Element {
        lock.withWriteLock { preconditionNotNil(treeRoot, ERR_MSG_OUT_OF_BOUNDS) { r in _remove(node: r.farRightNode) } }
    }

    @inlinable public __consuming func union(_ other: __owned TreeSet<Element>) -> Self {
        _withCopy { $0._formUnion(other) }
    }

    @inlinable public __consuming func intersection(_ other: __owned TreeSet<Element>) -> Self {
        _withCopy { $0.formIntersection(other) }
    }

    @inlinable public __consuming func symmetricDifference(_ other: __owned TreeSet<Element>) -> Self {
        _withCopy { $0.formSymmetricDifference(other) }
    }

    @inlinable public func formUnion(_ other: __owned TreeSet<Element>) {
        lock.withWriteLock { _formUnion(other) }
    }

    @inlinable public func formIntersection(_ other: __owned TreeSet<Element>) {
        lock.withWriteLock { _formIntersection(other) }
    }

    @inlinable public func formSymmetricDifference(_ other: __owned TreeSet<Element>) {
        other.lock.withReadLock {
            if !other.isEmpty {
                lock.withWriteLock {
                    if isEmpty {
                        if let r = other.treeRoot { treeRoot = Node<Element>(node: r) }
                    }
                    else {
                        other.forEach { i in
                            if let v = _node(forValue: i) { remove(v.item) }
                            else { _insert(i) }
                        }
                    }
                }
            }
        }
    }

    @inlinable public func hash(into hasher: inout Hasher) {
        forEach { v in hasher.combine(v) }
    }

    @inlinable public func forEach(_ body: (Element) throws -> Void) rethrows {
        try lock.withReadLock { try unwrap(treeRoot) { r in try r.forEach { n, _ in try body(n.item) } } }
    }

    @inlinable public func makeIterator() -> Iterator {
        lock.withReadLock { Iterator(self) }
    }

    @inlinable public static func == (lhs: TreeSet<Element>, rhs: TreeSet<Element>) -> Bool {
        guard lhs !== rhs else { return true }
        guard type(of: lhs) == type(of: rhs) else { return false }
        return lhs.lock.withReadLock {
            rhs.lock.withReadLock {
                guard lhs._count == rhs._count else { return false }
                for i in (lhs.startIndex ..< lhs.endIndex) {
                    guard lhs._nodeWith(index: i).item == rhs._nodeWith(index: i).item else { return false }
                }
                return true
            }
        }
    }

    @frozen public struct Index: Hashable, Strideable, ExpressibleByIntegerLiteral {
        public typealias Stride = Int

        @usableFromInline let index: Int

        @inlinable init(_ index: Int) { self.index = index }

        @inlinable public init(integerLiteral value: IntegerLiteralType) { index = value }

        @inlinable public func distance(to other: Index) -> Stride { (other.index - index) }

        @inlinable public func advanced(by n: Stride) -> Index { Index(index + n) }
    }

    @frozen public struct Iterator: TreeListener, IteratorProtocol {
        @usableFromInline let _iter: TreeIterator<TreeSet<Element>, Element>

        @inlinable init(_ tree: TreeSet<Element>) { _iter = TreeIterator<TreeSet<Element>, Element>(owner: tree) }

        @inlinable public func next() -> Element? { _iter.next() }

        @inlinable func allRemoved() { _iter.allRemoved() }

        @inlinable func nodeRemoved(node: Node<Element>) { _iter.nodeRemoved(node: node) }

        @inlinable func nodeInserted(node: Node<Element>) { _iter.nodeInserted(node: node) }
    }
}

extension TreeSet {
    @inlinable var _count: Int { treeRoot?.count ?? 0 }

    @inlinable func _formUnion(_ other: TreeSet<Element>) {
        other.forEach { _insert($0) }
    }

    @inlinable @discardableResult func _insert(_ value: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        if let r = treeRoot {
            if let o = r[value] { return (false, o.item) }
            treeRoot = r.insert(item: value)
        }
        else {
            treeRoot = Node<Element>(item: value)
        }

        return (true, value)
    }

    @inlinable @discardableResult func _update(with newMember: Element) -> Element? {
        if let r = treeRoot {
            let o = r[newMember]
            treeRoot = r.insert(item: newMember)
            if let _o = o { return _o.item }
        }
        else {
            treeRoot = Node<Element>(item: newMember)
        }
        return nil
    }

    @inlinable func _withBlankTree(_ body: (TreeSet<Element>) throws -> Void) rethrows -> Node<Element>? {
        let t = TreeSet<Element>()
        try body(t)
        return _trim(tree: t)
    }

    @inlinable func _formIntersection(_ other: TreeSet<Element>) {
        unwrap(treeRoot) { r1 in other.lock.withReadLock { ifNil(other.treeRoot) { _removeAll(r1) } else: { (r2: Node<Element>) in treeRoot = _intersection(r1, r2) } } }
    }

    @inlinable func _intersection(_ r1: Node<Element>, _ r2: Node<Element>) -> Node<Element>? {
        let t = TreeSet<Element>()
        r1.forEach { n, _ in if r2[n.item] != nil { t._insert(n.item) } }
        queue.async { r1.removeAll() }
        return _trim(tree: t)
    }

    @inlinable func _withCopy(_ body: (TreeSet<Element>) throws -> Void) rethrows -> Self {
        let t = TreeSet<Element>(tree: self)
        try body(t)
        return t as! Self
    }

    @inlinable func _remove(node n: Node<Element>) -> Element {
        treeRoot = n.remove()
        return n.item
    }

    @inlinable func _removeAll() {
        unwrap(treeRoot) { _removeAll($0) }
    }

    @inlinable func _removeAll(_ r: Node<Element>) {
        treeRoot = nil
        queue.async { r.removeAll() }
    }

    @inlinable func _node(forValue value: Element) -> Node<Element>? {
        unwrap(treeRoot, def: nil) { (r: Node<Element>) -> Node<Element>? in r[value] }
    }

    @inlinable func _nodeWith(index i: Index) -> Node<Element> {
        preconditionNotNil(preconditionNotNil(treeRoot, ERR_MSG_OUT_OF_BOUNDS)[i.index], ERR_MSG_OUT_OF_BOUNDS)
    }

    @inlinable func _trim(tree t: TreeSet<Element>) -> Node<Element>? {
        guard let r = t.treeRoot else { return nil }
        t.treeRoot = nil
        return r
    }
}

extension TreeSet: Codable where Element: Codable {
    @inlinable public func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        try forEach { v in try c.encode(v) }
    }
}
