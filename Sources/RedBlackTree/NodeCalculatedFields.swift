/*===============================================================================================================================================================================*
 *     PROJECT: RedBlackTree
 *    FILENAME: NodeCalculatedFields.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 1/2/22
 *
 * Copyright © 2022. All rights reserved.
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

extension Node {
    //@f:0
    @inlinable var farLeftNode:  ND    { _get(from: leftNode,   default: self)      { $0.farLeftNode                                                                    } }
    @inlinable var farRightNode: ND    { _get(from: rightNode,  default: self)      { $0.farLeftNode                                                                    } }
    @inlinable var root:         ND    { _get(from: parentNode, default: self)      { $0.root                                                                           } }
    @inlinable var leftCount:    Int   { _get(from: leftNode,   default: 0)         { $0.count                                                                          } }
    @inlinable var rightCount:   Int   { _get(from: rightNode,  default: 0)         { $0.count                                                                          } }
    @usableFromInline var index: Int   { _get(from: parentNode, default: leftCount) { (self === $0.rightNode) ? ($0.index + leftCount + 1) : ($0.index - leftCount - 1) } }

    @inlinable var count:        Int   { get { Int(bitPattern: (data & countBits)) } set { data = ((data & colorBit) | (UInt(bitPattern: newValue) & countBits)) } }
    @inlinable var color:        Color { get { Color.color(data)                   } set { data = newValue.d(data)                                         } }
    //@f:1
}
