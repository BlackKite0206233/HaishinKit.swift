// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "HaishinKit",
    products: [
        .library(name: "HaishinKit", targets: ["HaishinKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/shogo4405/Logboard.git", from: "2.1.2"),
        .package(url: "https://github.com/socketio/socket.io-client-swift", .upToNextMinor(from: "15.0.0"))
    ],
    targets: [
        .target(name: "SwiftPMSupport"),
        .target(name: "HaishinKit", dependencies: ["Logboard", "SwiftPMSupport", "SocketIO"],
                path: "Sources",
                sources: [
                    "Codec",
                    "Extension",
                    "FLV",
                    "ISO",
                    "Media",
                    "Net",
                    "Util",
                    "RTMP",
                    "HTTP",
                    "Platforms"
                ])
    ]
)
