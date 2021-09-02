/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: ConcurrentTreeBase.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: September 01, 2021
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

@usableFromInline class ConcurrentTreeBase<Element>: TreeBase<Element> where Element: Comparable {
    //@f:0
    private                    let lock:      NSRecursiveLock = NSRecursiveLock()
    @usableFromInline override var startNode: Element?        { lock.withLock { super.startNode } }
    @usableFromInline override var endNode:   Element?        { lock.withLock { super.endNode }   }
    @usableFromInline override var count:     Int             { lock.withLock { super.count }     }
    //@f:1

    @usableFromInline override init(trackInsertOrder: Bool) { super.init(trackInsertOrder: trackInsertOrder) }

    @usableFromInline override init(_ other: TreeBase<Element>) { super.init(other) }

    @usableFromInline override init(from container: KeyedDecodingContainer<CodingKeys>) throws where Element: Decodable { try super.init(from: container) }

    @usableFromInline override init<S>(trackInsertOrder: Bool, _ sequence: S) where S: Sequence, S.Element == Element { super.init(trackInsertOrder: trackInsertOrder, sequence) }

    @usableFromInline override init(trackInsertOrder: Bool, _ items: [Element]) { super.init(trackInsertOrder: trackInsertOrder, items) }

    @usableFromInline override func copy() -> TreeBase<Element> { ConcurrentTreeBase<Element>(self) }

    @usableFromInline override func first(reverse: Bool, where predicate: (Element) throws -> Bool) rethrows -> Element? { try lock.withLock { try super.first(reverse: reverse, where: predicate) } }

    @usableFromInline override func forEach(fast: Bool, reverse: Bool, _ body: (Element) throws -> Void) rethrows { try lock.withLock { try super.forEach(fast: fast, reverse: reverse, body) } }

    @usableFromInline override func forEachInOrder(reverse: Bool, _ body: (Element) throws -> Void) rethrows { try lock.withLock { try super.forEachInOrder(reverse: reverse, body) } }

    @usableFromInline override func node(forElement e: Element) -> TreeNode<Element>? { lock.withLock { super.node(forElement: e) } }

    @usableFromInline override func node(forIndex index: TreeIndex) -> TreeNode<Element> { lock.withLock { super.node(forIndex: index) } }

    @usableFromInline override func searchNode(compareWith comp: (Element) throws -> ComparisonResults) rethrows -> TreeNode<Element>? { try lock.withLock { try super.searchNode(compareWith: comp) } }

    @usableFromInline override func insert(element: Element) -> Element? { lock.withLock { super.insert(element: element) } }

    @usableFromInline override func remove(node n: TreeNode<Element>) -> Element { lock.withLock { super.remove(node: n) } }

    @usableFromInline override func removeAll(fast: Bool) { lock.withLock { super.removeAll(fast: fast) } }

    @usableFromInline override func makeIterator() -> Iterator { lock.withLock { super.makeIterator() } }

    @usableFromInline override func makeInsertOrderIterator() -> InsertOrderIterator { lock.withLock { super.makeInsertOrderIterator() } }
}
