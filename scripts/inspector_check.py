#!/usr/bin/env python3
"""Exercise the server with a pinned modern MCP Inspector CLI.

This is a protocol integration check. It never claims to validate Logic Pro.
"""
import json
from pathlib import Path
import subprocess
import sys
import tempfile


binary = Path(sys.argv[1] if len(sys.argv) > 1 else ".build/debug/logic-pro-11-mcp").resolve()
if not binary.is_file():
    raise SystemExit(f"Binaire absent : {binary}")

with tempfile.TemporaryDirectory(prefix="logic-mcp-inspector-") as temporary:
    config = Path(temporary) / "servers.json"
    config.write_text(json.dumps({"mcpServers": {
        "modern": {"command": str(binary), "args": [], "protocolEra": "modern"},
        "legacy": {"command": str(binary), "args": [], "protocolEra": "legacy"},
    }}), encoding="utf-8")

    def call(era, method, *extra):
        command = ["npx", "--yes", "@modelcontextprotocol/inspector@2.7.0",
                   "--cli", "--config", str(config), "--server", era,
                   "--method", method, *extra, "--format", "json"]
        completed = subprocess.run(command, capture_output=True, text=True, timeout=90)
        if completed.returncode:
            raise AssertionError(f"Inspector {method}: {completed.stderr.strip()}")
        return json.loads(completed.stdout)["result"]

    discovered = call("modern", "initialize")
    assert discovered["protocolVersion"] == "2026-07-28", discovered
    assert "tools" in discovered["capabilities"], discovered

    listed = call("modern", "tools/list")
    assert [tool["name"] for tool in listed["tools"]] == [
        "logic_status", "logic_diagnostic", "midi_create_pattern", "midi_inspect_export"
    ], listed

    called = call("modern", "tools/call", "--tool-name", "logic_status", "--tool-args-json", "{}")
    assert called["structuredContent"]["verification"] == "unqualified_without_logic_pilots", called
    assert called["structuredContent"]["outcome"] in {"confirmed", "uncertain", "refused"}, called

    old = call("legacy", "initialize")
    assert old["protocolVersion"] == "2025-11-25", old
    old_list = call("legacy", "tools/list")
    assert [tool["name"] for tool in old_list["tools"]] == [
        "logic_status", "logic_diagnostic", "midi_create_pattern", "midi_inspect_export"
    ], old_list
    old_call = call("legacy", "tools/call", "--tool-name", "logic_status", "--tool-args-json", "{}")
    assert old_call["structuredContent"]["mcpProtocolVersion"] == "2025-11-25", old_call

print("Inspector 2.7.0 : découverte, liste et appel validés en modes moderne et ancien ; Logic non testé.")
