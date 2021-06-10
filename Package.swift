// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "deft-mcp2221",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        // No need to export as part of product, but can still run locally:
        //.executable(name: "example", targets: ["example"]),
        .library(
            name: "DeftMCP2221",
            targets: ["DeftMCP2221"]),
        .library(name: "LibusbHIDAPI", targets: ["LibusbHIDAPI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/didactek/deft-log.git", from: "0.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DeftMCP2221",
            dependencies: [
                "LibusbHIDAPI",
                .product(name: "DeftLog", package: "deft-log"),
            ]),
        .target(
            name: "example",
            dependencies: [
                "DeftMCP2221",
            ]),
        .target(
            name: "LibusbHIDAPI",
            dependencies: [
                .target(name: "CHidApiLinux", condition: .when(platforms: [.linux])),
                .target(name: "CHidApi", condition: .when(platforms: [.macOS])),
            ]
        ),
        // CHidApi and CHidApiLinux libraries are the same in function and content;
        // they are duplicated here to work around the difficulty that they have different
        // pkg-config names on Linux and under brew.
        .systemLibrary(
            name: "CHidApi",
            pkgConfig: "hidapi",
            providers: [
                .brew(["hidapi"]),
            ]
        ),
        .systemLibrary(
            name: "CHidApiLinux",
            pkgConfig: "hidapi-libusb",
            providers: [
                .apt(["libhidapi-dev"]),
            ]
        ),
        //.testTarget(
        //    name: "DeftMCP2221Tests",
        //    dependencies: ["DeftMCP2221"]),
    ]
)
