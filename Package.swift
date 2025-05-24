// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AICompanion",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AICompanion",
            targets: ["AICompanion"]),
    ],
    dependencies: [
        // Supabase Swift SDK
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
        // KeychainAccess for secure storage
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        // OpenAI Swift SDK
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.2.4"),
        // Anthropic Swift SDK
        .package(url: "https://github.com/jamesrochabrun/SwiftAnthropic.git", from: "2.1.4"),
        // Markdown rendering
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui.git", from: "2.4.0"),
        // Syntax highlighting for code blocks
        .package(url: "https://github.com/raspu/Highlightr.git", from: "2.1.2"),
        // Combine schedulers for advanced timing operations
        .package(url: "https://github.com/pointfreeco/combine-schedulers.git", from: "1.0.0"),
        // CRDT implementation for collaborative editing
        .package(url: "https://github.com/automerge/automerge-swift.git", from: "0.4.0")
    ],
    targets: [
        .target(
            name: "AICompanion",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                "KeychainAccess",
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "SwiftAnthropic", package: "SwiftAnthropic"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                "Highlightr",
                .product(name: "CombineSchedulers", package: "combine-schedulers"),
                .product(name: "Automerge", package: "automerge-swift")
            ],
            // System frameworks
            swiftSettings: [
                .unsafeFlags([
                    "-framework", "EventKit",
                    "-framework", "CoreML",
                    "-framework", "ARKit",
                    "-framework", "RealityKit",
                    "-framework", "CoreLocation",
                    "-framework", "Combine",
                    "-framework", "UserNotifications"
                ])
            ]),
        .testTarget(
            name: "AICompanionTests",
            dependencies: ["AICompanion"],
            swiftSettings: [
                .unsafeFlags([
                    "-framework", "EventKit",
                    "-framework", "CoreML",
                    "-framework", "ARKit",
                    "-framework", "RealityKit",
                    "-framework", "CoreLocation",
                    "-framework", "Combine",
                    "-framework", "UserNotifications",
                    "-framework", "XCTest"
                ])
            ]),
    ]
)
