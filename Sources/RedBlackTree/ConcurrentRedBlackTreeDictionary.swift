/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: ConcurrentRedBlackTreeDictionary.swift
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

public class ConcurrentRedBlackTreeDictionary<Key, Value>: RedBlackTreeDictionary<Key, Value> where Key: Comparable {
    //@f:0
    @usableFromInline let lock:  NSRecursiveLock = NSRecursiveLock()
    public override   var count: Int             { lock.withLock { super.count } }
    //@f:1

    public override func encode(to encoder: Encoder) throws where Key: Encodable, Value: Encodable { try lock.withLock { try super.encode(to: encoder) } }

    override func node(forKey key: Key) -> TreeNode<KV>? { lock.withLock { super.node(forKey: key) } }

    override func node(at index: Index) -> TreeNode<KV> { lock.withLock { super.node(at: index) } }

    override func remove(node n: TreeNode<KV>) { lock.withLock { super.remove(node: n) } }

    public override func updateValue(_ value: Value, forKey key: Key) -> Value? { lock.withLock { super.updateValue(value, forKey: key) } }

    public override func removeAll(keepingCapacity keepCapacity: Bool) { lock.withLock { super.removeAll(keepingCapacity: keepCapacity) } }

    public override func forEach(reverse: Bool, _ body: ((Key, Value)) throws -> Void) rethrows { try lock.withLock { try super.forEach(reverse: reverse, body) } }

    override func _first(reverse f: Bool, where predicate: ((Key, Value)) throws -> Bool) rethrows -> (Key, Value)? { try lock.withLock { try super._first(reverse: f, where: predicate) } }

    override func _forEachFast(_ body: ((Key, Value)) throws -> Void) rethrows { try lock.withLock { try super._forEachFast(body) } }
}
