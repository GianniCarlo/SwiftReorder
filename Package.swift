// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftReorder",
	platforms: [.iOS(.v10),
				.tvOS(.v11)],
    products: [
        .library(
            name: "SwiftReorder",
            targets: ["SwiftReorder"]),
    ],
    targets: [
        .target(
            name: "SwiftReorder",
            dependencies: []),
    ]
)
