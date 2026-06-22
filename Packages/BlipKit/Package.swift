// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BlipKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BlipKit", targets: ["BlipKit"]),
    ],
    targets: [
        .target(name: "BlipKit"),
        .testTarget(name: "BlipKitTests", dependencies: ["BlipKit"]),
    ]
)
