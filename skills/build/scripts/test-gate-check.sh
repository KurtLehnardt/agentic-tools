#!/usr/bin/env bash
#
# test-gate-check.sh — regression test for gate-check.sh and binary test fixtures.
#
# Builds a throwaway git repo whose base commit already holds a binary PNG and a
# non-UTF-8 text file under tests/, with config.test_globs = ["tests/**"], then
# runs gate-check.sh in three scenarios and asserts exit status and report:
#   1. the task adds more binary fixtures                -> PASS, no crash
#   2. the task deletes a binary fixture                 -> FAIL, "test file deleted"
#   3. the task drops a test case in a text test file    -> FAIL, still detected
#
# Usage: skills/build/scripts/test-gate-check.sh      (exit 0 = all passed)
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
GATE="$HERE/gate-check.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FAILS=0

check() { # check <description> <condition-exit-status>
  if [ "$2" -eq 0 ]; then echo "  ok   - $1"; else echo "  FAIL - $1"; FAILS=$((FAILS+1)); fi
}

make_repo() { # make_repo <dir>
  local d="$1"
  mkdir -p "$d/tests" "$d/src" "$d.state/tasks"
  git -C "$d" init -q -b main
  git -C "$d" config user.email t@example.com
  git -C "$d" config user.name tester
  printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\xff\xfe\x00\x80' > "$d/tests/fixture.png"
  printf '# caf\xe9 \xff\xfe latin-1 bytes\ndef test_a():\n    pass\n' > "$d/tests/legacy_latin1.py"
  printf 'def test_one():\n    pass\n\ndef test_two():\n    pass\n' > "$d/tests/test_text.py"
  echo 'x = 1' > "$d/src/a.py"
  git -C "$d" add -A -- tests src
  git -C "$d" commit -q -m base
  git -C "$d" update-ref refs/remotes/origin/main HEAD
  git -C "$d" checkout -q -b task
  cat > "$d.state/config.json" <<'JSON'
{"base_ref": "origin/main", "test_globs": ["tests/**"], "validation": [], "contracts": []}
JSON
  cat > "$d.state/tasks/T1.json" <<'JSON'
{"owned_files": ["tests/new_fixture.png", "tests/blob.bin", "tests/fixture.png", "tests/test_text.py"], "shared_files": []}
JSON
}

run_gate() { # run_gate <dir>; sets OUT and RC
  OUT="$(cd "$1" && BUILD_STATE_DIR="$1.state" bash "$GATE" T1 2>&1)"
  RC=$?
}

echo "scenario 1: task adds binary fixtures"
R="$WORK/r1"; make_repo "$R"
printf '\x89PNG\r\n\x1a\n\x00\xff\xfe\xfd' > "$R/tests/new_fixture.png"
printf '\x00\x01\x02\xff\xfe' > "$R/tests/blob.bin"
git -C "$R" add -- tests/new_fixture.png tests/blob.bin
git -C "$R" commit -q -m "add fixtures"
run_gate "$R"
check "exit status 0 (got $RC)" "$([ "$RC" -eq 0 ]; echo $?)"
check "no traceback" "$(! grep -q Traceback <<<"$OUT"; echo $?)"
check "test-tampering PASS" "$(grep -q 'PASS.*test-tampering' <<<"$OUT"; echo $?)"
if [ "$RC" -ne 0 ]; then echo "$OUT" | sed 's/^/    | /'; fi

echo "scenario 2: task deletes a binary fixture"
R="$WORK/r2"; make_repo "$R"
git -C "$R" rm -q -- tests/fixture.png
git -C "$R" commit -q -m "drop fixture"
run_gate "$R"
check "exit status 1 (got $RC)" "$([ "$RC" -eq 1 ]; echo $?)"
check "no traceback" "$(! grep -q Traceback <<<"$OUT"; echo $?)"
check "report names deleted fixture" "$(grep -q 'test file deleted' "$R.state/gate/T1.json" 2>/dev/null; echo $?)"

echo "scenario 3: text test loses a case (behaviour unchanged)"
R="$WORK/r3"; make_repo "$R"
printf 'def test_one():\n    pass\n' > "$R/tests/test_text.py"
git -C "$R" add -- tests/test_text.py
git -C "$R" commit -q -m "drop a test"
run_gate "$R"
check "exit status 1 (got $RC)" "$([ "$RC" -eq 1 ]; echo $?)"
check "report names removed cases" "$(grep -q 'test cases removed (2 .u2192 1)' "$R.state/gate/T1.json" 2>/dev/null; echo $?)"

if [ "$FAILS" -eq 0 ]; then echo "all passed"; else echo "$FAILS check(s) failed"; exit 1; fi
