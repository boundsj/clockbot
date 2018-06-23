// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "clockbot",
    dependencies: [
        .package(url: "https://github.com/boundsj/websocket.git", .revision("834511bcb0f39b571918853e05b77587c93a2c0c"))
    ],
    targets: [
        .target(name: "clockbot", dependencies: ["WebSocket"]),
    ]
)
