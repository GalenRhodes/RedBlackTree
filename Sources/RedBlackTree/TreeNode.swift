/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeNode.swift
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

public class TreeNode<T>: Comparable where T: Comparable & Equatable {

    public internal(set) var value: T

    @usableFromInline init(value v: T, color c: Color) {
        value = v
        _color = c
    }

    //@f:0
    @usableFromInline var _parentNode: TreeNode<T>? = nil
    @usableFromInline var _rightNode:  TreeNode<T>? = nil
    @usableFromInline var _leftNode:   TreeNode<T>? = nil
    @usableFromInline var _color:      Color        = .Black
    @usableFromInline var _count:      Int          = 1
    @usableFromInline let _sx:         [Side]       = [ .Left, .Right ]
    //@f:1
}
