// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

//@f:0
let package = Package(
    name: "RedBlackTree",
    platforms: [ .macOS(.v10), .tvOS(.v13), .iOS(.v13), .watchOS(.v6), ],
    products: [ .library(name: "RedBlackTree", targets: [ "RedBlackTree", ]), ],
    dependencies: [],
    targets: [
        .target(name: "RedBlackTree", dependencies: [], exclude: [ "Info.plist", ]),
        .testTarget(name: "RedBlackTreeTests", dependencies: [ "RedBlackTree", ], exclude: [ "Info.plist", ]),
    ]
)
//@f:1
