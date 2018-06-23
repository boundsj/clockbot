// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "clockbot",
    dependencies: [
        .package(url: "https://github.com/boundsj/ArgyleKit.git", .revision("4f0a57d016627d9446f58025fac43b9a4b2cae7a"))
    ],
    targets: [
        .target(name: "clockbot", dependencies: ["ArgyleKit"]),
    ]
)
