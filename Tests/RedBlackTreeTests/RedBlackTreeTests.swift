//
//  RedBlackTreeTests.swift
//  RedBlackTreeTests
//
//  Created by Galen Rhodes on 7/30/21.
//

import XCTest
@testable import RedBlackTree

class RedBlackTreeTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInsert() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testDelete() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    #if !(os(macOS) || os(tvOS) || os(iOS) || os(watchOS))
        public static var allTests: [(String, (ExecutorTests) -> () throws -> Void)] {
            [ ("RedBlackTreeTests", testInsert),
              ("RedBlackTreeTests", testDelete), ]
        }
    #endif
}
