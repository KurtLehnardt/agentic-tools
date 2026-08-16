#!/usr/bin/env bash
#
# gate-check.sh — the deterministic mechanical gate for the /build pipeline.
#
# Nothing here is a model's account of what happened; every verdict is a real
# command's own exit code, a real git diff, or a real file-content count. The
# judge subagent runs AFTER this and may only ADD blocking issues — it can never
# overturn a mechanical FAIL.
#
# Project-agnostic: every command it runs comes from .claude/build/config.json.
# Requires: bash, git, python3. No jq, no node, no network.
#
# Usage:
#   scripts/gate-check.sh <TASK_ID>       Per-task gate.
#                                         Reads  .claude/build/tasks/<TASK_ID>.json
#                                         Writes .claude/build/gate/<TASK_ID>.json
#
#   scripts/gate-check.sh --integration   Whole-branch gate (also used to capture
#                                         the baseline in Phase 4.5).
#                                         Writes .claude/build/gate/integration.json
#
# Per-task checks:
#   1. validation suite   — every config.validation[].cmd
#   2. binding contracts  — every config.contracts[].cmd
#   3. scope diff         — changed files must live in owned_files + shared_files
#                           (files matching config.scope_ignore are exempt)
#   4. test-tampering     — no existing test deleted, skipped, or weakened
#   5. baseline delta     — a check already red at baseline is reported as
#                           known_failing_at_baseline, NOT this task's regression.
#                           Scope violations and test tampering get no baseline
#                           excuse — there is no baseline for those.
#
# Exit code:
#   0  machine_verdict == PASS
#   1  machine_verdict == FAIL
#   2  usage / configuration error (nothing was judged)
#
set -uo pipefail

MODE=""
TASK_ID=""
case "${1:-}" in
  "")            echo "usage: gate-check.sh <TASK_ID> | --integration" >&2; exit 2 ;;
  --integration) MODE="integration" ;;
  -* )           echo "gate-check.sh: unknown flag '$1'" >&2; exit 2 ;;
  * )            MODE="task"; TASK_ID="$1" ;;
esac

# Resolve the repo root so the script works from any cwd (workers cd into a worktree).
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "gate-check.sh: not inside a git repository" >&2; exit 2; }
cd "$REPO_ROOT"

BUILD_DIR=".claude/build"
CONFIG="$BUILD_DIR/config.json"
[ -f "$CONFIG" ] || { echo "gate-check.sh: missing $CONFIG (run Phase 0 first)" >&2; exit 2; }
if [ "$MODE" = "task" ]; then
  TASK_JSON="$BUILD_DIR/tasks/$TASK_ID.json"
  [ -f "$TASK_JSON" ] || { echo "gate-check.sh: missing task manifest $TASK_JSON" >&2; exit 2; }
fi

# Everything mechanical happens in python3 (subprocess for commands + git, stdlib
# for JSON and glob matching). Bash is only the entry point.
MODE="$MODE" TASK_ID="$TASK_ID" python3 - <<'PY'
import json, os, re, subprocess, sys, time

MODE      = os.environ["MODE"]
TASK_ID   = os.environ["TASK_ID"]
BUILD_DIR = ".claude/build"
GATE_DIR  = os.path.join(BUILD_DIR, "gate")
BASELINE  = os.path.join(BUILD_DIR, "baseline.json")

def load_json(path, default=None):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return default
    except Exception as e:
        print(f"gate-check.sh: cannot parse {path}: {e}", file=sys.stderr)
        sys.exit(2)

config = load_json(os.path.join(BUILD_DIR, "config.json"))
base_ref = config.get("base_ref", "origin/main")
test_globs   = config.get("test_globs", [])
# The pipeline's own control plane is never a task's deliverable code: config,
# task manifests, gate reports, baseline, telemetry, ledger, worktrees. Exempt it
# from the scope diff unconditionally, on top of the project's own scope_ignore.
scope_ignore = config.get("scope_ignore", []) + [".claude/**"]

def sh(cmd):
    """Run a shell command from config; return (exit_code, combined tail)."""
    p = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    out = (p.stdout or "") + (p.stderr or "")
    tail = out.strip().splitlines()[-25:]
    return p.returncode, tail

