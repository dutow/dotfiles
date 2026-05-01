"""Regex-based secret scanner for mitmproxy flows."""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

from mitmproxy import http  # type: ignore[import-not-found]

RULES: list[tuple[str, re.Pattern[str]]] = [
    ("github_pat", re.compile(r"\bghp_[A-Za-z0-9]{36,}\b")),
    ("github_oauth", re.compile(r"\bgho_[A-Za-z0-9]{36,}\b")),
    ("aws_access_key", re.compile(r"\b(AKIA|ASIA)[0-9A-Z]{16}\b")),
    ("openai_key", re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}\b")),
    ("anthropic_key", re.compile(r"\bsk-ant-[A-Za-z0-9_-]{40,}\b")),
    ("pem_private_key", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("slack_token", re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}\b")),
]


def scan_text(text: str) -> list[dict]:
    found = []
    for name, pat in RULES:
        for m in pat.finditer(text):
            found.append({"rule": name, "value": m.group(0)})
    return found


def mask_preview(value: str) -> str:
    if len(value) <= 8:
        return "****"
    return f"{value[:4]}****{value[-4:]}"


class SecretsAddon:
    def __init__(self, log_path: Path) -> None:
        self.log_path = log_path
        self.log_path.parent.mkdir(parents=True, exist_ok=True)

    def _scan_and_log(self, flow: http.HTTPFlow, direction: str, text: str) -> None:
        for match in scan_text(text):
            entry = {
                "ts": datetime.now(timezone.utc).isoformat(),
                "host": flow.request.pretty_host,
                "path": flow.request.path,
                "direction": direction,
                "rule": match["rule"],
                "match_preview": mask_preview(match["value"]),
                "flow_id": flow.id,
            }
            with self.log_path.open("a") as f:
                f.write(json.dumps(entry) + "\n")

    def request(self, flow: http.HTTPFlow) -> None:
        try:
            text = flow.request.get_text() or ""
        except (UnicodeDecodeError, ValueError):
            return
        if text:
            self._scan_and_log(flow, "request", text)
        for k, v in flow.request.headers.items():
            self._scan_and_log(flow, "request", f"{k}: {v}")
