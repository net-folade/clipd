// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Clipd",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Clipd",
            path: "Sources/Clipd"
        ),
        .testTarget(
            name: "ClipdTests",
            dependencies: ["Clipd"],
            path: "Tests/ClipdTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
