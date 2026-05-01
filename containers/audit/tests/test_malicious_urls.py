from pathlib import Path
from addons.malicious_urls import load_blocklist, is_blocked


def test_load_blocklist_strips_comments_and_ips(tmp_path):
    bl = load_blocklist(Path(__file__).parent / "fixtures" / "blocklist.txt")
    assert "evil.example.com" in bl
    assert "phishing.test" in bl
    assert "malware.example" in bl
    assert "#" not in bl
    assert "0.0.0.0" not in bl


def test_is_blocked_exact_match():
    bl = {"evil.example.com"}
    assert is_blocked("evil.example.com", bl) is True


def test_is_blocked_subdomain_match():
    bl = {"evil.example.com"}
    assert is_blocked("api.evil.example.com", bl) is True


def test_is_blocked_clean():
    bl = {"evil.example.com"}
    assert is_blocked("github.com", bl) is False


def test_is_blocked_does_not_match_tld_only():
    bl = {"com"}
    assert is_blocked("github.com", bl) is False
    assert is_blocked("evil.com", bl) is False
