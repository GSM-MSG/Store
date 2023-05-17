// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Store",
    platforms: [.iOS(.v13), .tvOS(.v13), .macOS(.v10_15), .watchOS(.v7)],
    products: [
        .library(
            name: "Store",
            targets: ["Store"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Store",
            dependencies: []
        ),
        .testTarget(
            name: "StoreTests",
            dependencies: ["Store"]
        ),
    ]
)
