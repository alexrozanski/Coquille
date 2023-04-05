// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Coquille",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Coquille",
            targets: ["Coquille"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Coquille",
            dependencies: []),
        .testTarget(
            name: "CoquilleTests",
            dependencies: ["Coquille"]),
    ]
)
