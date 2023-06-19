// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Subsystem",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "Subsystem",
            targets: ["Subsystem"]
        ),
    ],
    targets: [
        .target(
            name: "Subsystem"
        )
    ]
)
