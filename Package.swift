// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "eyecandy",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "eyecandy",
            targets: ["eyecandy"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "eyecandy"
        ),
    ],
    swiftLanguageModes: [.v5]
)
