// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "CSFileInfo",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "CSFileInfo",
            targets: ["CSFileInfo"]
        ),
    ],
    traits: [
        "Foundation",
    ],
    dependencies: [
        .package(
            url: "https://github.com/CharlesJS/CSErrors",
            from: "2.1.0",
            traits: [
                .trait(name: "Foundation", condition: .when(traits: ["Foundation"]))
            ]
        ),
        .package(
            url: "https://github.com/CharlesJS/DataParser",
            from: "0.6.0",
            traits: [
                .trait(name: "Foundation", condition: .when(traits: ["Foundation"]))
            ]
        ),
        .package(url: "https://github.com/CharlesJS/HFSTypeConversion", from: "0.1.4"),
        .package(url: "https://github.com/swift-extras/swift-extras-base64.git", from: "0.7.0"),
    ],
    targets: [
        .systemLibrary(
            name: "CSFileInfo_CShims",
            providers: [
                .apt(["libacl1-dev", "uuid-dev"]),
            ]
        ),
        .target(
            name: "CSFileInfo",
            dependencies: [
                "CSErrors",
                "DataParser",
                "HFSTypeConversion",
                "CSFileInfo_CShims",
                .product(name: "ExtrasBase64", package: "swift-extras-base64"),
            ],
            linkerSettings: [
                .linkedLibrary("acl", .when(platforms: [.linux]))
            ]
        ),
        .testTarget(
            name: "CSFileInfoTests",
            dependencies: ["CSFileInfo", "CSFileInfo_CShims"],
            resources: [
                .copy("fixtures")
            ]
        ),
    ]
)
