/*===============================================================================================================================================================================*
 *     PROJECT: RedBlackTree
 *    FILENAME: TreeIteratorOwner.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 1/5/22
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

@usableFromInline let ALL_NODES_REMOVED_NOTIFICATION: Notification.Name = Notification.Name("ALL_NODES_REMOVED_NOTIFICATION_NAME")
@usableFromInline let NODE_REMOVED_NOTIFICATION:      Notification.Name = Notification.Name("NODE_REMOVED_NOTIFICATION_NAME")
@usableFromInline let NODE_INSERTED_NOTIFICATION:     Notification.Name = Notification.Name("NODE_INSERTED_NOTIFICATION_NAME")

@usableFromInline protocol TreeIteratorOwner {
    associatedtype E
    associatedtype L where L: TreeListener, L.E == E

    var notificationCenter: NotificationCenter { get }
    var queue:              DispatchQueue { get }

    var treeRoot: Node<E>? { get }

    func addTreeIteratorListener(_ listener: L)

    func removeTreeIteratorListener(_ listener: L)
}

extension TreeIteratorOwner {
    @inlinable func addTreeIteratorListener(_ listener: L) {
        notificationCenter.addObserver(forName: ALL_NODES_REMOVED_NOTIFICATION, object: listener, queue: nil) { notification in }
        notificationCenter.addObserver(forName: NODE_REMOVED_NOTIFICATION, object: listener, queue: nil) { notification in }
        notificationCenter.addObserver(forName: NODE_INSERTED_NOTIFICATION, object: listener, queue: nil) { notification in }
    }

    @inlinable func removeTreeIteratorListener(_ listener: L) {
        notificationCenter.removeObserver(listener)
    }
}
