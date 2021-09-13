// swift-tools-version:5.4
import PackageDescription

let package = Package (
    name: "TTest",
    products: [
        .executable(
            name: "t-test",
            targets: ["TTest"]
        ),
        .library(
            name: "Statistics",
            targets: ["Statistics"]
        ),
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
            dependencies: ["Statistics"]
        ),
    ]
)