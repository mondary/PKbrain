// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PKbrain",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PKbrain", targets: ["PKbrain"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.0")
    ],
    targets: [
        .executableTarget(
            name: "PKbrain",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "src/macos/PKbrain",
            resources: [
                .copy("Resources/RedactedScript-Regular.ttf"),
                .copy("Resources/BrandIcons"),
                .copy("Resources/VERSION"),
                .copy("Resources/kofi-logo.png"),
                .copy("Resources/ProjectIcons"),
                .copy("Resources/ProjectScreenshots"),
                .process("Resources/Localizations")
            ]
        )
    ]
)
