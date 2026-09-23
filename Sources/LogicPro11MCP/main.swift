import Foundation

func subscriptionKey(_ id: Any) -> String {
    if let text = id as? String { return "string:\(text)" }
    if let number = id as? NSNumber { return "number:\(number.stringValue)" }
    return "invalid"
}

func emit(_ message: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: message, options: [.fragmentsAllowed]) else { return }
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data([0x0a]))
}

if CommandLine.arguments.contains("--version") {
    print("logic-pro-11-mcp 0.1.0-preview · MCP 2026-07-28")
} else if CommandLine.arguments.contains("--diagnose") {
    let result = LogicProbe.inspect().dictionary
    if let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]),
       let text = String(data: data, encoding: .utf8) { print(text) }
} else {
    var subscriptions: [String: Any] = [:]
    while let line = readLine() {
        guard let data = line.data(using: .utf8) else { continue }
        let input: Any
        do { input = try JSONSerialization.jsonObject(with: data) }
        catch {
            let reply: [String: Any] = ["jsonrpc": "2.0", "id": NSNull(),
                                        "error": ["code": -32700, "message": "Parse error"]]
            emit(reply)
            continue
        }
        if let request = input as? [String: Any],
           request["method"] as? String == "notifications/cancelled",
           let params = request["params"] as? [String: Any],
           let cancelledID = params["requestId"] {
            subscriptions.removeValue(forKey: subscriptionKey(cancelledID))
            continue
        }
        guard let reply = MCPServer.process(input) else { continue }
        if let request = input as? [String: Any],
           request["method"] as? String == "subscriptions/listen",
           reply["method"] as? String == "notifications/subscriptions/acknowledged",
           let id = request["id"] {
            subscriptions[subscriptionKey(id)] = id
        }
        emit(reply)
    }
    for id in subscriptions.values {
        let response: [String: Any] = ["jsonrpc": "2.0", "id": id,
                                       "result": ["resultType": "complete",
                                                  "_meta": ["io.modelcontextprotocol/subscriptionId": id,
                                                            "io.modelcontextprotocol/serverInfo": MCPServer.serverInfo]]]
        emit(response)
    }
}
