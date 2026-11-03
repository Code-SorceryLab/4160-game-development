# map-gen — Side Quest SQ4 (5 pts): a generator you can trust

CSCI 4160U - Game Development · Stage 8, Chapter 15 · started in class Wed Nov 4 ·
**due Wed Nov 11, 23:59** (one week)

You will build a small cave generator and then **prove** it works:

```text
seed  ->  random fill  ->  smoothing  ->  repair  ->  your content  ->  check  ->  ship or re-roll
          [A]              [B]            [D]         [E]               [C] [E]
                                                                        and [F]: run 1000 seeds, count
```

The point of the quest is not the caves. It is the **second program**: the
check that rejects a bad level, and the numbers that show it does.

## Run

From inside the `map-gen` folder:

```sh
odin run .
```

| Key | Does |
|---|---|
| `SPACE` | next seed |
| `R` | same seed again |
| `UP` / `DOWN` | more / fewer smoothing passes |
| `T` | test report: 1000 seeds, printed in the terminal |

Blue dot: start. Red dot: exit. Gold squares: what you place in Part E. The
bottom line shows the seed, how many seeds were rejected, and whether the map
passed.

It runs before you do anything: an empty box with a border.

## Where things live in `map_gen.odin`

| | |
|---|---|
| `[1]` | the numbers you will change: map size, `FILL`, `MAX_TRIES`, `REPAIR` |
| `[A]` `random_fill` | **yours**: turn a seed into walls and floor |
| `[B]` `smooth` | **yours**: one pass of the 4-5 rule |
| `[C]` `reachable` | **yours**: flood fill from start, did it reach the exit? |
| `[D]` `keep_largest` | **yours**: wall off every cave except the biggest |
| `[E]` `place_content` | **yours**: place something, and reject the map if it breaks your rule |
| `[F]` `test_report` | **yours**: run 1000 seeds, print what happened |
| `generate` | given: fill, smooth, repair, pick start and exit, check, re-roll |

Stop at "Everything below only DRAWS". Nothing down there changes the map.

---

## Part A — random fill (in class)

The steps are in the `TODO [A]` comment. Use the seeded generator, **not**
the global `rand`.

**Check:** the map looks like TV static with a solid border. `R` gives exactly
the same map; closing and reopening the game, seed 42 is still the same.

## Part B — smoothing (in class)

The 4-5 rule, written into a **copy** of the grid (`TODO [B]`).

**Check:** with 4 passes you see caves. `DOWN` to 0 shows the static again;
`UP` one at a time shows the caves forming.

## Part C — the check (in class or at home)

Flood fill from the start (`TODO [C]`). Right now `reachable` says yes to
everything.

**Check:** press `SPACE` until `rejected` is more than 0: that map came from a
later seed than the one you asked for.

## Part D — repair instead of re-roll

Re-rolling throws the whole map away. **Repairing** fixes it: keep only the
largest cave and turn every other cave into wall (`TODO [D]`). Then set
`REPAIR :: true`.

**Check:** no small islands of floor are left. Write down the `T` report with
`REPAIR` off and on: you need both for the memo.

## Part E — your content, with its own check

Pick **one** option. Put what you place in `m.items` / `m.n_items` (they are
drawn as gold squares), or add your own fields to `Map` and draw them.
Return `false` from `place_content` when your rule is broken, so the map is
re-rolled.

| Option | Place | The check (return `false` if...) |
|---|---|---|
| **1. Treasure far away** | 5 treasures on floor cells | any treasure is less than `MIN_DIST` steps from the start (add `MIN_DIST :: 25` at the top; walking distance, not straight line: turn your flood fill into a BFS that counts steps) |
| **2. Key and door** | a key and a locked door on the path from start to exit | the key can't be reached from the start **without** walking through the door |
| **3. Best of N** | nothing new; instead generate 10 candidates (this option changes `generate`) | keep the one with the **longest** path from start to exit (a score, not pass/fail) |
| **4. Your own** | anything your Main Quest needs: enemies, chests, a boss room... | you define the rule; say in the memo why it matters to the player |

Use a **separate** random generator for placement (the comment shows how),
so changing Part E never changes the caves.

**Check:** find a seed where your rule rejected the map (`rejected` > 0 with
`REPAIR` on) and write it down.

## Part F — evidence

A check you have not measured is a claim. Write `test_report` (`TODO [F]`):
for seeds 1 to 1000, run `generate` and print:

- how many were accepted on the first try
- the average number of rejections
- the worst seed, and how many re-rolls it needed
- how many gave up after `MAX_TRIES`

Press `T` and copy the output into your memo. Run it at least three times:
`REPAIR` off, `REPAIR` on, and one other `FILL` value of your choice.

## Part G — the memo

Fill in `MEMO.md`: half a page to one page, in your own words, plus the AI
disclosure.

---

## Hand in

On Canvas, by **Wed Nov 11, 23:59**: a **ZIP of your whole `map-gen` folder**
with `map_gen.odin` (all TODOs done) and `MEMO.md` filled in. Remove compiled
files (`map-gen`, `*.exe`, `*.bin`, `*.pdb`) first.

Individual work. LLM assistants are allowed for the code under the usual
conditions: disclose it, and be able to explain any line. The memo is yours.

Late policy is the course's: 10% of the value per day or part-day, up to 72
hours.

## How the 5 points are awarded

| | What we look for | pts |
|---|---|:--:|
| **A-C. Generator + check** | same seed gives the same map; caves after 4 passes, smoothed into a copy; flood fill rejects maps whose exit can't be reached | 1.5 |
| **D. Repair** | only the largest cave is left; `REPAIR` on and off both work | 0.5 |
| **E. Your content** | one option done, placed with its own generator, and the check really rejects maps that break the rule (a seed is given) | 1.0 |
| **F. Evidence** | `T` prints the four numbers; the memo has the three runs | 0.5 |
| **G. Memo + AI disclosure** | every question answered, specific, with your numbers | 1.5 |
| | **Total** | **5.0** |

## If something is wrong

| Symptom | Cause |
|---|---|
| `R` gives a different map | you used the global `rand` instead of the seeded generator in `[A]` |
| The caves drift diagonally or fill up | `[B]` writes into `g` instead of `next` |
| `rejected` is always 0, even with `FILL :: 0.55` | `[C]` still returns `true`, or it never pushes the neighbours |
| The game freezes on some seeds | `[C]` or `[D]` pushes cells it has already visited: mark them **before** pushing |
| Changing Part E changes the caves | `[E]` uses the same generator as `[A]`: give it its own |
| Every map is rejected | your Part E rule can never be met; print why it returned `false` |
