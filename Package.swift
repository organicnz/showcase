// swift-tools-version: 6.3.1
// This is a Skip (https://skip.dev) package.
import PackageDescription

let package = Package(
    name: "showcase",
    defaultLocalization: "ru",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Showcase", type: .dynamic, targets: ["Showcase"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.8.9"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.9.1"),
        .package(url: "https://source.skip.tools/skip-supabase.git", from: "0.3.0"),
        .package(url: "https://source.skip.tools/skip-av.git", from: "0.7.0")
    ],
    targets: [
        .target(name: "Showcase", dependencies: [
            .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
            .product(name: "SkipSupabase", package: "skip-supabase"),
            .product(name: "SkipAV", package: "skip-av")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
