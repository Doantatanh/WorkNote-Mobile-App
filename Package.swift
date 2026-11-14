// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WorkNote",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "WorkNote",
            targets: ["VoiceTodo"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "VoiceTodo",
            dependencies: [],
            path: "Sources/VoiceTodo"
        )
    ]
)
