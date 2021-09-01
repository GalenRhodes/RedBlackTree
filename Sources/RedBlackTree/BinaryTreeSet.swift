/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: BinaryTreeSet.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 31, 2021
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

public class BinaryTreeSet<Element>: BidirectionalCollection, ExpressibleByArrayLiteral where Element: Comparable {
    public typealias Index = TreeIndex
    public typealias ArrayLiteralElement = Element

    @usableFromInline var base: TreeBase<Element>

    public required init() { base = TreeBase<Element>(trackInsertOrder: false) }

    public init(trackInsertOrder: Bool) { base = TreeBase<Element>(trackInsertOrder: trackInsertOrder) }

    public init<S>(trackInsertOrder: Bool, _ sequence: S) where S: Sequence, S.Element == Element { base = TreeBase<Element>(trackInsertOrder: trackInsertOrder, sequence) }

    public init(treeSet other: BinaryTreeSet<Element>) { base = TreeBase<Element>(other.base) }

    public required init(from decoder: Decoder) throws where Element: Decodable { base = try TreeBase<Element>(from: decoder) }

    public required init(arrayLiteral elements: ArrayLiteralElement...) { base = TreeBase<Element>(trackInsertOrder: false, elements) }

    public required init<S>(_ sequence: S) where S: Sequence, S.Element == Element { base = TreeBase<Element>(trackInsertOrder: false, sequence) }
}

extension BinaryTreeSet {
    @inlinable public var startIndex: Index { base.startIndex }
    @inlinable public var endIndex:   Index { base.endIndex }
    @inlinable public var count:      Int { base.count }
    @inlinable public var isEmpty:    Bool { startIndex == endIndex }

    @inlinable public func index(before i: Index) -> Index { base.index(before: i) }

    @inlinable public func index(after i: Index) -> Index { base.index(after: i) }

    @inlinable public subscript(position: Index) -> Element { base[position] }

    @inlinable public subscript(element: Element) -> Element? { base[element] }

    @inlinable public func contains(_ member: Element) -> Bool { base.contains(member) }

    @inlinable public func map<T>(_ convert: (Element) throws -> T) rethrows -> BinaryTreeSet<T> where T: Comparable {
        let copy = BinaryTreeSet<T>()
        try forEach { copy.insert(try convert($0)) }
        return copy
    }

    @inlinable public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> BinaryTreeSet<Element> {
        let copy = BinaryTreeSet<Element>()
        try forEach { if try isIncluded($0) { copy.insert($0) } }
        return copy
    }

    @inlinable @discardableResult public func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        if let n = base[newMember] { return (inserted: false, memberAfterInsert: n) }
        base.insert(element: newMember)
        return (inserted: true, memberAfterInsert: newMember)
    }

    @inlinable @discardableResult public func insert(contentsOf treeSet: BinaryTreeSet<Element>) -> [(inserted: Bool, memberAfterInsert: Element)] {
        var out: [(inserted: Bool, memberAfterInsert: Element)] = []
        treeSet.forEach { out.append(insert($0)) }
        return out
    }

    @inlinable @discardableResult public func insert<S>(contentsOf sequence: S) -> [(inserted: Bool, memberAfterInsert: Element)] where S: Sequence, S.Element == Element {
        var out: [(inserted: Bool, memberAfterInsert: Element)] = []
        sequence.forEach { out.append(insert($0)) }
        return out
    }

    @inlinable @discardableResult public func remove(_ member: Element) -> Element? { base.remove(element: member) }

    @inlinable public func remove<S>(contentsOf sequence: S) where S: Sequence, S.Element == Element { remove { sequence.contains($0) } }

    @inlinable public func remove(contentsOf treeSet: BinaryTreeSet<Element>) { remove { treeSet.contains($0) } }

    @inlinable public func remove(where predicate: (Element) throws -> Bool) rethrows {
        var list: [Element] = []
        try forEach { if try predicate($0) { list.append($0) } }
        remove(contentsOf: list)
    }

    @inlinable public func removeAll(keepingCapacity: Bool = false) { base.removeAll(fast: true) }

    @inlinable @discardableResult public func update(with newMember: Element) -> Element? { base.insert(element: newMember) }

    @inlinable @discardableResult public func update(withContentsOf tree: BinaryTreeSet<Element>) -> [Element?] {
        var out: [Element?] = []
        tree.forEach { out.append(update(with: $0)) }
        return out
    }

    @inlinable @discardableResult public func update<S>(withContentsOf sequence: S) -> [Element?] where S: Sequence, S.Element == Element {
        var out: [Element?] = []
        sequence.forEach { out.append(update(with: $0)) }
        return out
    }

    @inlinable public func union(_ other: BinaryTreeSet<Element>) -> Self {
        let copy = BinaryTreeSet<Element>(treeSet: self)
        copy.insert(contentsOf: other)
        return copy as! Self
    }

    @inlinable public func intersection(_ other: BinaryTreeSet<Element>) -> Self {
        let copy = BinaryTreeSet<Element>()
        other.forEach { if let e = self[$0] { copy.insert(e) } }
        return copy as! Self
    }

    @inlinable public func symmetricDifference(_ other: BinaryTreeSet<Element>) -> Self {
        let copy  = BinaryTreeSet<Element>()
        let lock  = NSLock()
        let queue = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
        let group = DispatchGroup()
        queue.async(group: group) { self.forEach { e in if !other.contains(e) { lock.withLock { copy.insert(e) } } } }
        queue.async(group: group) { other.forEach { e in if !self.contains(e) { lock.withLock { copy.insert(e) } } } }
        group.wait()
        return copy as! Self
    }

    @inlinable public func formUnion(_ other: BinaryTreeSet<Element>) { insert(contentsOf: other) }

    @inlinable public func formIntersection(_ other: BinaryTreeSet<Element>) { remove { !other.contains($0) } }

    @inlinable public func formSymmetricDifference(_ other: BinaryTreeSet<Element>) {
        remove(contentsOf: other)
        insert(contentsOf: other.filter { !contains($0) })
    }

    @inlinable public func subtracting(_ other: BinaryTreeSet<Element>) -> Self {
        let copy = BinaryTreeSet<Element>()
        forEach { if !other.contains($0) { copy.insert($0) } }
        return copy as! Self
    }

    @inlinable public func isSubset(of other: BinaryTreeSet<Element>) -> Bool {
        for e in self { if !other.contains(e) { return false } }
        return true
    }

    @inlinable public func isDisjoint(with other: BinaryTreeSet<Element>) -> Bool {
        for e in self { if other.contains(e) { return false } }
        return true
    }

    @inlinable public func isSuperset(of other: BinaryTreeSet<Element>) -> Bool { other.isSubset(of: self) }

    @inlinable public func subtract(_ other: BinaryTreeSet<Element>) { remove(contentsOf: other) }
}

