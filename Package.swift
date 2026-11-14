// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoiceTodo",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "VoiceTodo",
            targets: ["VoiceTodo"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VoiceTodo",
            dependencies: [],
            path: "Sources/VoiceTodo"
        )
    ]
)
