// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "JyotishKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "EphemerisKit", targets: ["EphemerisKit"]),
    ],
    targets: [
        .target(
            name: "CSwissEph",
            exclude: ["LICENSE", "LICENSE.TXT", "agpl-3.0.txt"],
            publicHeadersPath: "include",
            cSettings: [
                .define("NO_SWE_GLP"),
            ],
            linkerSettings: [
                .linkedLibrary("m"),
            ]
        ),
        .target(
            name: "EphemerisKit",
            dependencies: ["CSwissEph"],
            resources: [.copy("Resources/ephe")]
        ),
        .testTarget(
            name: "EphemerisKitTests",
            dependencies: ["EphemerisKit"]
        ),
    ]
)
