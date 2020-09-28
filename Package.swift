// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftWAMP",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13)],
    products: [
        .library(
            name: "SwiftWAMP",
            targets: ["SwiftWAMP"]),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMinor(from: "4.0.0")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.3.2"))
    ],
    targets: [
        .target(
            name: "SwiftWAMP",
            dependencies: ["Starscream", "CryptoSwift"]),
        .testTarget(
            name: "SwiftWAMPTests",
            dependencies: ["SwiftWAMP", "Starscream", "CryptoSwift"]),
    ],
    swiftLanguageVersions: [.v5]
)
