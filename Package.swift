// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Beekeeper",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "Beekeeper", targets: ["Beekeeper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.1"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.3"),
        .package(url: "https://github.com/pointfreeco/swift-clocks.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "Beekeeper", dependencies: [
            .product(name: "CryptoSwift", package: "CryptoSwift"),
            .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            .product(name: "Clocks", package: "swift-clocks"),
        ]),
        .testTarget(name: "BeekeeperTests", dependencies: ["Beekeeper"]),
    ],
    swiftLanguageModes: [.version("6")]
)
