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
            from: "2.0.0",
            traits: [
                .trait(name: "Foundation", condition: .when(traits: ["Foundation"]))
            ]
        ),
        .package(
            url: "https://github.com/CharlesJS/DataParser",
            from: "0.5.0",
            traits: [
                .trait(name: "Foundation", condition: .when(traits: ["Foundation"]))
            ]
        ),
        .package(url: "https://github.com/CharlesJS/HFSTypeConversion", from: "0.1.1"),
        .package(url: "https://github.com/swift-extras/swift-extras-base64.git", from: "0.7.0"),
    ],
    targets: [
        .systemLibrary(name: "CSFileInfo_Membership"),
        .target(
            name: "CSFileInfo",
            dependencies: [
                "CSErrors",
                "DataParser",
                "HFSTypeConversion",
                "CSFileInfo_Membership",
                .product(name: "ExtrasBase64", package: "swift-extras-base64"),
            ]
        ),
        .testTarget(
            name: "CSFileInfoTests",
            dependencies: ["CSFileInfo"],
            resources: [
                .copy("fixtures")
            ]
        ),
    ]
)
