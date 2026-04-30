// swift-tools-version: 5.9
// This is a Skip (https://skip.dev) package.
import PackageDescription

let package = Package(
    name: "showcase",
    defaultLocalization: "ru",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ShowcaseCore", type: .dynamic, targets: ["ShowcaseCore"]),
        .library(name: "ShowcaseUI", type: .dynamic, targets: ["ShowcaseUI"]),
        .library(name: "ShowcaseApp", type: .dynamic, targets: ["ShowcaseApp"]),
        .library(name: "Showcase", type: .dynamic, targets: ["Showcase"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.8.9"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.9.1"),
        .package(url: "https://source.skip.tools/skip-supabase.git", from: "0.3.0"),
        .package(url: "https://source.skip.tools/skip-av.git", from: "0.7.0"),
        .package(url: "https://source.skip.tools/skip-unit.git", from: "1.6.0")
    ],
    targets: [
        // ShowcaseCore: Models, Services, Business Logic
        .target(
            name: "ShowcaseCore",
            dependencies: [
                .product(name: "SkipSupabase", package: "skip-supabase"),
                .product(name: "SkipAV", package: "skip-av")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
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
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        
        // ShowcaseApp: Entry Point
        .target(
            name: "ShowcaseApp",
            dependencies: [
                "ShowcaseCore",
                "ShowcaseUI"
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        
        // Legacy/Direct Showcase Target
        .target(
            name: "Showcase",
            dependencies: [
                .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
                .product(name: "SkipAV", package: "skip-av"),
                .product(name: "SkipSupabase", package: "skip-supabase")
            ],
            resources: [.process("Resources")],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        
        // Tests
        .testTarget(
            name: "ShowcaseCoreTests",
            dependencies: [
                "ShowcaseCore",
                .product(name: "SkipUnit", package: "skip-unit"),
                .product(name: "SkipTest", package: "skip", condition: .when(platforms: [.macOS, .linux]))
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        .testTarget(
            name: "ShowcaseUITests",
            dependencies: [
                "ShowcaseUI",
                .product(name: "SkipUnit", package: "skip-unit"),
                .product(name: "SkipTest", package: "skip", condition: .when(platforms: [.macOS, .linux]))
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        .testTarget(
            name: "ShowcaseAppTests",
            dependencies: [
                "ShowcaseApp",
                .product(name: "SkipUnit", package: "skip-unit"),
                .product(name: "SkipTest", package: "skip", condition: .when(platforms: [.macOS, .linux]))
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
    ]
)
