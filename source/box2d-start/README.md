# box2d-start - Chapter 10

Crates and balls in a box, simulated by **Box2D** (`vendor:box2d`, Box2D v3) and drawn with raylib.
This is the starting point for Encounter E5.

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

Box2D: <https://github.com/erincatto/box2d> · docs: <https://box2d.org/documentation/>
