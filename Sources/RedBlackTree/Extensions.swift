/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: Extensions.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 03, 2021
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

extension NSLocking {
    @inlinable func withLock<T>(do body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}

@inlinable func pow<T: BinaryInteger>(_ base: T, _ power: T) -> T {
    func expBySq(_ y: T, _ x: T, _ n: T) -> T {
        precondition(n >= 0)
        return (n == 0 ? y : (n == 1 ? y * x : (n.isMultiple(of: 2) ? expBySq(y, x * x, n / 2) : expBySq(y * x, x * x, (n - 1) / 2))))
    }

    return expBySq(1, base, power)
}

@usableFromInline enum ComparisonResult { case LessThan, GreaterThan, Equal }

@inlinable func compare<T>(_ a: T, _ b: T) -> ComparisonResult where T: Comparable { (a < b ? .LessThan : (a > b ? .GreaterThan : .Equal)) }

@inlinable func foobar<T>(start: T, getNext: (T) throws -> T?) rethrows -> T {
    var x = start
    while let y = try getNext(x) { x = y }
    return x
}
