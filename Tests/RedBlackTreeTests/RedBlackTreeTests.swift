//
//  RedBlackTreeTests.swift
//  RedBlackTreeTests
//
//  Created by Galen Rhodes on 7/30/21.
//

import XCTest
@testable import RedBlackTree

class RedBlackTreeTests: XCTestCase {
    lazy var fm:         FileManager = FileManager.default
    lazy var currDir:    URL         = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    lazy var outputDir:  URL         = URL(fileURLWithPath: "testout", isDirectory: true, relativeTo: currDir)
    lazy var imagesDir:  URL         = URL(fileURLWithPath: "images", isDirectory: true, relativeTo: outputDir)
    lazy var codableDir: URL         = URL(fileURLWithPath: "codable", isDirectory: true, relativeTo: outputDir)
    lazy var copyDir:    URL         = URL(fileURLWithPath: "copy", isDirectory: true, relativeTo: outputDir)

    let TestSet: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$%^&*()_-+=':;>.<,?|`~/\\🤣"

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testCodable() throws {
        try clearDirectory(url: codableDir, description: "codable")
        let tree:           BinaryTreeDictionary<String, NodeTestValue> = BinaryTreeDictionary<String, NodeTestValue>()
        let dataIns:        [Character]                                 = TestSet.shuffled()
        let imageBeforeURL: URL                                         = URL(fileURLWithPath: "Codable-Before.png", relativeTo: codableDir)
        let imageAfterURL:  URL                                         = URL(fileURLWithPath: "Codable-After.png", relativeTo: codableDir)
        let jsonURL:        URL                                         = URL(fileURLWithPath: "Codable.json", relativeTo: codableDir)
        let encoder:        JSONEncoder                                 = JSONEncoder()
        let decoder:        JSONDecoder                                 = JSONDecoder()

        for ch in dataIns { tree[String(ch)] = NodeTestValue() }
        try autoreleasepool { try tree.base.rootNode?.drawTree(url: imageBeforeURL) }

        encoder.outputFormatting = [ .sortedKeys, .prettyPrinted ]
        let data = try encoder.encode(tree)
        try data.write(to: jsonURL)

        let decodedTree = try decoder.decode(BinaryTreeDictionary<String, NodeTestValue>.self, from: data)
        try autoreleasepool { try decodedTree.base.rootNode?.drawTree(url: imageAfterURL) }
    }

//    func testInOrder() throws {
//        let tree:    BinaryTreeDictionary<String, NodeTestValue> = BinaryTreeDictionary<String, NodeTestValue>(trackOrder: true)
//        let dataIns: [Character]                           = TestSet.shuffled()
//        let dataDel: [Character]                           = Array<Character>(dataIns.shuffled()[0 ..< 10]).shuffled()
//
//        print("Inserting: ", terminator: "")
//        var str1: String = ""
//        for ch in dataIns {
//            let s = String(ch)
//            str1 += s
//            print(s, terminator: "")
//            tree[s] = NodeTestValue()
//        }
//        print("")
//
//        print(" Checking: ", terminator: "")
//        var str2: String = ""
//        tree.forEachInInsertOrder {
//            let s: String = $0.key
//            str2 += s
//            print(s, terminator: "")
//        }
//        print("")
//        print("")
//
//        guard str1 == str2 else { XCTFail("Strings don't match: \"\(str1)\" != \"\(str2)\""); return }
//        print("Strings match: \"\(str1)\" == \"\(str2)\"")
//
//        print("")
//        print("Removing: \"", terminator: "")
//        for ch in dataDel {
//            let s = String(ch)
//            print(s, terminator: "")
//            tree.removeValue(forKey: s)
//        }
//        print("\"")
//        print(" Results: \"", terminator: "")
//        tree.forEachInInsertOrder { print($0.key, terminator: "") }
//        print("\"")
//    }

    func testInserts() throws {
        try performTests(rounds: 1, doDelete: false, doDraw: true)
    }

    func testSlow() throws {
        try performTests(rounds: 1, doDelete: true, doDraw: true)
    }

    func testFast() throws {
        try performTests(rounds: 1000, doDelete: true, doDraw: false)
    }

    func testFastCopyPerformance() throws {
        try copyPerformanceTest(fast: true)
    }

    func testSlowCopyPerformance() throws {
        try copyPerformanceTest(fast: false)
    }

