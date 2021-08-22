/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: RedBlackTreeSet_Extensions.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 20, 2021
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

extension RedBlackTreeSet {

    //@f:0
    @inlinable public var isEmpty:  Bool  { (count == 0)           }
    @inlinable public var endIndex: Index { Index(index: count)    }
    //@f:1

    @inlinable public func index(after i: Index) -> Index {
        guard i >= startIndex && i < endIndex else { fatalError("Index out of bounds.") }
        return (i + 1)
    }

    @inlinable public func index(before i: Index) -> Index {
        guard i > startIndex && i <= endIndex else { fatalError("Index out of bounds.") }
        return (i - 1)
    }

    @inlinable public convenience init(tree: RedBlackTreeSet<Element>) {
        self.init()
        for e in tree { insert(e) }
    }

    @inlinable public func insert<S>(contentsOf s: S) where S: Sequence, S.Element == Element { for e: Element in s { insert(e) } }

    @inlinable public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> RedBlackTreeSet<Element> {
        let tree = RedBlackTreeSet<Element>()
        for e in self { if try isIncluded(e) { tree.insert(e) } }
        return tree
    }

    @inlinable public func removeFirst() -> Element {
        remove(at: startIndex)
    }

    @inlinable public static func == (lhs: RedBlackTreeSet<Element>, rhs: RedBlackTreeSet<Element>) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var index: Index = lhs.startIndex
        while index < lhs.endIndex {
            guard lhs[index] == rhs[index] else { return false }
            lhs.formIndex(after: &index)
        }
        return true
    }
}
