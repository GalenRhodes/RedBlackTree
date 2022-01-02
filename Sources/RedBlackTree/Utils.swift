/*===============================================================================================================================================================================*
 *     PROJECT: RedBlackTree
 *    FILENAME: Utils.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/26/21
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

infix operator ?=: ComparisonPrecedence

@inlinable func comp<T>(_ l: T, _ r: T) -> ComparisonResult where T: Comparable {
    return ((l < r) ? .orderedAscending : ((r < l) ? .orderedDescending : .orderedSame))
}

@inlinable func assertNotNil<T, R>(_ v: T?, _ msg: @autoclosure () -> String, _ body: (T) throws -> R) rethrows -> R {
    guard let v = v else { fatalError(msg()) }
    return try body(v)
}

@inlinable func ifNil<T, R>(_ v: T?, do a: () throws -> R, else b: (T) throws -> R) rethrows -> R {
    guard let v = v else { return try a() }
    return try b(v)
}

@inlinable func doIf(_ predicate: Bool, _ whenTrue: () throws -> Void, else whenFalse: () throws -> Void) rethrows {
    if predicate { try whenTrue() }
    else { try whenFalse() }
}

@inlinable func ifNotNil<T>(_ v: T?, do body: (T) throws -> Void) rethrows { if let v = v { try body(v) } }
