# box2d-start - Chapter 10

Crates and balls in a box, simulated by **Box2D** (`vendor:box2d`, Box2D v3) and drawn with raylib.
This is the starting point for Encounter E4.

```sh
odin run source/box2d-start      # from the repository root
```

| Key | Does |
|---|---|
| left click | drop a crate at the mouse |
| right click | drop a ball at the mouse |
| `SPACE` | drop 20 crates |
| `R` | reset |

Coloured bodies are **awake**. Grey bodies are **asleep**: Box2D has stopped moving and testing them.

## Linux: build Box2D once

Odin ships Box2D compiled for Windows and macOS, but not for Linux. Without that library you get
*"Could not find the compiled box2d libraries"*. To fix it, run this once (it needs `cmake` and an internet connection):

```sh
<your odin folder>/vendor/box2d/build_box2d.sh
```

At the end it prints a warning that the **WASM** build failed. That only matters for web builds; ignore it.

## Where Chapter 10 lives in the file

| Chapter 10 idea | In `box2d_start.odin` |
|---|---|
| fixed timestep | `main`: the `for accumulator >= STEP` loop around `b2.World_Step` |
| bounciness `e` | `shape_def`: `material.restitution` |
| a wall that never moves (inverse mass 0) | `add_wall`: the default body type is **static** |
| mass | `DENSITY`: Box2D computes mass from size times density |
| sleeping piles | the grey bodies; `b2.World_GetAwakeBodyCount` |
| metres, not pixels | `PIXELS_PER_METRE`, `to_metres`, `to_pixels` |

## Try

- `RESTITUTION` 0.2 -> 0.9: everything bounces, and it takes longer to fall asleep.
- `FRICTION` 0.6 -> 0: the crates slide off the ramp.
- `CRATE_HALF` 0.4 -> 16: a crate 32 *metres* wide. This is the "pixels instead of metres" bug.
- `SUB_STEPS` 4 -> 1, then press `SPACE` a few times: the pile gets softer and more wobbly.
- `GRAVITY` 10 -> 2: the Moon.

## Encounter E4 - Get started with Box2D (1 pt, in class)

On paper, by hand. Write your **name** and **student number** at the top of the sheet, then answer:

1. **Watch it sleep.** Press `SPACE` and wait 10 seconds. What happens to the `awake` count and to the colours? Why is that a win?
2. **Find the line.** Write the name of the procedure where Box2D gets:
   - the **fixed timestep**
   - the **bounciness `e`**
   - a body that **never moves**
3. **Predict, then change one number.** For each change below, write your prediction first. Then make the change (the constants are at the top of the file), re-run, and write what actually happened.
   - `RESTITUTION` 0.2 -> 0.9
   - `FRICTION` 0.6 -> 0 (watch the ramp)
   - `CRATE_HALF` 0.4 -> 16

If your build does not work, read `box2d_start.odin` instead. Answer step 2, and write the predictions for step 3. That is full credit.

### Submit

Take a **photo of your handwritten sheet** and upload it to the **Encounter E4** assignment on Canvas **before you leave the room**.

- The whole sheet must be readable: your name and student number, and all your answers.
- Handwritten only. Typed answers or screenshots are not accepted.
- Individual work. You may share a laptop with a classmate, but each of you writes and submits your own sheet.
- In class only: no late or remote submissions.

Box2D: <https://github.com/erincatto/box2d> · docs: <https://box2d.org/documentation/>
