// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "FocuraMac",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "FocuraMac",
            targets: ["FocuraMac"],
        ),
    ],
    targets: [
        .executableTarget(
            name: "FocuraMac",
            resources: [
                .process("Resources"),
            ],
        ),
        .testTarget(
            name: "FocuraMacTests",
            dependencies: ["FocuraMac"],
        ),
    ],
)
