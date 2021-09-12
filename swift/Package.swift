// swift-tools-version:5.4
import PackageDescription

let package = Package (
    name: "TTest",
    // platforms: [
    //     .macOS(.v10_15),
    //     .macOS(.v10_15),
    //     .macOS(.v10_15),
    //     .macOS(.v10_15),
    // ],
    products: [
        .executable(name: "t-test", targets: ["TTest"]),
        .library(
            name: "Statistics",
            targets: ["Statistics"]),
    ],
    targets: [
        .executableTarget(
            name: "TTest",
            dependencies: [
                .target(name: "Statistics")
            ]
        ),
        .target(
            name: "Statistics",
            dependencies: []
        ),
        .testTarget(
            name: "Test",
            dependencies: ["Statistics"]),
    ]
)