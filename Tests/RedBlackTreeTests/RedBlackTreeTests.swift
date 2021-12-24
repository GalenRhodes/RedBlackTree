//
//  RedBlackTreeTests.swift
//  RedBlackTreeTests
//
//  Created by Galen Rhodes on 7/30/21.
//

import XCTest
@testable import RedBlackTree

class RedBlackTreeTests: XCTestCase {
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testInserts() throws {}

    #if !(os(macOS) || os(tvOS) || os(iOS) || os(watchOS))
        public static var allTests: [(String, (ExecutorTests) -> () throws -> Void)] {
            [ ("RedBlackTreeTests", testInserts), ]
        }
    #endif
}
