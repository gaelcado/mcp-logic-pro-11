#!/usr/bin/env python3
"""Black-box stdio checks for MCP wire behavior; does not exercise Logic Pro."""
import json
import os
import subprocess
import sys
import tempfile


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
with tempfile.TemporaryDirectory(prefix="logic-mcp-midi-") as temporary:
    environment = dict(os.environ, LOGIC_MCP_EXPORT_DIR=temporary)
    run = subprocess.run([binary], input=payload, capture_output=True, text=True,
                         timeout=10, check=True, env=environment)
    assert not run.stderr, run.stderr
    responses = [json.loads(line) for line in run.stdout.splitlines()]
    assert len(responses) == 5, responses
    assert [r.get("id") for r in responses] == [1, 2, 3, None, 5], responses
    assert responses[0]["result"]["supportedVersions"] == ["2026-07-28", "2025-11-25"]
    assert responses[1]["result"]["tools"] == responses[4]["result"]["tools"]
    assert responses[2]["result"]["structuredContent"]["verification"] == "unqualified_without_logic_pilots"
    assert responses[3]["method"] == "notifications/subscriptions/acknowledged"
    assert responses[3]["params"]["_meta"]["io.modelcontextprotocol/subscriptionId"] == 4
    assert responses[3]["params"]["notifications"] == {}

    create = request("tools/call", 6, name="midi_create_pattern", arguments={
        "name": "Test pilote", "tempoBPM": 120, "beatsPerBar": 4,
        "tracks": [{"name": "Piano", "notes": [
            {"pitch": 60, "startBeat": 0, "durationBeats": 1},
            {"pitch": 64, "startBeat": 1, "durationBeats": 1}]},
            {"name": "Basse", "notes": [{"pitch": 36, "startBeat": 0, "durationBeats": 2}]}]
    })
    created = subprocess.run([binary], input=json.dumps(create) + "\n", capture_output=True,
                             text=True, timeout=10, check=True, env=environment)
    assert not created.stderr, created.stderr
    file = json.loads(created.stdout)["result"]["structuredContent"]
    assert file["fileConfirmed"] and file["totalNotes"] == 3 and file["trackCount"] == 3, file
    assert file["beatsPerBar"] == 4 and file["tempoBPM"] == 120, file

    inspect = request("tools/call", 7, name="midi_inspect_export",
                      arguments={"fileName": file["fileName"]})
    checked = subprocess.run([binary], input=json.dumps(inspect) + "\n", capture_output=True,
                             text=True, timeout=10, check=True, env=environment)
    assert not checked.stderr, checked.stderr
    reread = json.loads(checked.stdout)["result"]["structuredContent"]
    assert reread["sha256"] == file["sha256"] and reread["totalNotes"] == 3, reread

print("MCP stdio et création/relecture MIDI vérifiés ; aucun Logic Pro exercé.")
