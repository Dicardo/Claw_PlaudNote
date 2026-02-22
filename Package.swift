// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PlaudNote",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PlaudNote",
            targets: ["PlaudNote"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PlaudNote",
            dependencies: []),
    ]
)
