/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: NodeTestValue.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: August 09, 2021
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
@testable import RedBlackTree

extension NSSize {
    @inlinable func expand(width: CGFloat = 0, height: CGFloat = 0) -> NSSize { NSSize(width: self.width + width, height: self.height + height) }
}

struct NodeTestValue: Hashable, CustomStringConvertible, Codable {

    private let guid: String

    var description: String { bounds.debugDescription }
    var bounds:      NSRect = NSRect(x: 0, y: 0, width: 0, height: 0)

    enum CodingKeys: String, CodingKey {
        case guid, bounds
    }

    init() { guid = UUID().uuidString }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guid = try container.decode(String.self, forKey: .guid)
        bounds = try container.decode(NSRect.self, forKey: .bounds)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(guid, forKey: .guid)
        try container.encode(bounds, forKey: .bounds)
    }

    static func == (lhs: NodeTestValue, rhs: NodeTestValue) -> Bool { lhs.guid == rhs.guid }

    func hash(into hasher: inout Hasher) {
        hasher.combine(guid)
    }
}
