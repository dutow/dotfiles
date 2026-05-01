#!/usr/bin/env bash
# dcont egress audit smoke test.
#
# Prerequisites (run on host):
#   - dcont-host role applied: ./install.sh --tags dcont-host
#   - At least one container image built: ./dcont build --tag audit-test
#
# Usage:
#   bash containers/audit/smoke-test.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DCONT="$DOTFILES_DIR/dcont"
TAG="audit-test"
CTX="audit-smoke"

pass=0
fail=0

ok()   { echo "  [PASS] $*"; pass=$((pass+1)); }
nope() { echo "  [FAIL] $*"; fail=$((fail+1)); }

step() { echo; echo "==> $*"; }

# ---------- prerequisites ----------
step "Checking prerequisites"
command -v mitmdump >/dev/null 2>&1 && ok "mitmdump on PATH" || nope "mitmdump missing — run ./install.sh --tags dcont-host"
[ -L "$HOME/.local/bin/dcont-mitmproxy" ] && ok "dcont-mitmproxy symlink present" || nope "dcont-mitmproxy missing"
[ -f "$HOME/.mitmproxy/mitmproxy-ca-cert.pem" ] && ok "mitmproxy CA seeded" || nope "mitmproxy CA missing — run mitmdump --version once"
command -v podman >/dev/null 2>&1 || command -v docker >/dev/null 2>&1 && ok "container runtime present" || nope "neither podman nor docker found"

if [ $fail -gt 0 ]; then
    echo
    echo "Prerequisites failed; aborting."
    exit 1
fi

# ---------- build ----------
step "Building test image ($TAG)"
if "$DCONT" build --tag "$TAG" >/tmp/dcont-audit-build.log 2>&1; then
    ok "image build succeeded"
    grep -q "Staged mitmproxy CA for image build" /tmp/dcont-audit-build.log && ok "CA was staged" || nope "CA staging line missing from build log (see /tmp/dcont-audit-build.log)"
else
    nope "image build failed (see /tmp/dcont-audit-build.log)"
    exit 1
fi

# ---------- strict run with HTTPS ----------
step "Running container with --audit=strict and exercising egress"
in_container_script=$(cat <<'INNER'
set -e
echo "--- HTTPS via proxy (expect 200) ---"
code=$(curl -s -o /dev/null -w "%{http_code}" https://example.com)
echo "https code=$code"
[ "$code" = "200" ] || { echo "BAD: expected 200, got $code"; exit 11; }

echo "--- raw TCP to 1.1.1.1:53 (expect blocked) ---"
if timeout 2 bash -c 'cat < /dev/tcp/1.1.1.1/53'; then
    echo "BAD: raw TCP succeeded"
    exit 12
else
    echo "OK: raw TCP blocked"
fi
INNER
)

if "$DCONT" run --tag "$TAG" --context "$CTX" --audit=strict --shell /bin/bash -- -c "$in_container_script" > /tmp/dcont-audit-run.log 2>&1; then
    ok "strict-mode container completed without errors"
else
    rc=$?
    nope "strict-mode container exited $rc (see /tmp/dcont-audit-run.log)"
fi

# ---------- log verification ----------
step "Verifying audit logs"
log_dir="$HOME/.aicont-logs/$CTX/latest"
[ -L "$HOME/.aicont-logs/$CTX/latest" ] && ok "latest symlink exists" || nope "latest symlink missing"
[ -f "$log_dir/flows.mitm" ] && ok "flows.mitm present" || nope "flows.mitm missing"
[ -f "$log_dir/summary.jsonl" ] && ok "summary.jsonl present" || nope "summary.jsonl missing"
[ -f "$log_dir/proxy.log" ] && ok "proxy.log present" || nope "proxy.log missing"

if [ -f "$log_dir/summary.jsonl" ]; then
    if grep -q '"host": *"example.com"' "$log_dir/summary.jsonl"; then
        ok "summary.jsonl has example.com entry"
    else
        nope "summary.jsonl missing example.com entry"
    fi
fi

# ---------- tampering protection ----------
step "Verifying agent cannot see audit logs"
tamper_out=$("$DCONT" run --tag "$TAG" --context "$CTX" --audit=off --shell /bin/bash -- -c 'ls ~/.aicont-logs 2>&1 || echo "NOT_VISIBLE: $?"' 2>&1 || true)
if echo "$tamper_out" | grep -q "NOT_VISIBLE\|No such file"; then
    ok "audit log dir not visible inside container"
else
    nope "audit log dir VISIBLE inside container (output: $tamper_out)"
fi

# ---------- summary ----------
echo
echo "=========================================="
echo "  Smoke test result: $pass pass, $fail fail"
echo "=========================================="
[ $fail -eq 0 ]
