"""DNS-blocklist URL filter for mitmproxy."""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from mitmproxy import http  # type: ignore[import-not-found]


def load_blocklist(path: Path) -> set[str]:
    hosts: set[str] = set()
    for raw in path.read_text().splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        parts = line.split()
        candidates = parts[1:] if len(parts) > 1 else parts
        for c in candidates:
            c = c.strip().lower()
            if c and c not in {"localhost", "0.0.0.0", "127.0.0.1", "::1"}:
                hosts.add(c)
    return hosts


def is_blocked(host: str, blocklist: set[str]) -> bool:
    host = host.lower()
    if host in blocklist:
        return True
    parts = host.split(".")
    # Skip i=0 (full host, handled by exact-match above) and i=len(parts)-1
    # (just the TLD — would catastrophically match every .com host if "com"
    # appeared on the blocklist).
    for i in range(1, len(parts) - 1):
        if ".".join(parts[i:]) in blocklist:
            return True
    return False


class MaliciousUrlsAddon:
    def __init__(self, blocklist_path: Path, log_path: Path) -> None:
        self.blocklist = load_blocklist(blocklist_path) if blocklist_path.exists() else set()
        self.log_path = log_path
        self.log_path.parent.mkdir(parents=True, exist_ok=True)

    def http_connect(self, flow: http.HTTPFlow) -> None:
        host = flow.request.pretty_host
        if is_blocked(host, self.blocklist):
            entry = {
                "ts": datetime.now(timezone.utc).isoformat(),
                "host": host,
                "reason": "blocklist",
                "client_ip": flow.client_conn.peername[0] if flow.client_conn.peername else None,
            }
            with self.log_path.open("a") as f:
                f.write(json.dumps(entry) + "\n")
            flow.response = http.Response.make(502, b"Blocked by dcont egress audit", {"Content-Type": "text/plain"})
