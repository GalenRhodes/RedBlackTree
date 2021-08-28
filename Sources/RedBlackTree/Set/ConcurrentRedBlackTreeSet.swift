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

    let lock: NSRecursiveLock = NSRecursiveLock()

    public override var count: Int { lock.withLock { super.count } }

    public override func removeAll(keepingCapacity: Bool) { lock.withLock { super.removeAll(keepingCapacity: keepingCapacity) } }

    override func node(forElement e: Element) -> TreeNode<Element>? { lock.withLock { super.node(forElement: e) } }

    override func node(at index: TreeNode<Element>.Index) -> TreeNode<Element> { lock.withLock { super.node(at: index) } }

    override func remove(node: TreeNode<Element>) { lock.withLock { super.remove(node: node) } }

    override func insert(_ newElement: Element, force: Bool) -> (inserted: Bool, oldElement: Element?) { lock.withLock { super.insert(newElement, force: force) } }
}
