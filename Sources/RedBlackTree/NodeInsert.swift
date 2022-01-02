/*===============================================================================================================================================================================*
 *     PROJECT: RedBlackTree
 *    FILENAME: NodeInsert.swift
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
    @usableFromInline func insert(item i: T) -> ND {
        switch comp(i, item) {
            case .orderedSame:       item = i
            case .orderedAscending:  return _i1(item: i, side: .Left)
            case .orderedDescending: return _i1(item: i, side: .Right)
        }
        return root
    }

    @inlinable func _i1(item i: T, side sd: Side) -> ND {
        if let n = self[sd] { return n.insert(item: i) }
        let n = ND(item: item, color: .Red)
        self[sd] = n
        return n._i2()
    }

    @usableFromInline func _i2() -> ND { _withParent { _i3() } do: { ($0 == Color.Red) ? root : _i4($0, $1) } }

    @inlinable func _i3() -> ND { color = .Black; return self }

    @inlinable func _i4(_ p: ND, _ ns: Side) -> ND { p._withParent(ERR_NO_GRANDPARENT) { _i5($0, p, ns, $1) } }

    @inlinable func _i5(_ g: ND, _ p: ND, _ ns: Side, _ ps: Side) -> ND {
        _with(node: g[!ps]) { (($0 == Color.Black) ? _i6(g, p, ns, ps) : _i7(g, p, $0)) } else: { _i6(g, p, ns, ps) }
    }

    @inlinable func _i6(_ g: ND, _ p: ND, _ ns: Side, _ ps: Side) -> ND {
        if ps != ns { p._rotate(ps) }
        g._rotate(!ps)
        return root
    }

    @inlinable func _i7(_ g: ND, _ p: ND, _ u: ND) -> ND {
        p.color = .Black
        u.color = .Black
        g.color = .Red
        return g._i2()
    }
}

