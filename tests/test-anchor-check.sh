#!/usr/bin/env bash
# test-anchor-check.sh, standalone offline suite. Builds throwaway repos with
# known files and asserts every grounding outcome. bash + git + coreutils only.
#   bash tests/test-anchor-check.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC="$HERE/../src/anchor-check.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/anchorci.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok    $*"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $*"; }
check() { if [ "$2" = "$3" ]; then ok "$1 (rc=$2)"; else bad "$1 (got rc=$2, want $3)"; fi; }

ROOT="$WORK/repo"; mkdir -p "$ROOT/sub"
printf 'l1\nl2\nl3\nl4\nl5\n' > "$ROOT/sub/real.ts"   # exactly 5 lines

echo "== 1. a doc whose cites all ground -> exit 0 (exact path + find fallback) =="
p="$WORK/good.md"; printf 'cites sub/real.ts:2 and a range real.ts:4-5, both ground\n' > "$p"
bash "$AC" "$p" "$ROOT" >/dev/null 2>&1; check "good doc" "$?" "0"

echo "== 2. fabricated file + past-EOF line -> exit 1, both named =="
p="$WORK/bad.md"; printf 'cites ghost.ts:12 (fabricated) and sub/real.ts:99 (past EOF)\n' > "$p"
out=$(bash "$AC" "$p" "$ROOT" 2>&1); rc=$?
{ [ "$rc" = 1 ] && grep -q 'FAIL ghost.ts:12' <<<"$out" && grep -q 'FAIL sub/real.ts:99' <<<"$out"; } \
  && ok "missing file AND past-EOF both flagged, exit 1" || bad "bad doc (rc=$rc): $out"

echo "== 3. a line exactly at EOF grounds (boundary) =="
p="$WORK/eof.md"; printf 'sub/real.ts:5 is the last line\n' > "$p"
bash "$AC" "$p" "$ROOT" >/dev/null 2>&1; check "line == EOF grounds" "$?" "0"

echo "== 4. no cites -> exit 0 (nothing to check) =="
p="$WORK/none.md"; printf 'prose only, a bare mention of real.ts, no line cites\n' > "$p"
out=$(bash "$AC" "$p" "$ROOT" 2>&1); rc=$?
{ [ "$rc" = 0 ] && grep -q 'nothing to check' <<<"$out"; } \
  && ok "no cites: exit 0, says nothing to check" || bad "no cites (rc=$rc)"

echo "== 5. resolves a bare filename via git ls-files in a git repo =="
G="$WORK/gitrepo"; mkdir -p "$G/lib"; git init -q "$G"
printf 'a\nb\nc\n' > "$G/lib/mod.ts"
git -C "$G" -c user.name=t -c user.email=t@e.x add -A
git -C "$G" -c user.name=t -c user.email=t@e.x commit -qm init
p="$WORK/git.md"; printf 'cite mod.ts:2 grounds via ls-files; ghost.ts:1 does not\n' > "$p"
out=$(bash "$AC" "$p" "$G" 2>&1); rc=$?
{ [ "$rc" = 1 ] && grep -q 'ok   mod.ts:2' <<<"$out" && grep -q 'FAIL ghost.ts:1' <<<"$out"; } \
  && ok "git repo: bare cite grounds via ls-files, ghost fails" || bad "git repo (rc=$rc): $out"

echo "== 6. usage / bad inputs -> exit 64 =="
bash "$AC" >/dev/null 2>&1; check "no args" "$?" "64"
bash "$AC" "$WORK/nope.md" "$ROOT" >/dev/null 2>&1; check "doc not found" "$?" "64"
bash "$AC" "$WORK/good.md" "$WORK/noroot" >/dev/null 2>&1; check "repo root not found" "$?" "64"

echo "test-anchor-check: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
