// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "UltraHFRKit",
    defaultLocalization: "fr",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "HFRContent", targets: ["HFRContent"]),
        .library(name: "HFRKit", targets: ["HFRKit"]),
    ],
    dependencies: [
        // Lecture du HTML de HFR (MIT). Seule dépendance externe du projet.
        .package(url: "https://github.com/scinfu/SwiftSoup.git", .upToNextMinor(from: "2.13.9")),
    ],
    targets: [
        .target(name: "HFRContent"),
        .target(
            name: "HFRKit",
            dependencies: [
                "HFRContent",
                .product(name: "SwiftSoup", package: "SwiftSoup"),
            ]
        ),
        .testTarget(name: "HFRContentTests", dependencies: ["HFRContent"]),
        .testTarget(
            name: "HFRKitTests",
            dependencies: ["HFRKit"],
            resources: [.copy("Fixtures")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