extension BinaryTreeSet: Encodable where Element: Encodable {
    @inlinable public func encode(to encoder: Encoder) throws { try base.encode(to: encoder) }
}

extension BinaryTreeSet: Decodable where Element: Decodable {}

extension BinaryTreeSet: Equatable {
    @inlinable public static func == (lhs: BinaryTreeSet<Element>, rhs: BinaryTreeSet<Element>) -> Bool { lhs.base == rhs.base }
}

extension BinaryTreeSet: SetAlgebra, Hashable where Element: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) { base.forEach { hasher.combine($0) } }

    @inlinable @discardableResult public func insert(contentsOf set: Set<Element>) -> [(inserted: Bool, memberAfterInsert: Element)] {
        var out: [(inserted: Bool, memberAfterInsert: Element)] = []
        set.forEach { out.append(insert($0)) }
        return out
    }

    @inlinable public func remove(contentsOf set: Set<Element>) { remove { set.contains($0) } }

    @inlinable @discardableResult public func update(withContentsOf set: Set<Element>) -> [Element?] {
        var out: [Element?] = []
        set.forEach { out.append(update(with: $0)) }
        return out
    }

    @inlinable public func union(_ other: Set<Element>) -> Self {
        let copy = BinaryTreeSet<Element>(treeSet: self)
        copy.insert(contentsOf: other)
        return copy as! Self
    }

    @inlinable public func intersection(_ other: Set<Element>) -> Self {
        let copy = BinaryTreeSet<Element>()
        other.forEach { if let e = self[$0] { copy.insert(e) } }
        return copy as! Self
    }

    @inlinable public func symmetricDifference(_ other: Set<Element>) -> Self {
        let copy  = BinaryTreeSet<Element>()
        let lock  = NSLock()
        let queue = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
        let group = DispatchGroup()
        queue.async(group: group) { self.forEach { e in if !other.contains(e) { lock.withLock { copy.insert(e) } } } }
        queue.async(group: group) { other.forEach { e in if !self.contains(e) { lock.withLock { copy.insert(e) } } } }
        group.wait()
        return copy as! Self
    }

    @inlinable public func formUnion(_ other: Set<Element>) { insert(contentsOf: other) }

    @inlinable public func formIntersection(_ other: Set<Element>) { remove { !other.contains($0) } }

    @inlinable public func formSymmetricDifference(_ other: Set<Element>) {
        remove(contentsOf: other)
        insert(contentsOf: other.filter { !contains($0) })
    }

    @inlinable public func subtracting(_ other: Set<Element>) -> Self {
        let copy = BinaryTreeSet<Element>()
        forEach { if !other.contains($0) { copy.insert($0) } }
        return copy as! Self
    }

    @inlinable public func isSubset(of other: Set<Element>) -> Bool {
        for e in self { if !other.contains(e) { return false } }
        return true
    }

    @inlinable public func isDisjoint(with other: Set<Element>) -> Bool {
        for e in self { if other.contains(e) { return false } }
        return true
    }

    @inlinable public func isSuperset(of other: Set<Element>) -> Bool { other.isSubset(of: self) }

    @inlinable public func subtract(_ other: Set<Element>) { remove(contentsOf: other) }
}
