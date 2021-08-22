/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: RedBlackTreeSet_SetAlgebra.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 19, 2021
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

extension RedBlackTreeSet: SetAlgebra where Element: Hashable {}

extension RedBlackTreeSet {

    @inlinable public func union(_ other: RedBlackTreeSet<Element>) -> Self { _dNc(self, other, { f, e, a, b in true }) as! Self }

    @inlinable public func union<S>(_ other: S) -> RedBlackTreeSet<Element> where Element == S.Element, S: Sequence { _dNc(self, other, { f, e, a, b in true }) }

    @inlinable public func intersection(_ other: RedBlackTreeSet<Element>) -> Self { _intersection(other: other) as! Self }

    @inlinable public func intersection<S>(_ other: S) -> RedBlackTreeSet<Element> where Element == S.Element, S: Sequence { _intersection(other: other) }

    @inlinable public func symmetricDifference(_ other: RedBlackTreeSet<Element>) -> Self { _dNc(self, other, { !($0 ? $3.contains($1) : $2.contains($1)) }) as! Self }

    @inlinable public func symmetricDifference<S>(_ other: S) -> RedBlackTreeSet<Element> where Element == S.Element, S: Sequence {
        _dNc(self, other, { !($0 ? $3.contains($1) : $2.contains($1)) }) as! Self
    }

    @inlinable public func formUnion(_ other: RedBlackTreeSet<Element>) { insert(contentsOf: other) }

    @inlinable public func formIntersection(_ other: RedBlackTreeSet<Element>) {
        var common: [Element] = []
        for e in other { if contains(e) { common.append(e) } }
        removeAll()
        insert(contentsOf: common)
        common.removeAll()
    }//@f:0

    @inlinable public func formSymmetricDifference(_ other: RedBlackTreeSet<Element>) { for e in other { if contains(e) { remove(e) } else { insert(e) } } }
    //@f:1
    @inlinable public func subtract(_ other: RedBlackTreeSet<Element>) { for e in other { remove(e) } }

    @inlinable public func subtract<S>(_ other: S) where Element == S.Element, S: Sequence { for e: Element in other { remove(e) } }

    @inlinable public func subtracting(_ other: RedBlackTreeSet<Element>) -> Self { _dNc(self, other, { f, e, _, b in (f && !b.contains(e)) }) as! Self }

    @inlinable public func subtracting<S>(_ other: S) -> RedBlackTreeSet<Element> where Element == S.Element, S: Sequence { _dNc(self, other, { f, e, _, b in (f && !b.contains(e)) }) }

    @inlinable func _intersection<S>(other: S) -> RedBlackTreeSet<Element> where Element == S.Element, S: Sequence {
        let copy = RedBlackTreeSet<Element>()
        for e in self { if other.contains(e) { copy.insert(e) } }
        return copy
    }

    /// In situations where we have to scan two sequences to populate a new tree we can take advantage of
    /// multiple CPUs to get the job done faster. Only the point of inserting into the new tree has to be
    /// synchronized but everything else can happen in parallel.
    ///
    /// - Parameters:
    ///   - a: The first sequence.
    ///   - b: The second sequence.
    ///   - t: The closure to test if an element from either sequence should be put into the resulting
    ///        tree.
    /// - Returns: The resulting tree.
    ///
    @inlinable func _dNc<A, B, E>(_ a: A, _ b: B, _ t: (Bool, E, A, B) -> Bool) -> RedBlackTreeSet<E> where A: Sequence, B: Sequence, E: Comparable & Equatable, A.Element == E, B.Element == E {
        withoutActuallyEscaping(t) { _t in
            let g = DispatchGroup()
            let q = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
            let c = RedBlackTreeSet<E>()
            let l = NSLock()
            q.async(group: g) { for e in a { if _t(true, e, a, b) { l.withLock { c.insert(e) } } } }
            q.async(group: g) { for e in b { if _t(false, e, a, b) { l.withLock { c.insert(e) } } } }
            g.wait()
            return c
        }
    }
}
