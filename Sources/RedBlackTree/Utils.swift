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

/*==============================================================================================================*/
/// An enum that specifies whether one
/// <code>[Comparable](https://developer.apple.com/documentation/swift/Comparable)</code> object is equal to, less
/// than, or greater than another
/// <code>[Comparable](https://developer.apple.com/documentation/swift/Comparable)</code> object. Returned by the
/// function `compare(a:b:)`.
///
public enum ComparisonResults {
    /*==========================================================================================================*/
    /// Both objects are equal to each other.
    ///
    case EqualTo
    /*==========================================================================================================*/
    /// The first object `a` is less than the second object `b`.
    ///
    case LessThan
    /*==========================================================================================================*/
    /// The first object `a` is greather than the second object `b`.
    ///
    case GreaterThan
}

/*==============================================================================================================*/
/// Compares two objects that are both the same type and both conform to the
/// <code>[Comparable](https://developer.apple.com/documentation/swift/Comparable)</code> protocol.
/// 
/// - Parameters:
///   - a: The first object.
///   - b: The second object.
/// - Returns: An instance of `ComparisonResults`.
///
@inlinable public func compare<T>(a: T, b: T) -> ComparisonResults where T: Comparable { ((a == b) ? .EqualTo : ((a < b) ? .LessThan : .GreaterThan)) }

@inlinable func foo<T>(start: T, _ body: (T) throws -> T?) rethrows -> T {
    var o1 = start
    while let o2 = try body(o1) { o1 = o2 }
    return o1
}

@inlinable func with<T>(_ o: T?, do body: (T) throws -> Void) rethrows { if let n = o { try body(n) } }

@inlinable func condExec<R>(_ predicate: Bool, yes: () throws -> R, no: () throws -> R) rethrows -> R { (predicate ? (try yes()) : (try no())) }

@inlinable @discardableResult func nilTest<T, R>(_ o: T?, whenNil: @autoclosure () throws -> R, whenNotNil: (T) throws -> R) rethrows -> R {
    guard let oo = o else { return try whenNil() }
    return try whenNotNil(oo)
}

@inlinable @discardableResult func nilTest<T, R>(_ o: T?, whenNil: @autoclosure () -> String, whenNotNil: (T) throws -> R) rethrows -> R {
    guard let oo = o else { fatalError(whenNil()) }
    return try whenNotNil(oo)
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

extension UUID {
    @inlinable static var new: String { UUID().uuidString }
}
