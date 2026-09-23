import Foundation
import CoreFoundation

enum MCPServer {
    static let protocolVersion = "2026-07-28"
    static let serverInfo: [String: String] = ["name": "logic-pro-11-mcp", "version": "0.1.0-preview"]
    static let serverMeta: [String: Any] = ["io.modelcontextprotocol/serverInfo": serverInfo]

    static let tools: [[String: Any]] = [
        ["name": "logic_status", "title": "État de Logic Pro",
         "description": "Requiert Logic Pro ouvert pour lire sa version et choisir le profil 11.1 ou 11.2 ; indique aussi l'autorisation Accessibilité. Ne modifie pas le projet.",
         "inputSchema": ["type": "object", "properties": [:], "additionalProperties": false] as [String: Any],
         "annotations": ["readOnlyHint": true]],
        ["name": "logic_diagnostic", "title": "Diagnostic de connexion",
         "description": "Donne un diagnostic court même si Logic est fermé, sans nom de projet, pour préparer un test pilote. Ne modifie pas Logic.",
         "inputSchema": ["type": "object", "properties": [:], "additionalProperties": false] as [String: Any],
         "annotations": ["readOnlyHint": true]]
    ]

    static func process(_ value: Any) -> [String: Any]? {
        guard let request = value as? [String: Any], request["jsonrpc"] as? String == "2.0",
              let method = request["method"] as? String else {
            return error(id: (value as? [String: Any])?["id"] ?? NSNull(), code: -32600, message: "Invalid Request")
        }
        guard let id = request["id"] else { return nil } // JSON-RPC notification
        guard id is String || (id is NSNumber && CFGetTypeID(id as CFTypeRef) != CFBooleanGetTypeID()) else {
            return error(id: NSNull(), code: -32600, message: "Invalid Request")
        }
        guard let params = request["params"] as? [String: Any],
              let meta = params["_meta"] as? [String: Any],
              let version = meta["io.modelcontextprotocol/protocolVersion"] as? String,
              meta["io.modelcontextprotocol/clientCapabilities"] is [String: Any] else {
            return error(id: id, code: -32602, message: "Missing or invalid request _meta")
        }
        guard version == protocolVersion else {
            return error(id: id, code: -32022, message: "Unsupported protocol version",
                         data: ["supported": [protocolVersion], "requested": version])
        }
        switch method {
        case "server/discover":
            return success(id: id, result: ["supportedVersions": [protocolVersion],
                                            "capabilities": ["tools": [:] as [String: Any]],
                                            "instructions": "Deux outils de diagnostic en lecture seule. Les commandes de transport, MIDI et mixage attendent la qualification des pilotes Logic 11.1 et 11.2.",
                                            "ttlMs": 300_000, "cacheScope": "public"])
        case "tools/list":
            guard params["cursor"] == nil else { return error(id: id, code: -32602, message: "Invalid cursor") }
            return success(id: id, result: ["tools": tools, "ttlMs": 300_000, "cacheScope": "public"])
        case "tools/call":
            guard let name = params["name"] as? String,
                  let arguments = params["arguments"] as? [String: Any], arguments.isEmpty else {
                return error(id: id, code: -32602, message: "Invalid tool arguments")
            }
            guard tools.contains(where: { $0["name"] as? String == name }) else {
                return error(id: id, code: -32602, message: "Unknown tool")
            }
            let result = LogicProbe.inspect().dictionary
            let message = name == "logic_diagnostic" ? "Diagnostic établi. Aucune commande musicale n'a été exécutée." : "État de Logic lu. Aucun changement effectué."
            return success(id: id, result: ["content": [["type": "text", "text": message]],
                                            "structuredContent": result, "isError": false])
        case "subscriptions/listen":
            guard params["notifications"] is [String: Any] else {
                return error(id: id, code: -32602, message: "Invalid notification filter")
            }
            // The tool catalog is static, so no change event is advertised or emitted.
            return ["jsonrpc": "2.0", "method": "notifications/subscriptions/acknowledged",
                    "params": ["_meta": ["io.modelcontextprotocol/subscriptionId": id],
                               "notifications": [:] as [String: Any]]]
        default:
            return error(id: id, code: -32601, message: "Method not found")
        }
    }

    private static func success(id: Any, result: [String: Any]) -> [String: Any] {
        var body = result
        body["resultType"] = "complete"
        body["_meta"] = serverMeta
        return ["jsonrpc": "2.0", "id": id, "result": body]
    }

    private static func error(id: Any, code: Int, message: String, data: [String: Any]? = nil) -> [String: Any] {
        var detail: [String: Any] = ["code": code, "message": message]
        if let data { detail["data"] = data }
        return ["jsonrpc": "2.0", "id": id, "error": detail]
    }
}
