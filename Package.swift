// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Beekeeper",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(name: "Beekeeper", targets: ["Beekeeper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChaosCoder/ConvAPI.git", .branch("master")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.3.8"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.8.0"),
    ],
    targets: [
        .target(name: "Beekeeper", dependencies: ["ConvAPI", "CryptoSwift", "PromiseKit"]),
        .testTarget(name: "BeekeeperTests", dependencies: ["Beekeeper"]),
    ]
)
