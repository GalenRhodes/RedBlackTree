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

public class TreeSet<T>: BidirectionalCollection, SetAlgebra, Hashable where T: Hashable & Comparable {

    public typealias Element = T

    /// I know it's a performance hit to do locking but binary trees do NOT recover well
    /// from concurrent updates. Bad things happen. So we will do locking so that we can
    /// use this class concurrently without having to worry about loosing data.
    @usableFromInline let lock: ReadWriteLock = ReadWriteLock()

    /// And since we're doing locking we might as well take advantage of multiple threads
    /// to make some tasks faster. For example, with multiple CPUs you can split the tree
    /// in half to do searches as long as you're not depending on the order.
    @usableFromInline lazy var queue: DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem)

    /// The root of our tree.
    @usableFromInline var treeRoot: Node<T>? = nil

    //@f:0
    public let capacity:   Int   = Int.max
    public let startIndex: Index = 0
    //@f:1

    public required init() {}

    public required convenience init<S>(_ s: S) where S: Sequence, S.Element == T {
        self.init()
        insert(from: s)
    }

    public required init(from decoder: Decoder) throws where T: Codable {
        var c = try decoder.unkeyedContainer()
        while !c.isAtEnd { try _insert(c.decode(T.self)) }
    }
}

extension TreeSet {
    //@f:0
    @inlinable public var endIndex: Index { Index(count)                            }
    @inlinable public var count:    Int   { lock.withReadLock { _count            } }
    @inlinable public var isEmpty:  Bool  { lock.withReadLock { (treeRoot == nil) } }
    //@f:1

    @inlinable public convenience init(tree: TreeSet<T>) {
        self.init()
        tree.lock.withReadLock { if let r = tree.treeRoot { treeRoot = Node<T>(node: r) } }
    }

    @inlinable public subscript(position: Index) -> T {
        lock.withReadLock {
            let n = _nodeWith(index: position)
            return n.item
        }
    }

    @inlinable public func index(after i: Index) -> Index {
        guard i < endIndex else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return i.advanced(by: 1)
    }

    @inlinable public func index(before i: Index) -> Index {
        guard i > startIndex else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return i.advanced(by: -1)
    }

    @inlinable public func insert<S>(from src: S) where S: Sequence, S.Element == T {
        lock.withWriteLock { for e: T in src { _insert(e) } }
    }

    @inlinable @discardableResult public func insert(_ value: T) -> (inserted: Bool, memberAfterInsert: T) {
        lock.withWriteLock { _insert(value) }
    }

    @inlinable @discardableResult public func update(with newMember: T) -> T? {
        lock.withWriteLock { _update(with: newMember) }
    }

    @inlinable @discardableResult public func remove(_ member: T) -> T? {
        lock.withWriteLock {
            guard let n = _node(forValue: member) else { return nil }
            return _remove(node: n)
        }
    }

    @inlinable @discardableResult public func remove(at position: Index) -> T {
        lock.withWriteLock { _remove(node: _nodeWith(index: position)) }
    }

