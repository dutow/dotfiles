"""JSONL request summary logger for mitmproxy."""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from mitmproxy import http  # type: ignore[import-not-found]


def build_summary(
    method: str,
    host: str,
    path: str,
    status: Optional[int],
    req_bytes: int,
    resp_bytes: int,
    dur_ms: int,
) -> dict:
    return {
        "ts": datetime.now(timezone.utc).isoformat(),
        "method": method,
        "host": host,
        "path": path,
        "status": status,
        "req_bytes": req_bytes,
        "resp_bytes": resp_bytes,
        "dur_ms": dur_ms,
    }


class FlowLoggerAddon:
    def __init__(self, log_path: Path) -> None:
        self.log_path = log_path
        self.log_path.parent.mkdir(parents=True, exist_ok=True)

    def response(self, flow: http.HTTPFlow) -> None:
        req = flow.request
        resp = flow.response
        req_bytes = len(req.raw_content or b"")
        resp_bytes = len(resp.raw_content or b"") if resp else 0
        if resp and resp.timestamp_end is not None and req.timestamp_start is not None:
            dur_ms = int((resp.timestamp_end - req.timestamp_start) * 1000)
        else:
            dur_ms = 0
        summary = build_summary(
            method=req.method,
            host=req.pretty_host,
            path=req.path,
            status=resp.status_code if resp else None,
            req_bytes=req_bytes,
            resp_bytes=resp_bytes,
            dur_ms=dur_ms,
        )
        with self.log_path.open("a") as f:
            f.write(json.dumps(summary) + "\n")
