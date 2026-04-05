// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DarkNetwork",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "DarkNetwork", targets: ["DarkNetwork"])
    ],
    targets: [
        .target(
            name: "DarkNetwork",
            path: "Sources/DarkNetwork"
        ),
        .testTarget(
            name: "DarkNetworkTests",
            dependencies: ["DarkNetwork"],
            path: "Tests/DarkNetworkTests"
        )
    ]
)
