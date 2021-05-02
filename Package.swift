// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "deft-mcp2221-i2c-gpio",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DeftMCP2221",
            targets: ["DeftMCP2221"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/didactek/deft-simple-usb", "0.0.1" ..< "0.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DeftMCP2221",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SimpleUSB", package: "deft-simple-usb"),
            ]),
        .testTarget(
            name: "DeftMCP2221Tests",
            dependencies: ["DeftMCP2221"]),
    ]
)
