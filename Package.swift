// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HitRivals",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "HitRivals",
            targets: ["HitRivals"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "HitRivals",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "HitRivals"
        ),
        .testTarget(
            name: "HitRivalsTests",
            dependencies: ["HitRivals"],
            path: "HitRivalsTests"
        ),
    ]
) 