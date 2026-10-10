// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PowerModes",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PowerModesCore", targets: ["PowerModesCore"]),
        .executable(name: "PowerModes", targets: ["PowerModesApp"]),
        .executable(name: "PowerModesHelper", targets: ["PowerModesHelper"])
    ],
    targets: [
        .target(name: "PowerModesCore"),
        .executableTarget(name: "PowerModesApp", dependencies: ["PowerModesCore"]),
        .executableTarget(name: "PowerModesHelper", dependencies: ["PowerModesCore"]),
        .testTarget(name: "PowerModesCoreTests", dependencies: ["PowerModesCore"])
    ]
)
