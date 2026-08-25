// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LmsApi",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "LmsApi",
            targets: ["LmsApi"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "LmsApi",
            path: "LmsApi.xcframework"
        )
    ]
)
