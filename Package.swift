// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Beekeeper",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(name: "Beekeeper", targets: ["Beekeeper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChaosCoder/ConvAPI.git", from: "1.0.2"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.3.8"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.8.0"),
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
