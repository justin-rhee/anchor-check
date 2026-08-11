# anchor-check

An AI agent will build from a plan that points to code that doesn't exist. That's what mine did: the plan named a file that wasn't there, so the agent created it from scratch to match, and two rounds of AI review had already signed off, because they were judging whether the plan sounded right, not whether it matched the real code.

anchor-check is the cheap check that would have caught it. It reads a plan (or any document) and finds every place that points to a specific file and line, like `src/auth.ts:340`, then makes sure each one is real: the file exists, and that line is actually in it. It doesn't use a model, it runs in a second or two, and it's about 90 lines of bash.

```console
$ anchor-check.sh plan.md ./repo
FAIL paymentGuard.ts:12                                    file not found in repo
ok   src/checkout.ts:3
FAIL src/checkout.ts:99                                    line 99 past EOF (src/checkout.ts)
anchor-check: 3 cites checked, 2 failing
$ echo $?
1
```

## Use it if

You've got an agent writing plans, specs, or design docs that point at real code, and someone reviews them before anyone builds, whether that reviewer is a person or another agent. Anywhere a made-up file-and-line reference can slip past a reviewer who's checking whether the idea makes sense, not whether the files are actually there.

```
anchor-check.sh <doc-file> [repo-root]      # repo-root defaults to $PWD
# exit 0  every reference is real
# exit 1  a reference points at a missing file or a line past the end (it names which)
# exit 64 you called it wrong
```

It looks for each file three ways: the exact path first, then a search by filename if you're in a git repo, then a plain file search. The tests have a worked example of each.

## What it won't do

- It catches made-up references, not stale ones. If a line number just shifted because the file changed but the file still exists, it passes. It proves the reference is real, not that it still points at the right thing.
- It only checks explicit file-and-line references like `path.ext:12`. Plain filenames and prose are skipped on purpose.
- One thing it gets wrong: something like `example.com:8080` in your text looks like a file reference to it. Keep those out of your prose, or expect to wave off a flagged line. I left it in the open rather than loosening the rule to hide it. The reasoning is in [docs/ADR.md](docs/ADR.md).

## How I tested it

You can run the test suite offline:

```
bash tests/test-anchor-check.sh    # 8 checks
```

It covers a plan with real references, a made-up file, a line past the end of a file, the exact-last-line edge case, the filename search, and the ways you can call it wrong.

## License

MIT. See [LICENSE](LICENSE). No warranty. Security notes and how to report a problem: [SECURITY.md](SECURITY.md).

---

One of a set of small tools I've pulled out of a bigger system I run, where agents write the code and plain scripts decide when it's actually done. They all share one rule: the machine suggests, a person decides, and nothing quietly goes wrong behind your back. More of them on my [GitHub profile](https://github.com/justin-rhee).
