import json

from addons.flow_logger import build_summary


def test_summary_contains_expected_fields():
    s = build_summary(
        method="GET",
        host="github.com",
        path="/foo",
        status=200,
        req_bytes=312,
        resp_bytes=48211,
        dur_ms=284,
    )
    assert s["method"] == "GET"
    assert s["host"] == "github.com"
    assert s["path"] == "/foo"
    assert s["status"] == 200
    assert s["req_bytes"] == 312
    assert s["resp_bytes"] == 48211
    assert s["dur_ms"] == 284
    assert "ts" in s


def test_summary_serializes_to_jsonl():
    s = build_summary(method="POST", host="x", path="/", status=500, req_bytes=0, resp_bytes=0, dur_ms=1)
    line = json.dumps(s)
    parsed = json.loads(line)
    assert parsed["status"] == 500


def test_summary_with_none_status():
    s = build_summary(method="GET", host="x", path="/", status=None, req_bytes=0, resp_bytes=0, dur_ms=0)
    assert s["status"] is None
