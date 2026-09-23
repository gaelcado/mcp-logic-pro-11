#!/usr/bin/env python3
"""Black-box stdio checks for MCP wire behavior; does not exercise Logic Pro."""
import json
import subprocess
import sys


def request(method, request_id, **params):
    params["_meta"] = {
        "io.modelcontextprotocol/protocolVersion": "2026-07-28",
        "io.modelcontextprotocol/clientCapabilities": {},
        "io.modelcontextprotocol/clientInfo": {"name": "smoke-test", "version": "1"},
    }
    return {"jsonrpc": "2.0", "id": request_id, "method": method, "params": params}


binary = sys.argv[1] if len(sys.argv) > 1 else ".build/debug/logic-pro-11-mcp"
messages = [
    request("server/discover", 1),
    request("tools/list", 2),
    request("tools/call", 3, name="logic_status", arguments={}),
    request("subscriptions/listen", 4, notifications={"toolsListChanged": True}),
    {"jsonrpc": "2.0", "method": "notifications/cancelled", "params": {"requestId": 4}},
    request("tools/list", 5),
]
payload = "\n".join(json.dumps(message, separators=(",", ":")) for message in messages) + "\n"
run = subprocess.run([binary], input=payload, capture_output=True, text=True, timeout=10, check=True)
assert not run.stderr, run.stderr
responses = [json.loads(line) for line in run.stdout.splitlines()]
assert len(responses) == 5, responses
assert [r.get("id") for r in responses] == [1, 2, 3, None, 5], responses
assert responses[0]["result"]["supportedVersions"] == ["2026-07-28"]
assert responses[1]["result"]["tools"] == responses[4]["result"]["tools"]
assert responses[2]["result"]["structuredContent"]["verification"] == "unqualified_without_logic_pilots"
assert responses[3]["method"] == "notifications/subscriptions/acknowledged"
assert responses[3]["params"]["_meta"]["io.modelcontextprotocol/subscriptionId"] == 4
assert responses[3]["params"]["notifications"] == {}
print("5 réponses stdio conformes aux scénarios testés ; aucun Logic Pro exercé.")
