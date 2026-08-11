#!/usr/bin/env bash
# anchor-check.sh, deterministic grounding check for file:line citations in a
# plan or design doc.
#
# WHY: a model reviewing a plan certifies its LOGIC but not its CONTACT WITH THE
# CODE. A plan can cite files and line numbers that do not exist, pass every model
# review, and only break at implementation. Observed: a plan cited a source file
# that did not exist, passed two rounds of AI review anyway, and the implementer,
# told to edit that file, created it from scratch to match the plan. This check is
# model-free and runs in O(seconds): it greps a doc for `path.ext:N` citations and
# confirms each one grounds in the repo (the file exists, the line is within EOF).
#
# Usage: anchor-check.sh <doc-file> [repo-root]      (repo-root default: $PWD)
# Exit:  0 every cite grounds · 1 any cite missing/past-EOF · 64 usage error
#
# What counts as a cite (deliberate scope): explicit `path.ext:N` or `path.ext:N-M`
# tokens. Bare filename mentions, prose, and contextual `:N` fragments are ignored.
# Line-number DRIFT within an existing file is NOT detectable here, this catches
# FABRICATION (missing file, line past EOF), not drift; symbols stay authoritative
# over raw line numbers. Known false-positive edge: a bare `host.tld:port` in prose
# parses as a cite, keep ports out of doc prose or expect a flagged line to justify.
set -euo pipefail

[ $# -ge 1 ] || { printf 'usage: anchor-check.sh <doc-file> [repo-root]\n' >&2; exit 64; }
plan="$1"
root="${2:-$PWD}"
[ -f "$plan" ] || { printf 'anchor-check: doc not found: %s\n' "$plan" >&2; exit 64; }
[ -d "$root" ] || { printf 'anchor-check: repo root not found: %s\n' "$root" >&2; exit 64; }

cites="$(grep -oE '[A-Za-z0-9_][A-Za-z0-9_./-]*\.[a-z]{2,4}:[0-9]+(-[0-9]+)?' "$plan" | sort -u || true)"
if [ -z "$cites" ]; then
  printf 'anchor-check: no file:line cites found in %s, nothing to check\n' "$plan"
  exit 0
fi

fails=0
checked=0
while IFS= read -r cite; do
  [ -n "$cite" ] || continue
  checked=$((checked + 1))
  file="${cite%%:*}"
  range="${cite#*:}"
  start="${range%%-*}"

  # Candidate paths: exact path under root first, then suffix search
  # (tracked files when root is a git repo, plain find otherwise).
  cands=""
  if [ -f "$root/$file" ]; then
    cands="$root/$file"
  elif git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
    cands="$(git -C "$root" ls-files -- "*/$file" "$file" 2>/dev/null | sed "s|^|$root/|" | head -5)"
  else
    cands="$(find "$root" -type f -path "*/$file" 2>/dev/null | head -5)"
  fi

  if [ -z "$cands" ]; then
    printf 'FAIL %-58s file not found in repo\n' "$cite"
    fails=$((fails + 1))
    continue
  fi

  ok_path=""
  while IFS= read -r cand; do
    [ -f "$cand" ] || continue
    n="$(wc -l < "$cand" | tr -d ' ')"
    if [ "$start" -le "$n" ]; then
      ok_path="$cand"
      break
    fi
  done <<CANDS
$cands
CANDS

  if [ -n "$ok_path" ]; then
    printf 'ok   %s\n' "$cite"
  else
    printf 'FAIL %-58s line %s past EOF (%s)\n' "$cite" "$start" "$(printf '%s\n' "$cands" | head -1)"
    fails=$((fails + 1))
  fi
done <<CITES
$cites
CITES

printf 'anchor-check: %s cites checked, %s failing\n' "$checked" "$fails"
if [ "$fails" -gt 0 ]; then
  exit 1
fi
exit 0
