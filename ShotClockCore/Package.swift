// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ShotClockCore",
    platforms: [.watchOS("27.0"), .macOS(.v26)],
    products: [
        .library(name: "ShotClockCore", targets: ["ShotClockCore"])
    ],
    targets: [
        .target(name: "ShotClockCore"),
        .testTarget(name: "ShotClockCoreTests", dependencies: ["ShotClockCore"]),
    ]
)
