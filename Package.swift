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
        .package(url: "https://github.com/ChaosCoder/ConvAPI.git", from: "2.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.1"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.3"),
    ],
    targets: [
        .target(name: "Beekeeper", dependencies: [
            .product(name: "ConvAPI", package: "ConvAPI"),
            .product(name: "CryptoSwift", package: "CryptoSwift"),
            .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        ]),
        .testTarget(name: "BeekeeperTests", dependencies: ["Beekeeper"]),
    ],
    swiftLanguageModes: [.version("6")]
)
