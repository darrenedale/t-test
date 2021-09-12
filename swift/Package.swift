// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "TTest",
    // platforms: [
    //     .macOS(.v10_15),
    //     .macOS(.v10_15),
    //     .macOS(.v10_15),
    //     .macOS(.v10_15),
    // ],
    products: [
        .executable(name: "t-test", targets: ["TTest"]),
    ],
    targets: [
        .executableTarget(name: "TTest", sources: ["main.swift", "TTest.swift", "DataFile.swift"]),
    ]
)