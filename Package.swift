// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftWAMP",
    platforms: [.iOS(.v9), .macOS(.v10_12), .tvOS(.v9)],
    products: [
        .library(
            name: "SwiftWAMP",
            targets: ["SwiftWAMP"]),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMinor(from: "4.0.0")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.3.2")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMinor(from: "5.0.0")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "8.0.1"))
    ],
    targets: [
        .target(
            name: "SwiftWAMP",
            dependencies: ["CryptoSwift", "Starscream", "SwiftyJSON"]),
        .testTarget(
            name: "SwiftWAMPTests",
            dependencies: ["SwiftWAMP", "CryptoSwift", "Starscream", "SwiftyJSON", "Quick", "Nimble"]),
    ],
    swiftLanguageVersions: [.v5]
)
