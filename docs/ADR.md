# Architecture Decision Records (ADRs)

Short notes on the design decisions behind this tool, one per real problem I hit.
The tests enforce these; this is the reasoning.

## 1. Check that the plan touches the real code, not just that it reads well

In a plan-then-build setup, an agent wrote a plan, other agents reviewed it, and a
cheap agent built whatever got approved. One plan pointed to a source file that
didn't exist. It passed two rounds of review anyway, because the reviewers were
checking whether the plan's reasoning held up, which it did. None of them checked
whether the file was real. The builder, told to edit that file, created it from
scratch to match the plan. A made-up reference had become a made-up file, and no
review caught it because none of them touched the actual code.

So I added a check with no AI in it: pull every file-and-line reference out of the
plan and confirm each one is real, the file exists and the line is within it. Run
it before anyone builds.

Now "the plan points at code that isn't there" gets caught in seconds, for the cost
of a grep, which frees the expensive reviewers to spend their attention on the
reasoning, the thing they're actually good at. A reviewer that can't see the code
can vouch for the logic; this vouches for the contact with the code.

## 2. Catch made-up references, not stale ones (and say so)

The tempting next step is "check that the reference still points at the right
thing." But that means understanding what the line actually means, a renamed
function, a moved block, which is exactly the AI-scale judgment this check exists to
avoid depending on. Trying to catch that would make the check slow, brittle, and a
new source of false confidence.

So I scoped it to made-up references only: a missing file, or a line past the end of
the file. A line that just moved inside a file that still exists passes. And I say
that plainly in the usage and the README.

The check stays fast and never claims more than it proves. Line numbers get checked
here; the meaning behind them stays the reviewer's job. I'd rather ship something
cheap that tells you where it stops than something thorough that leaves you
guessing about it.

## 3. Find the file three ways, fail closed, and own the one false positive

A reference can be written as a full path (`src/auth.ts:12`) or a bare filename
(`auth.ts:12`), and the repo may or may not be a git checkout. The pattern is also
loose enough that something like `example.com:8080` in prose reads as a
file-and-line reference, which is a real source of false positives.

So it looks for each reference three ways in order: the exact path, then a
git-tracked file by name, then a plain file search. A reference that matches nothing
is a hard fail, not a skip. And the `example.com:8080` false positive is disclosed
in the usage rather than papered over by loosening the pattern, a known edge with a
stated workaround (keep ports out of your prose).

The check works in and out of git, on full or bare references, and fails closed on
anything it can't find. The one known false positive is a line a human waves off in
a second, and it's on the record, because a weakness you disclose is one a reader
can plan around, while a weakness you hide quietly erodes trust in every green result.
