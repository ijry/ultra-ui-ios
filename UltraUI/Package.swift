// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UltraUI",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "UltraUI", targets: ["UltraUI"])
    ],
    targets: [
        .target(name: "UltraUI", resources: [.process("Resources")]),
        .testTarget(name: "UltraUITests", dependencies: ["UltraUI"])
    ]
)
