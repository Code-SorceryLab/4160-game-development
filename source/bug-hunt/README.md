# bug-hunt — Side Quest SQ5 (5 pts): a QA pass

CSCI 4160U - Game Development · Stage 9, Chapter 18 · started in class Mon Nov 16 ·
**due Sun Nov 22, 23:59**

You are the QA team for a small game that is almost ready to ship. It comes
with a design document, `SPEC.md`, and it has **bugs**. Your job is the one
from class: check the build against the specification, report what does not
match so a developer can reproduce it, fix a few bugs, and make sure they
never come back.

```text
SPEC.md  ->  test plan  ->  play the build  ->  bug reports  ->  fix + regression test  ->  smoke run
             [A]            [B]                 [B]              [C]                        [D]
```

Do **not** start by reading the code looking for bugs. Test the game the way a
QA tester would: from the spec, by playing. The code is for Part C.

## Run

From inside the `bug-hunt` folder:

```sh
odin run .     # play
odin test .    # run the tests in tests.odin
```

| Key | Does |
|---|---|
| arrows / WASD | move one tile (hold to repeat) |
| SHIFT + direction | dash |
| ESC | back to the title screen |
| F3 | debug overlay: frame rate and live particles |

## Where things live

| File | What is in it |
|---|---|
| `SPEC.md` | the design document: **the oracle** |
| `game.odin` | the rules: moving, damage, coins, key, door, enemies, particles. No drawing, so every procedure can be called from a test |
| `main.odin` | keyboard and drawing |
| `levels.odin` | the two levels as text |
| `text.odin` | every string, in English and French |
| `tests.odin` | three example tests; yours go at the bottom |
| `TESTPLAN.md`, `BUGS.md`, `MEMO.md` | what you hand in, besides the code |

## A week, roughly 7-8 hours

| When | Part | Time |
|---|---|---|
| In class, Mon Nov 16 | read `SPEC.md`, start Part A | 30 min |
| Tue-Wed | finish A, then B | 3 h |
| Thu-Fri | C and D | 2.5 h |
| Sat-Sun | memo, zip, submit | 1 h |

---

## Part A — test plan (`TESTPLAN.md`)

From `SPEC.md` only:

1. **At least 10 test cases**, each pointing to a rule (R1-R32), with steps and
   an expected result precise enough that someone else would agree on the
   verdict. Cover different parts of the spec, not ten coin tests.
2. A **pairwise table**: 5 rows covering every pair of settings values (R12).
3. A **flow diagram** of the screens, and paths that use every arrow at least
   once.

## Part B — play and report (`TESTPLAN.md`, `BUGS.md`)

Run your test cases, your 5 pairwise rows and your flow paths, then spend at
least **20 minutes exploring**: play *not* as intended (walls, dashes, ESC at
odd moments, both difficulties, both languages, standing still, playing for a
few minutes).

Fill in the Result column of your plan and write one **bug report** per bug in
`BUGS.md`. Each report needs a rule, steps that reproduce it, expected vs.
actual, repro rate, severity and priority.

The build has several bugs of different kinds. You do not need to find all of
them: **5 good reports earn the full marks** for this part.

## Part C — fix and pin (`game.odin` / `main.odin`, `tests.odin`)

Pick **3** of your bugs and fix them. For each one:

1. **First**, write a test in `tests.odin` that reproduces the bug. Run
   `odin test .` and see it **fail**. Copy the failure line into `BUGS.md`,
   under that report.
2. Fix the code. Run `odin test .` and see it **pass**.

At least **two** of the three must be bugs whose test calls the rules in
`game.odin` (for example `apply_damage`, `start_level`, `move_player`). If you
fix a bug that cannot be tested this way (it is only visible on screen), say so
in the memo and explain how you checked the fix instead.

Name each test after the rule it protects, for example
`health_never_goes_below_zero`. Look at the three example tests for the
pattern (`new_game`, `destroy_game`, `testing.expect_value`).

## Part D — smoke run (`main.odin`)

Add the smoke run from the slides (Chapter 18, "Smoke test and BVT"):

- `SMOKE_FRAMES :: #config(SMOKE_FRAMES, 0)`
- when it is above 0: hidden window, skip the title screen (call `new_game`),
  run that many frames, exit
- `odin run . -define:SMOKE_FRAMES=600` must end on its own with exit code 0
  (`echo $?` on Linux/macOS, `echo %errorlevel%` on Windows)

Then show it catches a crash: in the smoke path, set the settings to a
combination that crashed in Part B (if you found one) **before** your fix, and
note the exit code in `BUGS.md`. If you found no crash, write "no crash found".

## Part E — memo (`MEMO.md`)

Half a page to one page, in your own words, plus the AI disclosure.

---

## Hand in

On Canvas, by **Sun Nov 22, 23:59**: a **ZIP of your whole `bug-hunt` folder**
with your fixes and tests, `TESTPLAN.md`, `BUGS.md` and `MEMO.md` filled in.
Remove compiled files (`bug-hunt`, `*.exe`, `*.bin`, `*.pdb`) first.

Individual work. LLM assistants are allowed under the usual conditions:
disclose them, and be able to explain any line. A bug "found" by asking an LLM
to read the code still needs a report whose steps reproduce it **in the game**;
reports that cite code instead of steps are not counted. The memo is yours.

Late policy is the course's: 10% of the value per day or part-day, up to 72
hours.

## How the 5 points are awarded

| | What we look for | pts |
|---|---|:--:|
| **A. Test plan** | 10+ specific cases tied to rules and covering the spec; a correct 5-row pairwise table; a flow diagram whose paths cover every arrow | 1.0 |
| **B. Bug reports** | 0.25 per valid report, up to 5: reproducible from your steps, the rule it breaks, a defensible severity and priority | 1.25 |
| **C. Fix and pin** | 3 bugs fixed; each test fails before the fix (failure line pasted) and passes after; `odin test .` passes | 1.0 |
| **D. Smoke run** | `-define:SMOKE_FRAMES=600` exits 0 without a window; the crash check is reported | 0.25 |
| **E. Memo + AI disclosure** | every question answered, specific, with your bugs and tests | 1.5 |
| | **Total** | **5.0** |

## If something is wrong

| Symptom | Cause |
|---|---|
| `odin test .` says "undeclared name" | your test calls a procedure that is not in `game.odin`; check the spelling |
| A test reports a memory leak | add `defer destroy_game(&g)` after `g: Game` |
| The smoke run never ends | the frame counter is not compared with `SMOKE_FRAMES`, or `new_game` is not called so the title screen waits for ENTER |
| The smoke run opens a window | `rl.SetConfigFlags({.WINDOW_HIDDEN})` must come **before** `rl.InitWindow` |
| Your test passes before the fix | it does not reproduce the bug: use the exact settings and inputs from your report |
