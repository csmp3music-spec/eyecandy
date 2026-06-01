// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "eyecandy",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "eyecandy", targets: ["eyecandy"])
    ],
    targets: [
        .executableTarget(
            name: "eyecandy",
            path: "Sources/eyecandy"
        )
    ]
)
