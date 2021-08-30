/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: Utils.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 17, 2021
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

public enum ComparisonResults {
    case EqualTo, LessThan, GreaterThan
}

@inlinable func compare<T>(a: T, b: T) -> ComparisonResults where T: Comparable { ((a == b) ? .EqualTo : ((a < b) ? .LessThan : .GreaterThan)) }

@inlinable func foo<T>(start: T, _ body: (T) throws -> T?) rethrows -> T {
    var o1 = start
    while let o2 = try body(o1) { o1 = o2 }
    return o1
}

@inlinable func with<T, R>(node: TreeNode<T>?, default def: @autoclosure () throws -> R, _ body: (TreeNode<T>) throws -> R) rethrows -> R where T: Comparable & Equatable {
    guard let r = try with(node: node, body) else { return try def() }
    return r
}

@inlinable @discardableResult func with<T, R>(node: TreeNode<T>?, _ body: (TreeNode<T>) throws -> R) rethrows -> R? where T: Comparable & Equatable {
    guard let n = node else { return nil }
    return try body(n)
}

extension NSLock {
    @inlinable @discardableResult func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}

extension NSRecursiveLock {
    @inlinable @discardableResult func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
