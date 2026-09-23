import Foundation
import CoreFoundation

/// Compatibility with handshake-era MCP 2025-11-25 on the same stdio process.
/// Modern 2026-07-28 requests remain independent and are handled by MCPServer.
struct LegacyServer {
    static let protocolVersion = "2025-11-25"
    private(set) var initialized = false
    private(set) var ready = false

    mutating func process(_ value: Any) -> [String: Any]? {
        guard let request = value as? [String: Any],
              request["jsonrpc"] as? String == "2.0",
              let method = request["method"] as? String else {
            return error(id: NSNull(), code: -32600, message: "Invalid Request")
        }
        if method == "notifications/initialized" && request["id"] == nil {
            if initialized { ready = true }
            return nil
        }
        guard let id = request["id"] else { return nil }
        guard id is String || (id is NSNumber && CFGetTypeID(id as CFTypeRef) != CFBooleanGetTypeID()) else {
            return error(id: NSNull(), code: -32600, message: "Invalid Request")
        }
        if method == "initialize" {
            guard !initialized,
                  let params = request["params"] as? [String: Any],
                  params["protocolVersion"] is String,
                  params["capabilities"] is [String: Any],
                  let clientInfo = params["clientInfo"] as? [String: Any],
                  clientInfo["name"] is String,
                  clientInfo["version"] is String else {
                return error(id: id, code: -32602, message: "Invalid initialize parameters")
            }
            initialized = true
            return success(id: id, result: [
                "protocolVersion": Self.protocolVersion,
                "capabilities": ["tools": [:] as [String: Any]],
                "serverInfo": MCPServer.serverInfo,
                "instructions": "Diagnostics et motifs MIDI pour import manuel ; les actions directes dans Logic attendent les pilotes 11.1 et 11.2."
            ])
        }
        guard ready else { return error(id: id, code: -32600, message: "Server not initialized") }
        switch method {
        case "ping":
            return success(id: id, result: [:])
        case "tools/list":
            let params = request["params"] as? [String: Any] ?? [:]
            guard params["cursor"] == nil else { return error(id: id, code: -32602, message: "Invalid cursor") }
            return success(id: id, result: ["tools": MCPServer.tools])
        case "tools/call":
            guard let params = request["params"] as? [String: Any],
                  let name = params["name"] as? String,
                  params["arguments"] == nil || params["arguments"] is [String: Any] else {
                return error(id: id, code: -32602, message: "Invalid tool arguments")
            }
            let arguments = params["arguments"] as? [String: Any] ?? [:]
            guard MCPServer.tools.contains(where: { $0["name"] as? String == name }) else {
                return error(id: id, code: -32602, message: "Unknown tool")
            }
            do {
                var result = try MusicToolRouter.call(name: name, arguments: arguments)
                var details = result["structuredContent"] as? [String: Any] ?? [:]
                details["mcpProtocolVersion"] = Self.protocolVersion
                result["structuredContent"] = details
                return success(id: id, result: result)
            } catch {
                return self.error(id: id, code: -32602, message: String(describing: error))
            }
        default:
            return error(id: id, code: -32601, message: "Method not found")
        }
    }

    private func success(id: Any, result: [String: Any]) -> [String: Any] {
        ["jsonrpc": "2.0", "id": id, "result": result]
    }

    private func error(id: Any, code: Int, message: String) -> [String: Any] {
        ["jsonrpc": "2.0", "id": id, "error": ["code": code, "message": message]]
    }
}
