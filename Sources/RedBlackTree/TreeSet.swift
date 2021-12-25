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

@usableFromInline let ERR_MSG_OUT_OF_BOUNDS: String = "Index out of bounds."

public class TreeSet<T>: BidirectionalCollection, SetAlgebra, Hashable where T: Hashable & Comparable {
    public var test: Set<T> = Set<T>()

    public typealias Element = T

    @usableFromInline var treeRoot: Node<T>? = nil

    public let startIndex: Index = 0
    public var endIndex:   Index { Index(treeRoot?.count ?? 0) }
    public var isEmpty:    Bool { (treeRoot == nil) }

    required public init() {}
}

extension TreeSet {

    @inlinable subscript(value: T) -> Node<T>? { treeRoot?[value] }

    @inlinable func withBlankTree(_ body: (TreeSet<T>) throws -> Void) rethrows -> Node<T>? {
        let t = TreeSet<T>()
        try body(t)
        let nr = t.treeRoot
        t.treeRoot = nil
        return nr
    }

    @inlinable func getIntersection(_ r1: Node<T>, _ r2: Node<T>, remove f: Bool) -> Node<T>? {
        let nr = withBlankTree { t in r1.forEach { n, _ in if r2[n.item] != nil { t.insert(n.item) } } }
        if f { r1.removeAll() }
        return nr
    }

    @inlinable func withCopy(_ body: (TreeSet<T>) throws -> Void) rethrows -> Self {
        let t = TreeSet<T>()
        t.treeRoot = treeRoot?.copy()
        try body(t)
        return t as! Self
    }

    @inlinable func _remove(node n: Node<T>) -> T {
        treeRoot = n.remove()
        return n.item
    }

    @inlinable func nodeWith(index i: Index) -> Node<T> {
        guard let n = treeRoot?.nodeWith(index: i.index) else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return n
    }

    @inlinable public subscript(position: Index) -> T {
        let n = nodeWith(index: position)
        return n.item
    }

    @inlinable public func index(after i: Index) -> Index {
        guard i < endIndex else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return i.advanced(by: 1)
    }

    @inlinable public func index(before i: Index) -> Index {
        guard i > startIndex else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return i.advanced(by: -1)
    }

    @inlinable @discardableResult public func insert(_ value: T) -> (inserted: Bool, memberAfterInsert: T) {
        if let r = treeRoot {
            if let o = r[value] { return (false, o.item) }
            treeRoot = r.insert(item: value)
        }
        else {
            treeRoot = Node<T>(item: value)
        }

        return (true, value)
    }

    @inlinable @discardableResult public func update(with newMember: T) -> T? {
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

    @inlinable @discardableResult public func remove(_ member: T) -> T? {
        guard let n = self[member] else { return nil }
        return _remove(node: n)
    }

    @inlinable @discardableResult public func remove(at position: Index) -> T { _remove(node: nodeWith(index: position)) }

    @inlinable public func removeAll(keepingCapacity keepCapacity: Bool = false) { if let r = treeRoot { r.removeAll(); treeRoot = nil } }

    @inlinable @discardableResult public func removeFirst() -> T {
        guard let r = treeRoot else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return _remove(node: r.farLeftNode)
    }

    @inlinable @discardableResult public func removeLast() -> T {
        guard let r = treeRoot else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return _remove(node: r.farRightNode)
    }

    @inlinable public __consuming func union(_ other: __owned TreeSet<T>) -> Self { withCopy { $0.formUnion(other) } }

    @inlinable public __consuming func intersection(_ other: TreeSet<T>) -> Self { withCopy { $0.formIntersection(other) } }

    @inlinable public __consuming func symmetricDifference(_ other: __owned TreeSet<T>) -> Self { withCopy { $0.formSymmetricDifference(other) } }

    @inlinable public func formUnion(_ other: __owned TreeSet<T>) { other.forEach { v in update(with: v) } }

    @inlinable public func formIntersection(_ other: TreeSet<T>) {
        guard let r1 = treeRoot else { return }
        guard let r2 = other.treeRoot else { removeAll(); return }
        treeRoot = getIntersection(r1, r2, remove: true)
    }

    @inlinable public func formSymmetricDifference(_ other: __owned TreeSet<T>) {
        guard let r2 = other.treeRoot else { return } // Nothhing to do.
        guard treeRoot != nil else { treeRoot = r2.copy(); return }

        let nr = withBlankTree { t in

        }
    }

    @inlinable public func hash(into hasher: inout Hasher) { forEach { v in hasher.combine(v) } }

    @inlinable public func forEach(_ body: (T) throws -> Void) rethrows { if let r = treeRoot { try r.forEach { n, f in try body(n.item) } } }

    @inlinable public static func == (lhs: TreeSet<T>, rhs: TreeSet<T>) -> Bool { fatalError() }

    @frozen public struct Index: Hashable, Strideable, ExpressibleByIntegerLiteral {
        public typealias Stride = Int

        @usableFromInline let index: Int

        @inlinable public func distance(to other: Index) -> Stride { (other.index - index) }

        @inlinable public func advanced(by n: Stride) -> Index { Index((index + n)) }

        @inlinable init(_ index: Int) { self.index = index }

        @inlinable public init(integerLiteral value: IntegerLiteralType) { index = value }
    }
}
