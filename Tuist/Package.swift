// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "Lottie": .framework,
            "ProtonUIFoundations": .framework,
        ],
        baseSettings: .settings(
            configurations: [
                .debug(name: "Debug"),
                .debug(name: "Debug-Dev"),
                .release(name: "Release"),
            ]
        )
    )
#endif

let package = Package(
    name: "LumoDependencies",
    dependencies: [
        .package(url: "git@gitlab.protontech.ch:apple/shared/ProtonUIFoundations.git", from: "1.4.4"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.5.2"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.18.9"),
    ]
)
