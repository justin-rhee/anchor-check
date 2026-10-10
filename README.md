# anchor-check

[![test](https://github.com/justin-rhee/anchor-check/actions/workflows/test.yml/badge.svg)](https://github.com/justin-rhee/anchor-check/actions/workflows/test.yml)

One small shell check for agent plans and specs: **extract every file-and-line reference**, **confirm the file exists and is long enough to have that line**, and **fail with the broken citations named**. About 90 lines of shell, no model involved, nothing to install.

It exists because two agent reviewers once approved a plan built around a file that didn't exist, and the agent that built from it didn't blink either, it just wrote the file from scratch to match. Nobody was careless: everyone was reading for whether the approach made sense, and with agents writing and reviewing in parallel, checking that the files were real was nobody's job. A made-up reference to `src/auth.ts:340` reads like evidence.

## Use it if

- an agent writes plans, specs, or design docs that point at real code, and a person or another agent reviews them before anyone builds
- a made-up file-and-line reference could slip past a reviewer who's checking whether the idea makes sense, not whether the files are actually there
- you want the check in front of an approval step, which the exit code makes easy

## How it works

It reads a document and pulls out every reference that points at a specific file and line, the `src/auth.ts:340` shape. For each one it checks two things: that the file exists, and that the file is long enough to have that line in it. It takes a second or two.

```console
$ anchor-check.sh plan.md ./repo
FAIL paymentGuard.ts:12                                    file not found in repo
ok   src/checkout.ts:3
FAIL src/checkout.ts:99                                    line 99 past EOF (src/checkout.ts)
anchor-check: 3 cites checked, 2 failing
$ echo $?
1
```

Finding the file is the part that needed care: it tries the exact path first, then, in a git repo, searches by filename so a plan that says `checkout.ts` still resolves when the file lives three folders deep, then falls back to a plain search of the tree.

## Install

There's nothing to install. It's one shell script and it uses what's already on your machine. Verify it works before you point it at a real plan: run it against a document with an invented file-and-line reference and confirm it fails and names it.

```sh
git clone https://github.com/justin-rhee/anchor-check
bash src/anchor-check.sh docs/plan.md ./repo
```

```
anchor-check.sh <doc-file> [repo-root]      # repo-root defaults to the current folder
# exit 0  every reference is real
# exit 1  a reference points at a missing file, or past the end of one, and it names which
# exit 64 you called it wrong
```

## Platforms

macOS and Linux today. Windows on the way.

## What it won't do

- catch stale references: if a line number drifted because the file changed but the file is still there, it passes, so it proves a reference is real, not that it still points at the right thing
- look at anything but explicit file-and-line references: plain filenames and ordinary prose are skipped on purpose, because guessing which words are filenames produces more noise than it's worth
- stop flagging things like `example.com:8080`, which reads as a file reference to it; I left that in the open rather than loosening the rule to hide it, since the looser rule would also start missing real problems. The reasoning is in [docs/ADR.md](docs/ADR.md)

## How I tested it

The suite runs offline, no accounts or network:

```sh
bash tests/test-anchor-check.sh
```

8 cases: a plan whose references are all real, an invented file, a line past the end of a real file, the exact-last-line boundary, the filename search finding something the exact path missed, and the ways you can call it wrong.

## License

MIT. See [LICENSE](LICENSE). No warranty. Security notes and how to report a problem: [SECURITY.md](SECURITY.md).

This little tool is one of a handful I pulled out of my own day-to-day agent setup. I use them all myself, so when something breaks I usually notice fast. But if you run into any issues, or anything that looks off, open an issue. I read every one. More tools on my [GitHub profile](https://github.com/justin-rhee).
