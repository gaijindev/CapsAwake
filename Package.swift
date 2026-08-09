// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CapsAwake",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CapsAwakeCore", targets: ["CapsAwakeCore"]),
        .executable(name: "CapsAwake", targets: ["CapsAwake"])
    ],
    targets: [
        .target(name: "CapsAwakeCore"),
        .executableTarget(name: "CapsAwake", dependencies: ["CapsAwakeCore"], path: "Sources/CapsAwakeApp"),
        .testTarget(name: "CapsAwakeCoreTests", dependencies: ["CapsAwakeCore"])
    ]
)
