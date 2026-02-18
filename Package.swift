// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "macos-quick-translate",
    platforms: [
        .macOS("15.0")
    ],
    products: [
        .library(name: "QuickTranslateCore", targets: ["QuickTranslateCore"]),
        .executable(name: "quick-translate-cli", targets: ["quick-translate-cli"]),
        .executable(name: "quick-translate-macos", targets: ["quick-translate-macos"])
    ],
    targets: [
        .target(name: "QuickTranslateCore"),
        .executableTarget(
            name: "quick-translate-cli",
            dependencies: ["QuickTranslateCore"]
        ),
        .executableTarget(
            name: "quick-translate-macos",
            dependencies: ["QuickTranslateCore"]
        ),
        .testTarget(
            name: "QuickTranslateCoreTests",
            dependencies: ["QuickTranslateCore"]
        )
    ]
)
