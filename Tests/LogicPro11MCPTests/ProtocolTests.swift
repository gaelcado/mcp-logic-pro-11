import XCTest
@testable import LogicPro11MCP

final class ProtocolTests: XCTestCase {
    private func request(_ method: String, id: Int = 1, version: String = "2026-07-28", extra: [String: Any] = [:]) -> [String: Any] {
        var params = extra
        params["_meta"] = ["io.modelcontextprotocol/protocolVersion": version,
                           "io.modelcontextprotocol/clientCapabilities": [:] as [String: Any],
                           "io.modelcontextprotocol/clientInfo": ["name": "test", "version": "1"]]
        return ["jsonrpc": "2.0", "id": id, "method": method, "params": params]
    }

    private func result(_ value: [String: Any]?) -> [String: Any] { value?["result"] as? [String: Any] ?? [:] }
    private func errorCode(_ value: [String: Any]?) -> Int? { (value?["error"] as? [String: Any])?["code"] as? Int }

    func testDiscoverAndListAreModernAndCacheable() {
        let discover = result(MCPServer.process(request("server/discover")))
        XCTAssertEqual(discover["resultType"] as? String, "complete")
        XCTAssertEqual(discover["supportedVersions"] as? [String], ["2026-07-28"])
        XCTAssertNotNil((discover["capabilities"] as? [String: Any])?["tools"])
        XCTAssertEqual(discover["cacheScope"] as? String, "public")
        XCTAssertNotNil(discover["ttlMs"] as? Int)
        XCTAssertNotNil((discover["_meta"] as? [String: Any])?["io.modelcontextprotocol/serverInfo"])

        let listed = result(MCPServer.process(request("tools/list")))
        let names = (listed["tools"] as? [[String: Any]])?.compactMap { $0["name"] as? String }
        XCTAssertEqual(names, ["logic_status", "logic_diagnostic"])
        XCTAssertEqual(listed["resultType"] as? String, "complete")
        XCTAssertEqual(listed["cacheScope"] as? String, "public")
        XCTAssertNotNil(listed["ttlMs"] as? Int)
        XCTAssertEqual(errorCode(MCPServer.process(request("tools/list", extra: ["cursor": "other"]))), -32602)
    }

    func testPerRequestMetadataAndVersion() {
        let malformed: [String: Any] = ["jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": [:]]
        XCTAssertEqual(errorCode(MCPServer.process(malformed)), -32602)
        let versionError = MCPServer.process(request("server/discover", version: "2025-11-25"))
        XCTAssertEqual(errorCode(versionError), -32022)
        let data = (versionError?["error"] as? [String: Any])?["data"] as? [String: Any]
        XCTAssertEqual(data?["supported"] as? [String], ["2026-07-28"])
        XCTAssertEqual(data?["requested"] as? String, "2025-11-25")
    }

    func testToolCallAndRefusalOfUnknownOrArguments() {
        let call = result(MCPServer.process(request("tools/call", extra: ["name": "logic_status", "arguments": [:] as [String: Any]])))
        XCTAssertEqual(call["resultType"] as? String, "complete")
        XCTAssertEqual(call["isError"] as? Bool, false)
        XCTAssertEqual((call["structuredContent"] as? [String: Any])?["verification"] as? String, "unqualified_without_logic_pilots")
        XCTAssertEqual(errorCode(MCPServer.process(request("tools/call", extra: ["name": "logic_play", "arguments": [:] as [String: Any]]))), -32602)
        XCTAssertEqual(errorCode(MCPServer.process(request("tools/call", extra: ["name": "logic_status", "arguments": ["unexpected": true]]))), -32602)
    }

    func testProfileSelectionDoesNotGuess() {
        XCTAssertEqual(LogicVersion("11.1")?.profile, "11.1")
        XCTAssertEqual(LogicVersion("11.2.2")?.profile, "11.2")
        XCTAssertNil(LogicVersion("12.3")?.profile)
        XCTAssertNil(LogicVersion("11.3")?.profile)
        XCTAssertNil(LogicVersion("11.2beta"))
        XCTAssertNil(LogicVersion("11.2.0.1"))
    }

    func testStaticCatalogSubscriptionAcknowledgesNoEvents() {
        let response = MCPServer.process(request("subscriptions/listen", id: 27,
            extra: ["notifications": ["toolsListChanged": true]]))
        XCTAssertEqual(response?["method"] as? String, "notifications/subscriptions/acknowledged")
        let params = response?["params"] as? [String: Any]
        XCTAssertEqual((params?["_meta"] as? [String: Any])?["io.modelcontextprotocol/subscriptionId"] as? Int, 27)
        XCTAssertEqual((params?["notifications"] as? [String: Any])?.count, 0)
    }
}
