/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeNode_Color.swift
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

@usableFromInline let RedMask:   UInt   = (1 << (UInt.bitWidth - 1))
@usableFromInline let ColorMask: [UInt] = [ 0, RedMask ]

extension TreeNode {

    public enum Color: Int {
        case Black = 0
        case Red

        @inlinable var isRed:   Bool { self == .Red }
        @inlinable var isBlack: Bool { self == .Black }

        @inlinable static func isRed(_ n: TreeNode?) -> Bool { n?.color.isRed ?? false }

        @inlinable static func isBlack(_ n: TreeNode?) -> Bool { n?.color.isBlack ?? true }

        @inlinable static func maskLo(_ n: UInt) -> UInt {
            let m: UInt = ~RedMask
            let r: UInt = (n & m)
            return r
        }

        @inlinable static func maskLo(_ n: Int) -> UInt { maskLo(UInt(bitPattern: n)) }

        @inlinable static func maskHi(_ n: UInt) -> UInt {
            let m: UInt = RedMask
            let r: UInt = (n & m)
            return r
        }
    }

    @inlinable var color: Color {
        get { ((Color.maskHi(_data) == 0) ? Color.Black : Color.Red) }
        set { _data = (Color.maskLo(_data) | ColorMask[newValue.rawValue]) }
    }
}

extension TreeNode.Color: CustomStringConvertible, CustomDebugStringConvertible {
    @inlinable public var description:      String { ((self == .Red) ? "red" : "black") }
    @inlinable public var debugDescription: String { description }
}
