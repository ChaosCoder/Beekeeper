// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Beekeeper",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(name: "Beekeeper", targets: ["Beekeeper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChaosCoder/ConvAPI.git", from: "2.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.1"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "8.0.0"),
    ],
    targets: [
        .target(name: "Beekeeper", dependencies: [
            .product(name: "ConvAPI", package: "ConvAPI"),
            .product(name: "CryptoSwift", package: "CryptoSwift"),
            .product(name: "PromiseKit", package: "PromiseKit"),
        ]),
        .testTarget(name: "BeekeeperTests", dependencies: ["Beekeeper"]),
    ]
)