def git(*args):
    p = subprocess.run(["git", *args], capture_output=True, text=True)
    return p.returncode, p.stdout, p.stderr

# ---- glob matching (supports ** ; anchored to full repo-relative path) --------
def glob_to_re(pat):
    i, n, out = 0, len(pat), ["^"]
    while i < n:
        c = pat[i]
        if c == "*":
            if i + 1 < n and pat[i+1] == "*":
                out.append(".*"); i += 2
                if i < n and pat[i] == "/":
                    i += 1
                continue
            out.append("[^/]*")
        elif c == "?":
            out.append("[^/]")
        else:
            out.append(re.escape(c))
        i += 1
    out.append("$")
    return re.compile("".join(out))

def match_any(path, patterns):
    base = os.path.basename(path)
    for pat in patterns:
        rx = glob_to_re(pat)
        if rx.match(path) or rx.match(base):
            return True
    return False

# ---- 1 & 2: run validation suite and binding contract checks ------------------
def run_checks(items, name_key):
    results = []
    for it in items:
        name = it.get("name") or it.get(name_key) or it.get("cmd")
        rc, tail = sh(it["cmd"])
        results.append({
            "name": name,
            "cmd": it["cmd"],
            "exit": rc,
            "status": "PASS" if rc == 0 else "FAIL",
            "log_tail": tail,
        })
    return results

validation = run_checks(config.get("validation", []), "name")
contracts  = run_checks(config.get("contracts", []),  "artifact")

report = {
    "task_id": TASK_ID or None,
    "mode": MODE,
    "base_ref": base_ref,
    "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
    "validation": validation,
    "contracts": contracts,
}

