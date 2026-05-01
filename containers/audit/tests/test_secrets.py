from addons.secrets import scan_text, mask_preview


def test_detects_github_pat():
    matches = scan_text("token=ghp_1234567890abcdefghij1234567890ABCDEF12")
    assert any(m["rule"] == "github_pat" for m in matches)


def test_detects_aws_access_key():
    matches = scan_text("AKIAIOSFODNN7EXAMPLE in body")
    assert any(m["rule"] == "aws_access_key" for m in matches)


def test_detects_openai_key():
    matches = scan_text("sk-proj-" + "a" * 40)
    assert any(m["rule"] == "openai_key" for m in matches)


def test_detects_pem_private_key():
    body = "-----BEGIN RSA PRIVATE KEY-----\nMIIE..."
    matches = scan_text(body)
    assert any(m["rule"] == "pem_private_key" for m in matches)


def test_no_false_positive_on_plain_text():
    matches = scan_text("Hello world, this is a normal message.")
    assert matches == []


def test_github_pat_short_does_not_match():
    assert scan_text("ghp_short") == []


def test_github_pat_no_word_boundary_does_not_match():
    long = "x" * 36
    assert scan_text(f"prefixghp_{long}") == []


def test_mask_preview_shows_first_and_last_4():
    assert mask_preview("ghp_1234567890abcdefghij1234567890ABCDEF12") == "ghp_****EF12"


def test_mask_preview_short_secret_fully_masked():
    assert mask_preview("short") == "****"
