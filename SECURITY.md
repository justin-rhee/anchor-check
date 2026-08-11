# Security policy: anchor-check

## Posture

anchor-check is provided as-is, with NO WARRANTY (see LICENSE). It is a
correctness gate for AI-authored plans, not a security control.

The honest ceiling: it proves a citation is *real* (the file exists, the line is
within it), not that it points at the *right* code. A line number that drifted
within an existing file passes; catching that is out of scope by design (see
docs/ADR.md, ADR-002). Do not treat a green anchor-check as proof that a plan's
citations are semantically correct, only that they aren't fabricated.

It reads the doc and repo files you point it at and executes nothing from them.

## Validation status

The standalone suite `tests/test-anchor-check.sh` runs offline (bash + git +
coreutils, no network, no keys) and passes 8/8, covering grounded cites,
fabricated files, past-EOF lines, the exact-EOF boundary, git `ls-files`
resolution, and usage errors. Run it before relying on the tool:

    bash tests/test-anchor-check.sh

## Reporting a vulnerability

Please report suspected vulnerabilities privately through this repository's
**Security → Report a vulnerability** tab (GitHub private vulnerability
reporting). Do not open a public issue for a suspected vulnerability, this keeps
the report private until a fix is available.
