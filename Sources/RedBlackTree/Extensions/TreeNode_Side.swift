/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeNode_Side.swift
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

@usableFromInline let _sx: [Side] = [ .Left, .Right ]

@usableFromInline enum Side: UInt8, CustomStringConvertible, CustomDebugStringConvertible {
    case Neither = 0
    case Left
    case Right

    @inlinable var debugDescription: String { description }
    @inlinable var description:      String {
        switch self {
            case .Neither: return "neither"
            case .Left:    return "left"
            case .Right:   return "right"
        }
    }

    @inlinable static prefix func ! (s: Self) -> Self {
        switch s {
            case .Neither: return .Neither
            case .Left:    return .Right
            case .Right:   return .Left
        }
    }
}
