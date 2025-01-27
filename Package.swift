// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BrewUI",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BrewUI",
            targets: ["BrewUI"]),

    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/madmachineio/SwiftIO.git", branch: "develop"),
        .package(url: "https://github.com/madmachineio/MadBoards.git", branch: "develop"),
        .package(url: "https://github.com/madmachineio/MadDrivers.git", branch: "develop"),
        .package(url: "https://github.com/madmachineio/CFreeType", from: "2.13.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BrewUI",
            dependencies: [
                "SwiftIO",
                "MadBoards",
                .product(name: "ST7789", package: "MadDrivers"),
                "CFreeType",
            ]
            ),
        .testTarget(
            name: "BrewUITests",
            dependencies: ["BrewUI"]),
    ]
)
