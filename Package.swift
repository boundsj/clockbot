// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "clockbot",
    dependencies: [
        .package(url: "https://github.com/boundsj/ArgyleKit.git", .revision("12efc6d585a63970a8d76f71fee9190593c55065"))
    ],
    targets: [
        .target(name: "clockbot", dependencies: ["ArgyleKit"]),
    ]
)
