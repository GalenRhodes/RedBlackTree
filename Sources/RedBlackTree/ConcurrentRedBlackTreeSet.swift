/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: ConcurrentRedBlackTreeSet.swift
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

public class ConcurrentRedBlackTreeSet<Element>: RedBlackTreeSet<Element> where Element: Comparable {

    @usableFromInline let lock: NSRecursiveLock = NSRecursiveLock()

    public override func contains(_ e: Element) -> Bool { lock.withLock { super.contains(e) } }

    public override func removeAll(keepingCapacity: Bool) { lock.withLock { super.removeAll(keepingCapacity: keepingCapacity) } }

    public override func remove(at position: Index) -> Element { lock.withLock { super.remove(at: position) } }

    public override subscript(position: Index) -> Element { lock.withLock { super[position] } }

    public override func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) { lock.withLock { super.insert(newMember) } }

    public override func remove(_ member: Element) -> Element? { lock.withLock { super.remove(member) } }

    public override func update(with newMember: Element) -> Element? { lock.withLock { super.update(with: newMember) } }

    public override func makeIterator() -> Iterator { lock.withLock { super.makeIterator() } }
}
