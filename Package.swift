// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "CSFileInfo",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "CSFileInfo",
            targets: ["CSFileInfo"]
        ),
        .library(
            name: "CSFileInfo+Foundation",
            targets: ["CSFileInfo_Foundation"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/CharlesJS/CSDataProtocol", from: "0.1.0"),
        .package(url: "https://github.com/CharlesJS/CSErrors", from: "1.2.4"),
        .package(url: "https://github.com/CharlesJS/DataParser", from: "0.3.2"),
        .package(url: "https://github.com/swift-extras/swift-extras-base64.git", from: "0.7.0"),
    ],
    targets: [
        .systemLibrary(name: "Membership"),
        .target(
            name: "CSFileInfo",
            dependencies: [
                "CSDataProtocol",
                "CSErrors",
                "DataParser",
                "Membership",
                .product(name: "ExtrasBase64", package: "swift-extras-base64"),
            ]
        ),
        .target(
            name: "CSFileInfo_Foundation",
            dependencies: [
                "CSFileInfo",
                .product(name: "CSDataProtocol+Foundation", package: "CSDataProtocol"),
                .product(name: "CSErrors+Foundation", package: "CSErrors"),
                .product(name: "DataParser+Foundation", package: "DataParser")
            ]
        ),
        .testTarget(
            name: "CSFileInfoTests",
            dependencies: ["CSFileInfo_Foundation"],
            resources: [
                .copy("fixtures")
            ]
        ),
    ]
)
