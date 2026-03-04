// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TailBar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "TailBar"),
        .testTarget(
            name: "TailBarTests",
            dependencies: ["TailBar"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
