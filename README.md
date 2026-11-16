# anchor-check

[![tests](https://github.com/justin-rhee/anchor-check/actions/workflows/test.yml/badge.svg)](https://github.com/justin-rhee/anchor-check/actions/workflows/test.yml) [![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) ![shell](https://img.shields.io/badge/shell-bash-blue.svg) ![zero dependencies](https://img.shields.io/badge/dependencies-0-brightgreen.svg)

Checks that every file-and-line reference in an agent's plan points at a file that exists and a line that's really there.

```console
$ anchor-check.sh plan.md ./repo
FAIL paymentGuard.ts:12                                    file not found in repo
ok   src/checkout.ts:3
FAIL src/checkout.ts:99                                    line 99 past EOF (src/checkout.ts)
anchor-check: 3 cites checked, 2 failing
$ echo $?
1
```

Two agent reviewers once approved a plan built around a file that didn't exist, and the agent building from it just wrote the file from scratch to match. Everyone was reading for whether the approach made sense, and checking the files were real was nobody's job. A made-up `src/auth.ts:340` reads like evidence.

## Use it if

- an agent writes plans, specs or design docs that point at real code, and someone reviews them before anyone builds
- a made-up reference could slip past a reviewer checking the idea rather than the files
- you want the check in front of an approval step, which the exit code makes easy

## Install

One shell script, nothing to install:

```sh
git clone https://github.com/justin-rhee/anchor-check
bash anchor-check/src/anchor-check.sh docs/plan.md ./repo
```

Exit 0 means every reference is real, 1 means one points at a missing file or past the end of one (and it names which), and 64 means it was called wrong. Before you trust it, run it on a document with an invented reference and check that it fails and names it.

## How it works

1. it pulls every reference shaped like `src/auth.ts:340` out of the document
2. it finds the file: the exact path first, then a search by filename in a git repo, so `checkout.ts` still resolves three folders deep, then a plain search of the tree
3. it checks the file is long enough to have that line

## What it won't do

- catch a stale reference, since a line number that drifted in a file that still exists passes, so it proves a reference is real, not that it points at the right thing
- look at plain filenames or prose, which it skips on purpose, because guessing which words are filenames makes more noise than it's worth
- stop flagging things like `example.com:8080`, which reads as a file reference to it; a looser rule would also start missing real problems, and the reasoning is in [docs/ADR.md](docs/ADR.md)
- run on Windows yet

## How I tested it

- 8 offline cases: `bash tests/test-anchor-check.sh`
- covers an all-real plan, an invented file, a line past the end, the exact last line, and the filename search finding what the exact path missed
- CI runs them on macOS and Ubuntu

## License

MIT. See [LICENSE](LICENSE). No warranty. Security notes and how to report a problem: [SECURITY.md](SECURITY.md).

<!-- related:start -->
## Related

- [attest-check](https://github.com/justin-rhee/attest-check): rejects a reply that leaves out anything you asked about
- [judgment-check](https://github.com/justin-rhee/judgment-check): has agents commit to a prediction first, then a different agent scores it

Part of a small set of tools I pulled out of my own agent harness. I use them myself and read every issue. More on my [GitHub profile](https://github.com/justin-rhee).
<!-- related:end -->
