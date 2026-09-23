// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LogicPro11MCP",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "logic-pro-11-mcp", targets: ["LogicPro11MCP"])],
    targets: [
        .executableTarget(name: "LogicPro11MCP"),
        .testTarget(name: "LogicPro11MCPTests", dependencies: ["LogicPro11MCP"])
    ]
)
