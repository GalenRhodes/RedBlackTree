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

let ERR_MSG_OUT_OF_BOUNDS: String = "Index out of bounds."

public class TreeSet<T>: BidirectionalCollection, SetAlgebra, Hashable where T: Hashable & Comparable {

    public typealias Element = T

    var treeRoot: Node<T>? = nil

    public let startIndex: Index = 0
    public var endIndex:   Index { Index(treeRoot?.count ?? 0) }
    public var isEmpty:    Bool { (treeRoot == nil) }

    required public init() {}

    required public convenience init<S>(_ s: S) where S: Sequence, S.Element == T {
        self.init()
        insert(from: s)
    }

    public required init(from decoder: Decoder) throws where T: Codable {
        var c = try decoder.unkeyedContainer()
        while !c.isAtEnd { try insert(c.decode(T.self)) }
    }
}

extension TreeSet {

    public convenience init(_ tree: TreeSet<T>) {
        self.init()
        formUnion(tree)
    }

    subscript(value: T) -> Node<T>? { treeRoot?[value] }

    func withBlankTree(_ body: (TreeSet<T>) throws -> Void) rethrows -> Node<T>? {
        let t = TreeSet<T>()
        try body(t)
        let nr = t.treeRoot
        t.treeRoot = nil
        return nr
    }

    func getIntersection(_ r1: Node<T>, _ r2: Node<T>, remove f: Bool) -> Node<T>? {
        let nr = withBlankTree { t in r1.forEach { n, _ in if r2[n.item] != nil { t.insert(n.item) } } }
        if f { r1.removeAll() }
        return nr
    }

    func withCopy(_ body: (TreeSet<T>) throws -> Void) rethrows -> Self {
        let t = TreeSet<T>()
        if let r = treeRoot { t.treeRoot = Node<T>(node: r) }
        try body(t)
        return t as! Self
    }

    func _remove(node n: Node<T>) -> T {
        treeRoot = n.remove()
        return n.item
    }

    func nodeWith(index i: Index) -> Node<T> {
        guard let r = treeRoot, let n = r[i.index] else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return n
    }

    public subscript(position: Index) -> T {
        let n = nodeWith(index: position)
        return n.item
    }

    public func index(after i: Index) -> Index {
        guard i < endIndex else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return i.advanced(by: 1)
    }

    public func index(before i: Index) -> Index {
        guard i > startIndex else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return i.advanced(by: -1)
    }

    public func insert<S>(from src: S) where S: Sequence, S.Element == T {
        for e: T in src { insert(e) }
    }

    @discardableResult public func insert(_ value: T) -> (inserted: Bool, memberAfterInsert: T) {
        if let r = treeRoot {
            if let o = r[value] { return (false, o.item) }
            treeRoot = r.insert(item: <#T##T##T#>)
        }
        else {
            treeRoot = Node<T>(item: value)
        }

        return (true, value)
    }

    @discardableResult public func update(with newMember: T) -> T? {
        if let r = treeRoot {
            let o = r[newMember]
            treeRoot = r.insert(item: <#T##T##T#>)
            if let _o = o { return _o.item }
        }
        else {
            treeRoot = Node<T>(item: newMember)
        }
        return nil
    }

    @discardableResult public func remove(_ member: T) -> T? {
        guard let n = self[member] else { return nil }
        return _remove(node: n)
    }

    @discardableResult public func remove(at position: Index) -> T { _remove(node: nodeWith(index: position)) }

    public func removeAll(keepingCapacity keepCapacity: Bool = false) { if let r = treeRoot { r.removeAll(); treeRoot = nil } }

    @discardableResult public func removeFirst() -> T {
        guard let r = treeRoot else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return _remove(node: r.farLeftNode)
    }

    @discardableResult public func removeLast() -> T {
        guard let r = treeRoot else { fatalError(ERR_MSG_OUT_OF_BOUNDS) }
        return _remove(node: r.farRightNode)
    }

    public __consuming func union(_ other: __owned TreeSet<T>) -> Self { withCopy { $0.formUnion(other) } }

    public __consuming func intersection(_ other: TreeSet<T>) -> Self { withCopy { $0.formIntersection(other) } }

    public __consuming func symmetricDifference(_ other: __owned TreeSet<T>) -> Self { withCopy { $0.formSymmetricDifference(other) } }

    public func formUnion(_ other: __owned TreeSet<T>) { other.forEach { insert($0) } }

    public func formIntersection(_ other: TreeSet<T>) {
        guard let r1 = treeRoot else { return }
        guard let r2 = other.treeRoot else { return removeAll() }
        treeRoot = getIntersection(r1, r2, remove: true)
    }

    public func formSymmetricDifference(_ other: __owned TreeSet<T>) {
        if other.isEmpty { return }
        if isEmpty { return formUnion(other) }
        other.forEach { i in
            if let v = self[i] { remove(v.item) }
            else { insert(i) }
        }
    }

    public func hash(into hasher: inout Hasher) { forEach { v in hasher.combine(v) } }

    public func forEach(_ body: (T) throws -> Void) rethrows { if let r = treeRoot { try r.forEach { n, f in try body(n.item) } } }

    public static func == (lhs: TreeSet<T>, rhs: TreeSet<T>) -> Bool {
        guard lhs !== rhs else { return true }
        guard lhs.count == rhs.count else { return false }
        for i in (lhs.startIndex ..< lhs.endIndex) { guard lhs[i] == rhs[i] else { return false } }
        return true
    }

    @frozen public struct Index: Hashable, Strideable, ExpressibleByIntegerLiteral {
        public typealias Stride = Int

        let index: Int

        public func distance(to other: Index) -> Stride { (other.index - index) }

        public func advanced(by n: Stride) -> Index { Index(index + n) }

        init(_ index: Int) { self.index = index }

        public init(integerLiteral value: IntegerLiteralType) { index = value }
    }
}

extension TreeSet: Codable where T: Codable {
    public func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        try forEach { v in try c.encode(v) }
    }
}