# =============================================================================
# INTEGRATION MODE — whole-branch snapshot, no scope/tamper, no baseline delta.
# Doubles as the baseline capture in Phase 4.5.
# =============================================================================
if MODE == "integration":
    failed = [c["name"] for c in validation + contracts if c["status"] == "FAIL"]
    report["machine_verdict"] = "PASS" if not failed else "FAIL"
    report["failing_checks"] = failed
    os.makedirs(GATE_DIR, exist_ok=True)
    out_path = os.path.join(GATE_DIR, "integration.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    print(f"gate-check.sh --integration → {report['machine_verdict']}  ({out_path})")
    for c in validation + contracts:
        print(f"  [{c['status']:4}] {c['name']}")
    sys.exit(0 if report["machine_verdict"] == "PASS" else 1)

# =============================================================================
# TASK MODE
# =============================================================================
task = load_json(os.path.join(BUILD_DIR, "tasks", f"{TASK_ID}.json"), {})
owned  = set(task.get("owned_files", []))
shared = set(task.get("shared_files", []))
allowed = owned | shared

# Resolve the point this branch diverged from base, so the diff is *this task's*
# changes, not everything base is behind on.
rc, _, _ = git("rev-parse", "--verify", "--quiet", f"{base_ref}^{{commit}}")
if rc != 0:
    print(f"gate-check.sh: base_ref '{base_ref}' does not resolve — run `git fetch` "
          f"in the worktree", file=sys.stderr)
    sys.exit(2)
rc, mb, _ = git("merge-base", base_ref, "HEAD")
diff_base = mb.strip() if rc == 0 and mb.strip() else base_ref

# ---- 3: scope diff -----------------------------------------------------------
# Committed changes since divergence, plus anything still in the working tree
# (a worker may self-run the gate before its final commit).
changed = set()
for args in (["diff", "--name-only", diff_base, "HEAD"],
             ["diff", "--name-only", "HEAD"],
             ["diff", "--name-only", "--cached"]):
    rc, out, _ = git(*args)
    if rc == 0:
        changed.update(f for f in out.splitlines() if f.strip())
rc, out, _ = git("ls-files", "--others", "--exclude-standard")
if rc == 0:
    changed.update(f for f in out.splitlines() if f.strip())

scope_violations = sorted(
    f for f in changed
    if f not in allowed and not match_any(f, scope_ignore)
)
report["scope"] = {
    "status": "PASS" if not scope_violations else "FAIL",
    "changed": sorted(changed),
    "allowed": sorted(allowed),
    "violations": scope_violations,
}

# ---- 4: test-tampering diff --------------------------------------------------
# Compare every test file that EXISTED at base: deleted, or fewer test cases, or
# more skip markers at HEAD than at base => tampering. New test files are fine.
TEST_CASE_RES = [
    re.compile(r"\bit\s*\("), re.compile(r"\btest\s*\("),
    re.compile(r"\bdef\s+test_"), re.compile(r"\bfunc\s+Test\w*\s*\("),
    re.compile(r"@Test\b"),
]
SKIP_RES = [
    re.compile(r"\.skip\b"), re.compile(r"\.only\b"),
    re.compile(r"\bxit\s*\("), re.compile(r"\bxdescribe\s*\("),
    re.compile(r"@pytest\.mark\.skip"), re.compile(r"@(?:Ignore|Disabled)\b"),
    re.compile(r"\bt\.Skip\s*\("), re.compile(r"#\s*\[ignore\]"),
]
def count(text, regexes):
    return sum(len(rx.findall(text)) for rx in regexes)

rc, base_files_out, _ = git("ls-tree", "-r", "--name-only", base_ref)
base_files = base_files_out.splitlines() if rc == 0 else []
base_test_files = [f for f in base_files if match_any(f, test_globs)]

tamper = []
for f in base_test_files:
    rc, base_content, _ = git("show", f"{base_ref}:{f}")
    if rc != 0:
        continue
    if not os.path.exists(f):
        tamper.append({"file": f, "issue": "test file deleted"})
        continue
    with open(f, encoding="utf-8", errors="replace") as fh:
        head_content = fh.read()
    base_cases, head_cases = count(base_content, TEST_CASE_RES), count(head_content, TEST_CASE_RES)
    if head_cases < base_cases:
        tamper.append({"file": f, "issue": f"test cases removed ({base_cases} → {head_cases})"})
    base_skips, head_skips = count(base_content, SKIP_RES), count(head_content, SKIP_RES)
    if head_skips > base_skips:
        tamper.append({"file": f, "issue": f"skip/only markers added ({base_skips} → {head_skips})"})

report["test_tampering"] = {
    "status": "PASS" if not tamper else "FAIL",
    "findings": tamper,
}

# ---- 5: baseline delta -------------------------------------------------------
baseline = load_json(BASELINE)
baseline_failing = set()
if baseline:
    for c in baseline.get("validation", []) + baseline.get("contracts", []):
        if c.get("status") == "FAIL":
            baseline_failing.add(c.get("name"))

known_failing, regressions = [], []
for c in validation + contracts:
    if c["status"] != "FAIL":
        continue
    if c["name"] in baseline_failing:
        c["classification"] = "known_failing_at_baseline"
        known_failing.append(c["name"])
    else:
        c["classification"] = "regression"
        regressions.append(c["name"])
report["baseline_delta"] = {
    "baseline_present": baseline is not None,
    "known_failing_at_baseline": known_failing,
    "regressions": regressions,
}

# ---- verdict -----------------------------------------------------------------
fail_reasons = []
if regressions:
    fail_reasons.append(f"validation/contract regressions: {', '.join(regressions)}")
if scope_violations:
    fail_reasons.append(f"scope violations: {', '.join(scope_violations)}")
if tamper:
    fail_reasons.append(f"test tampering: {len(tamper)} finding(s)")

report["machine_verdict"] = "PASS" if not fail_reasons else "FAIL"
report["fail_reasons"] = fail_reasons

os.makedirs(GATE_DIR, exist_ok=True)
out_path = os.path.join(GATE_DIR, f"{TASK_ID}.json")
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2)

# Human-readable summary (the worker reads this and fixes what it flags).
print(f"gate-check.sh {TASK_ID} → {report['machine_verdict']}  ({out_path})")
for c in validation + contracts:
    extra = f"  [{c['classification']}]" if c.get("classification") == "known_failing_at_baseline" else ""
    print(f"  [{c['status']:4}] {c['name']}{extra}")
print(f"  [{report['scope']['status']:4}] scope"
      + (f" — {', '.join(scope_violations)}" if scope_violations else ""))
print(f"  [{report['test_tampering']['status']:4}] test-tampering"
      + (f" — {len(tamper)} finding(s)" if tamper else ""))
if fail_reasons:
    print("FAIL:", "; ".join(fail_reasons))

sys.exit(0 if report["machine_verdict"] == "PASS" else 1)
PY
