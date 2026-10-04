// swift-tools-version: 6.2
// This is a Skip (https://skip.dev) package.
import PackageDescription

let package = Package(
    name: "showcase",
    defaultLocalization: "ru",
    // macOS floor: SwiftPM defaults unspecified platforms to macOS 10.13,
    // but Skip dependencies require macOS 13+ and the code uses
    // @Observable/Observation which requires macOS 14+. Without this floor
    // both local `swift build` and the CI `swift test` fail.
    platforms: [.iOS(.v26), .macOS(.v14)],
    products: [
        .library(name: "ShowcaseCore", targets: ["ShowcaseCore"]),
        .library(name: "ShowcaseUI", targets: ["ShowcaseUI"]),
        .library(name: "Showcase", targets: ["Showcase"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.9.2"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.16.0"),
        .package(url: "https://source.skip.tools/skip-supabase.git", from: "0.3.0"),
        .package(url: "https://source.skip.tools/skip-av.git", from: "0.7.1"),
        .package(url: "https://source.skip.tools/skip-unit.git", from: "1.7.0"),
        .package(url: "https://source.skip.tools/skip-ui.git", from: "1.55.0"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.4.0")
    ],
    targets: [
        // ShowcaseCore: Models, Services, Business Logic
        .target(
            name: "ShowcaseCore",
            dependencies: [
                .product(name: "SkipFoundation", package: "skip-foundation"),
                .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
                .product(name: "SkipSupabase", package: "skip-supabase"),
                .product(name: "SkipAV", package: "skip-av")
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        
        // ShowcaseUI: Views, Components, Theme
        .target(
            name: "ShowcaseUI",
            dependencies: [
                "ShowcaseCore",
                .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
                .product(name: "SkipAV", package: "skip-av")
            ],
            resources: [.process("Resources")],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        
        
        .target(
            name: "Showcase",
            dependencies: [
                "ShowcaseCore",
                "ShowcaseUI",
                .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
                .product(name: "SkipAV", package: "skip-av"),
                .product(name: "SkipSupabase", package: "skip-supabase")
            ],
            resources: [.process("Resources")],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),

        // Test targets. These were present on disk but never declared, so
        // `swift test` had nothing to run and CI silently compiled zero tests.
        .testTarget(
            name: "ShowcaseCoreTests",
            dependencies: ["ShowcaseCore"]
        ),

        .testTarget(
            name: "ShowcaseTests",
            dependencies: ["Showcase"]
        ),

        .testTarget(
            name: "ShowcaseUITests",
            dependencies: ["ShowcaseUI"]
        ),
    ]
)
