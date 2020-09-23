// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftWAMP",
    platforms: [.iOS(.v13), .macOS(.v10_12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftWAMP",
            targets: ["SwiftWAMP"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMinor(from: "4.0.0")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.3.2")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMinor(from: "5.0.0")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "8.0.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftWAMP",
            dependencies: ["CryptoSwift", "Starscream", "SwiftyJSON"]),
        .testTarget(
            name: "SwiftWAMPTests",
            dependencies: ["SwiftWAMP", "CryptoSwift", "Starscream", "SwiftyJSON", "Quick", "Nimble"]),
    ],
    swiftLanguageVersions: [.v5]
)