    @inlinable public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        lock.withWriteLock {
            if let r = treeRoot {
                treeRoot = nil
                queue.async { r.removeAll() }
            }
        }
    }

    @inlinable @discardableResult public func removeFirst() -> T {
        lock.withWriteLock {
            guard let r = treeRoot else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
            return _remove(node: r.farLeftNode)
        }
    }

    @inlinable @discardableResult public func removeLast() -> T {
        lock.withWriteLock {
            guard let r = treeRoot else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
            return _remove(node: r.farRightNode)
        }
    }

    @inlinable public __consuming func union(_ other: __owned TreeSet<T>) -> Self { _withCopy { $0.formUnion(other) } }

    @inlinable public __consuming func intersection(_ other: TreeSet<T>) -> Self { _withCopy { $0.formIntersection(other) } }

    @inlinable public __consuming func symmetricDifference(_ other: __owned TreeSet<T>) -> Self { _withCopy { $0.formSymmetricDifference(other) } }

    @inlinable public func formUnion(_ other: __owned TreeSet<T>) { _formUnion(other) }

    @inlinable public func formIntersection(_ other: TreeSet<T>) {
        lock.withWriteLock {
            if let r1 = treeRoot {
                other.lock.withReadLock {
                    if let r2 = other.treeRoot {
                        treeRoot = _getIntersection(r1, r2)
                    }
                    else {
                        treeRoot = nil
                        queue.async { r1.removeAll() }
                    }
                }
            }
        }
    }

    @inlinable func _formUnion(_ other: TreeSet<T>) {
        other.forEach { _insert($0) }
    }

    @inlinable public func formSymmetricDifference(_ other: __owned TreeSet<T>) {
        other.lock.withReadLock {
            if !other.isEmpty {
                lock.withWriteLock {
                    if isEmpty {
                        if let r = other.treeRoot { treeRoot = Node<T>(node: r) }
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

    @inlinable public func hash(into hasher: inout Hasher) { forEach { v in hasher.combine(v) } }

    @inlinable public func forEach(_ body: (T) throws -> Void) rethrows {
        lock.withReadLock { if let r = treeRoot { try r.forEach { n, _ in try body(n.item) } } }
    }

    @inlinable public static func == (lhs: TreeSet<T>, rhs: TreeSet<T>) -> Bool {
        guard lhs !== rhs else { return true }
        guard type(of: lhs) == type(of: rhs) else { return false }
        return lhs.lock.withReadLock {
            rhs.lock.withReadLock {
                guard lhs._count == rhs._count else { return false }
                for i in (lhs.startIndex ..< lhs.endIndex) { guard lhs._nodeWith(index: i).item == rhs._nodeWith(index: i).item else { return false } }
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
}

extension TreeSet {
    @inlinable var _count: Int { treeRoot?.count ?? 0 }

    @inlinable @discardableResult func _insert(_ value: T) -> (inserted: Bool, memberAfterInsert: T) {
        if let r = treeRoot {
            if let o = r[value] { return (false, o.item) }
            treeRoot = r.insert(item: value)
        }
        else {
            treeRoot = Node<T>(item: value)
        }

        return (true, value)
    }

    @inlinable @discardableResult func _update(with newMember: T) -> T? {
        if let r = treeRoot {
            let o = r[newMember]
            treeRoot = r.insert(item: newMember)
            if let _o = o { return _o.item }
        }
        else {
            treeRoot = Node<T>(item: newMember)
        }
        return nil
    }

    @inlinable func _withBlankTree(_ body: (TreeSet<T>) throws -> Void) rethrows -> Node<T>? {
        let t = TreeSet<T>()
        try body(t)
        return _trim(tree: t)
    }

    @inlinable func _trim(tree t: TreeSet<T>) -> Node<T>? {
        guard let r = t.treeRoot else { return nil }
        t.treeRoot = nil
        return r
    }

    @inlinable func _getIntersection(_ r1: Node<T>, _ r2: Node<T>) -> Node<T>? {
        let t = TreeSet<T>()
        r1.forEach { n, _ in if r2[n.item] != nil { t._insert(n.item) } }
        queue.async { r1.removeAll() }
        return _trim(tree: t)
    }

    @inlinable func _withCopy(_ body: (TreeSet<T>) throws -> Void) rethrows -> Self {
        let t = TreeSet<T>(tree: self)
        try body(t)
        return t as! Self
    }

    @inlinable func _remove(node n: Node<T>) -> T {
        treeRoot = n.remove()
        return n.item
    }

    @inlinable func _node(forValue value: T) -> Node<T>? {
        unwrap(treeRoot, def: nil) { (r: Node<T>) -> Node<T>? in r[value] }
    }

    @inlinable func _nodeWith(index i: Index) -> Node<T> {
        preconditionNotNil(preconditionNotNil(treeRoot, ERR_MSG_OUT_OF_BOUNDS)[i.index], ERR_MSG_OUT_OF_BOUNDS)
    }
}

extension TreeSet: Codable where T: Codable {
    @inlinable public func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        try forEach { v in try c.encode(v) }
    }
}
