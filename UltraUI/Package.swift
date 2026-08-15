// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UltraUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "UltraUI", targets: ["UltraUI"])
    ],
    targets: [
        .target(name: "UltraUI"),
        .testTarget(name: "UltraUITests", dependencies: ["UltraUI"])
    ]
)
