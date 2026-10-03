// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "DevBar", platforms: [.macOS(.v14)],
    products: [.executable(name: "DevBar", targets: ["DevBar"])],
    targets: [
        .target(name: "DevBarCore", path: "Sources/Core"),
        .executableTarget(name: "DevBar", dependencies: ["DevBarCore"], path: "Sources", exclude: ["Core"]),
        .testTarget(name: "DevBarCoreTests", dependencies: ["DevBarCore"])
    ]
)