    func copyPerformanceTest(fast: Bool) throws {
        let tree:          BinaryTreeDictionary<String, NodeTestValue> = BinaryTreeDictionary<String, NodeTestValue>()
        //let dataIns:       [Character]                                 = TestSet.shuffled()
        let copyDirURL:    URL                                         = URL(fileURLWithPath: (fast ? "fast" : "slow"), isDirectory: true, relativeTo: copyDir)
        let imageAfterURL: URL                                         = URL(fileURLWithPath: "Copy-Performance-\(fast ? "Fast" : "Slow")-Final.png", relativeTo: copyDirURL)

        try fm.createDirectory(at: copyDirURL, withIntermediateDirectories: true)
        print("Creating data set...")
        var cc = tree.count
        while cc < 100000 {
            var str = String(Int.random(in: 0 ..< Int.max))
            tree[str] = NodeTestValue()
            cc = tree.count
            if ((cc % 10000) == 0) { print("\(cc)") }
            else if ((cc % 1000) == 0) { print(".", terminator: "") }
        }
        print("")
        var copy: BinaryTreeDictionary<String, NodeTestValue>? = nil

        DoCopyFast = fast
        print("Performing Test Copies...")
        self.measure {
            let c = BinaryTreeDictionary<String, NodeTestValue>(tree)
            print("Copy Count: \(c.count)")
            copy = c
        }

        if let c = copy {
            print("Removing all but 50 items...")
            var cc = c.count
            while cc > 50 {
                let idx = TreeIndex(Int.random(in: c.startIndex.idx ..< c.endIndex.idx))
                c.remove(at: idx)
                cc -= 1
                if ((cc % 1000) == 0) { print("\(cc)") }
                else { print(".", terminator: "") }
            }
            print("")
            print("Saving image of final copy...")
            try autoreleasepool { try c.base.rootNode?.drawTree(url: imageAfterURL) }
        }
    }

    func performTests(rounds: Int, doDelete: Bool, doDraw: Bool) throws {
        if doDraw { try clearDirectory(url: imagesDir, description: "images") }

        for x in (1 ... rounds) {
            print("Round \(x) of \(rounds)...")

            let tree:    BinaryTreeDictionary<String, NodeTestValue> = BinaryTreeDictionary<String, NodeTestValue>()
            let dataIns: [Character]                                 = TestSet.shuffled()
            let dataDel: [Character]                                 = Array<Character>(dataIns.shuffled()[0 ..< (dataIns.count / 2)])

            for i in (0 ..< dataIns.count) {
                let str = String(dataIns[i])
                tree[str] = NodeTestValue()
                if doDraw {
                    try autoreleasepool {
                        try drawTreeImage(action: "insert", round: x, imageNumber: i, tree: tree)
                    }
                }
                if rounds == 1 {
                    print("Inserting: \"\(str == "\"" ? "\\\"" : str)\"")
                }
            }

            if doDelete {
                for j in (0 ..< dataDel.count) {
                    let str = String(dataDel[j])
                    if rounds == 1 {
                        print("Removing: \"\(str == "\"" ? "\\\"" : str)\"")
                    }
                    tree.removeValue(forKey: str)
                    if doDraw {
                        try autoreleasepool {
                            try drawTreeImage(action: "remove", round: x, imageNumber: j, tree: tree)
                        }
                    }
                }
            }

            tree.removeAll()
        }
    }

    func clearDirectory(url: URL, description desc: String) throws {
        print("Clearing \(desc) folder: \(url.absoluteString)")
        do { try fm.removeItem(at: url) }
        catch let e { print("ERROR: \(e)") }
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func drawTreeImage(action a: String, round i: Int, imageNumber j: Int, tree: BinaryTreeDictionary<String, NodeTestValue>) throws {
        let url = URL(fileURLWithPath: "Sample_\(a)_\(i)_\(j + 1).png", relativeTo: imagesDir)
        try tree.base.rootNode?.drawTree(url: url)
    }

    #if !(os(macOS) || os(tvOS) || os(iOS) || os(watchOS))
        public static var allTests: [(String, (ExecutorTests) -> () throws -> Void)] {
            [ ("RedBlackTreeTests", testInserts),
              ("RedBlackTreeTests", testSlow),
              ("RedBlackTreeTests", testFast),
              ("RedBlackTreeTests", testCodable),
              ("RedBlackTreeTests", testSlowCopyPerformance),
              ("RedBlackTreeTests", testFastCopyPerformance),
            ]
        }
    #endif
}
