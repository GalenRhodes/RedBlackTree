/*****************************************************************************************************************************//**
 *     PROJECT: RedBlackTree
 *    FILENAME: RedBlackTreeSet.swift
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

let s: Set<String> = []

public class RedBlackTreeSet<Element>: BidirectionalCollection, ExpressibleByArrayLiteral, Equatable where Element: Comparable & Equatable {
    public typealias ArrayLiteralElement = Element
    public typealias Index = TreeNode<Element>.Index

    public let startIndex: Index = Index(index: 0)
    public var count:      Int { (rootNode?.count ?? 0) }

    @usableFromInline var rootNode:   TreeNode<Element>? = nil
    @usableFromInline let trackOrder: Bool

    public required init() { trackOrder = false }

    public init(trackOrder: Bool) { self.trackOrder = trackOrder }

    public convenience init(from decoder: Decoder, trackOrder: Bool) throws where Element: Decodable {
        self.init(trackOrder: trackOrder)
        var c = try decoder.unkeyedContainer()
        while !c.isAtEnd { insert(try c.decode(Element.self)) }
    }

    public convenience required init(from decoder: Decoder) throws where Element: Decodable { try self.init(from: decoder, trackOrder: false) }

    public convenience required init(arrayLiteral elements: Element...) {
        self.init()
        for e in elements { insert(e) }
    }

    public convenience init(elements: [Element], trackOrder: Bool = false) {
        self.init(trackOrder: trackOrder)
        for e in elements { insert(e) }
    }

    public convenience required init<Source>(_ sequence: Source) where Element == Source.Element, Source: Sequence {
        self.init()
        for e: Element in sequence { insert(e) }
    }

    public func removeAll(keepingCapacity: Bool = false) {
        guard let r = rootNode else { return }
        rootNode = nil
        DispatchQueue(label: UUID().uuidString).async { r.removeAll() }
    }

    @usableFromInline func node(forElement e: Element) -> TreeNode<Element>? {
        guard let r = rootNode else { return nil }
        return r[e]
    }

    @usableFromInline func node(at index: Index) -> TreeNode<Element> {
        guard let r = rootNode else { fatalError("Index out of bounds.") }
        return r[index]
    }

    @usableFromInline func remove(node: TreeNode<Element>) { rootNode = node.remove() }

    @usableFromInline func insert(_ newElement: Element, force: Bool) -> (inserted: Bool, oldElement: Element?) {
        guard let r = rootNode else {
            rootNode = TreeNode<Element>(value: newElement)
            return (inserted: true, oldElement: nil)
        }
        guard let n = r[newElement] else {
            rootNode = r.insert(value: newElement).rootNode
            return (inserted: true, oldElement: nil)
        }
        guard force else { return (inserted: false, oldElement: n.value) }
        rootNode = n.remove()
        return insert(newElement, force: force)
    }
}
