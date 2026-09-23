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
    config.write_text(json.dumps({"mcpServers": {"logic": {
        "command": str(binary), "args": [], "protocolEra": "modern"
    }}}), encoding="utf-8")

    def call(method, *extra):
        command = ["npx", "--yes", "@modelcontextprotocol/inspector@2.7.0",
                   "--cli", "--config", str(config), "--server", "logic",
                   "--method", method, *extra, "--format", "json"]
        completed = subprocess.run(command, capture_output=True, text=True, timeout=90)
        if completed.returncode:
            raise AssertionError(f"Inspector {method}: {completed.stderr.strip()}")
        return json.loads(completed.stdout)["result"]

    discovered = call("initialize")
    assert discovered["protocolVersion"] == "2026-07-28", discovered
    assert "tools" in discovered["capabilities"], discovered

    listed = call("tools/list")
    assert [tool["name"] for tool in listed["tools"]] == [
        "logic_status", "logic_diagnostic"
    ], listed

    called = call("tools/call", "--tool-name", "logic_status", "--tool-args-json", "{}")
    assert called["structuredContent"]["verification"] == "unqualified_without_logic_pilots", called
    assert called["structuredContent"]["outcome"] in {"confirmed", "uncertain", "refused"}, called

print("Inspector moderne 2.7.0 : découverte, liste et appel validés ; Logic non testé.")
