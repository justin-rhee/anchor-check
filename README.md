# anchor-check

[![test](https://github.com/justin-rhee/anchor-check/actions/workflows/test.yml/badge.svg)](https://github.com/justin-rhee/anchor-check/actions/workflows/test.yml)

Two agent reviewers approved a plan built around a file that didn't exist. The agent that built from it didn't blink either, it just wrote the file from scratch to match

Nobody was careless. Everyone was reading for whether the approach made sense, and with agents writing and reviewing in parallel, checking that the files were real was nobody's job. A made-up reference to `src/auth.ts:340` reads like evidence.

So this is that check, about 90 lines of shell that reads a plan and makes sure every file and line it points at is really there.

## Use it if

You've got an agent writing plans, specs, or design docs that point at real code, and someone reviews them before anyone builds, whether that reviewer is a person or another agent. Anywhere a made-up file-and-line reference can slip past a reviewer who's checking whether the idea makes sense, not whether the files are actually there.

## How it works

It reads a document and pulls out every reference that points at a specific file and line, the `src/auth.ts:340` shape. For each one it checks two things: that the file exists, and that the file is long enough to have that line in it.

No model involved, and it takes a second or two.

```console
$ anchor-check.sh plan.md ./repo
FAIL paymentGuard.ts:12                                    file not found in repo
ok   src/checkout.ts:3
FAIL src/checkout.ts:99                                    line 99 past EOF (src/checkout.ts)
anchor-check: 3 cites checked, 2 failing
$ echo $?
1
```

Finding the file is the part that needed care. It tries the exact path first. If that misses and you're in a git repo, it searches by filename, so a plan that says `checkout.ts` still resolves when the file lives three folders deep. Failing that it falls back to a plain search of the tree.

## Install

There's nothing to install. It's one shell script and it uses what's already on your machine.

```
anchor-check.sh <doc-file> [repo-root]      # repo-root defaults to the current folder
# exit 0  every reference is real
# exit 1  a reference points at a missing file, or past the end of one, and it names which
# exit 64 you called it wrong
```

Use it wherever an agent writes a plan that someone reviews before anyone builds from it, whether that reviewer is a person or another agent. The exit code makes it easy to put in front of an approval step.

## What it won't do

It catches invented references, not stale ones. If a line number drifted because the file changed but the file is still there, it passes. It proves a reference is real, not that it still points at the right thing.

It only looks at explicit file-and-line references. Plain filenames and ordinary prose are skipped on purpose, because guessing which words are filenames produces more noise than it's worth.

Something like `example.com:8080` in your text reads as a file reference to it, and gets flagged. I left that in the open rather than loosening the rule to hide it, since the looser rule would also start missing real problems. The reasoning is in [docs/ADR.md](docs/ADR.md).

## How I tested it

The suite runs offline, no accounts or network:

```
bash tests/test-anchor-check.sh
```

8 cases: a plan whose references are all real, an invented file, a line past the end of a real file, the exact-last-line boundary, the filename search finding something the exact path missed, and the ways you can call it wrong.

## License

MIT. See [LICENSE](LICENSE). No warranty. Security notes and how to report a problem: [SECURITY.md](SECURITY.md).

---

This little tool is one of a handful I pulled out of my own day-to-day agent setup. I use them all myself, so when something breaks I usually notice fast. But if you run into any issues, or anything that looks off, open an issue. I read every one. More tools on my [GitHub profile](https://github.com/justin-rhee).
