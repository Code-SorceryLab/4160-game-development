# Ninja Village — Activities

> These activities are **Encounter E5 (2 pts)**. What to hand in and how
> it is graded: see the E5 handout on Canvas.

Seven activities on top of `game-template`. Each one touches a different mix
of the four tools:

| # | Activity | LDtk | Box2D | raylib | Odin | Code? |
|---|---|:-:|:-:|:-:|:-:|---|
| 1 | A new prop, no code | ● | ● | | | no |
| 2 | Dig a second lake | ● | ● | | | no |
| 3 | Coins | ● | ● | ● | ● | yes |
| 4 | Tune the feel | | ● | | ● | numbers only |
| 5 | A third level | ● | | | ● | yes |
| 6 | A pen for the animals | ● | ● | ● | ● | yes |
| 7 | An NPC who talks | ● | ● | ● | ● | yes |

Do them **in order**: 5 and 6 build on each other, and 3 teaches the pattern
that 6 and 7 repeat. Read `README.md` first. You need the parts called **The
level** and **Box2D in this game**.

Before you start:

```sh
odin run source/game-template     # it runs, you can walk around and throw shurikens
```

Open `source/game-template/assets/world.ldtk` in **LDtk 1.5.3**. Every time
you change the level: **save in LDtk (Ctrl+S), then run the game again**. The
game reads the `.ldtk` file when a level loads. Nothing is copied by hand.

Keep `F1` in mind. It draws every Box2D shape (green = boxes, yellow =
circles, magenta = portals). When something "doesn't collide", press F1
before you change any code.

Every art file you need is already in `assets/ninja-adventure/`. All of it is
CC0, so you can use it in your own project too.

---

## 1. A new prop, no code

**Goal:** add a **Statue** to the village that the player cannot walk
through, but can walk *behind*.

**You will learn:** an LDtk entity has a **picture** (its tile) and a
**footprint** (its size), and the game uses them for different things.

### Steps

1. In LDtk, open the **Entities** panel from the top toolbar (hover over the
   icons to see their names). Look at how `House` is set up before you make
   your own:
   - its **Size** is 60 x 26: only the bottom part of the 64 x 48 picture;
   - its **Pivot** is bottom-centre;
   - **Editor visual** is *Tile*, with **Tile render mode: Full size
     (uncropped)**, so the whole picture shows even though the box is
     smaller;
   - its **Tags** contain `solid`.
2. Click **+** to add a new entity. Name it `Statue`.
3. Give the statue its picture:
   - Set **Editor visual** to *Tile*. A tile picker appears below it.
   - In the picker, choose the tileset `House`. Its whole image opens
     (`TilesetHouse.png`: walls, roofs, doors, statues, ...).
   - Find the row of sandstone statues, about two-thirds of the way down the
     image, just below the doors. Pick the small statue holding a
     **blue orb** (the third object from the left).
   - It is 2 x 2 tiles, so **click and drag** across all four tiles. A single
     click only grabs one 16 x 16 tile, a quarter of the statue.
   - (Exact spot, if you need it: x 48, y 240, size 32 x 32 pixels.)
4. Set **Tile render mode** to *Full size (uncropped)* and the **pivot** to
   bottom-centre.
5. Set the **size** to the statue's *base*, the part that should block the
   player. Look at the picture: about 24 x 12.
6. Add the tag `solid`.
7. Close the panel, select the `Entities` layer, and place **three statues**
   in the village. Save.
8. Run the game. Walk into a statue from below, then walk around it and stand
   behind it. Press `F1`.

### Check

- [ ] The player stops at the statue's base, not at the top of its head.
- [ ] Standing behind the statue, the player is drawn *behind* it.
- [ ] `F1` shows a green box only around the base.

### Questions (answer in 1–2 sentences each)

1. Why can the player walk *behind* the statue but not *through* it? Name the
   two things in the code that make each of those true. (Hint: `physics.add_solid_box`
   and `draw_sorted` in `scenes/game_scene.odin`.)
2. You wrote no code. Which line in `scenes/level.odin` turned your new tag
   into a Box2D body?
3. Set the statue's size to the full 32 x 32 picture. What changes when you
   play? Why does that feel wrong in a top-down game?

---

## 2. Dig a second lake

**Goal:** paint a second lake in the Village and see how one LDtk layer becomes
both the **picture** and the **collision**.

**You will learn:** IntGrid layers, auto-rules, and how the game turns
cells into Box2D boxes.

### Steps

1. In LDtk, select the **Water** layer. Its only value is `water` (1).
2. Paint a **rectangle of water**, at least 3 x 3 cells, somewhere empty in
   the village. Watch the lake tiles appear by themselves. Those are the layer's
   **auto-rules** (the **RULES** button next to the layer name).
3. Save, run, and walk into your lake. Press `F1`.
4. Now paint one extra cell sticking out of a corner, so the lake becomes an
   **L shape**. Save and look at it in LDtk and in the game.
5. Undo the L (Ctrl+Z), save.

### Check

- [ ] The player cannot walk into your lake, from any side.
- [ ] `F1` shows **one green box per row** of water, slightly smaller than the
      painted cells.

### Questions

1. Open `read_water` in `scenes/level.odin`. Why one box per **row** and not
   one per **cell**? How many boxes would a 6 x 4 lake make each way?
2. Why are the boxes **smaller** than the cells? (Look at `SHORE`.) What
   would the player see if they were not?
3. What went wrong with the L shape, and why? Open the RULES window and look
   at the 9 rules: which situation has no rule?

---

## 3. Coins

**Goal:** coins in the village. Walking over one makes it disappear, plays a
sound, and adds 1 to a counter on the screen.

**You will learn:** adding a **tileset** in LDtk, a new **tag**, Box2D
**sensors** and sensor events, and drawing a **HUD** (heads-up display: text
drawn on top of the game).

A coin must not *block* the player. That is the difference between a
**sensor** and a normal shape: a sensor lets things pass through and **reports**
who entered it.

### Part A: LDtk

1. **Add a tileset.** Tilesets panel → **+** → choose
   `assets/ninja-adventure/Items/Treasure/Coin2.png`. Name it `Coin`. This
   image is 40 x 10: four 10 x 10 frames, so set the **grid size to 10**.
2. Add an entity `Coin`: tile = the first frame of `Coin`, size 8 x 8,
   pivot bottom-centre, tag **`pickup`**.
3. Place 6–8 coins around the village. Save.
4. Run the game. The coins show, but walking over them does nothing. Why?
   Look at what `read_entity` does with a tag it does not know.

### Part B: read the new tag (`scenes/level.odin`)

1. Add a `Pickup` value to `Thing_Kind`.
2. In `read_entity`, add a `case` for the tag `"pickup"`, like the ones for
   `"solid"` and `"animal"`.
3. In `draw_sorted` (`scenes/game_scene.odin`), pickups must be drawn too.
   Find the line that skips everything that is not `.Decor` or `.Solid`.

Run: the coins show again (after step 2 they had vanished: why?), and you
still walk over them without anything happening.

### Part C: a sensor for each coin (`physics/physics.odin`, `scenes/game_scene.odin`)

1. In `physics.odin`, write `add_sensor_box`. Copy `add_solid_box`, then
   set two fields of the shape definition:

   ```odin
   shape_def.isSensor = true
   shape_def.enableSensorEvents = true
   ```

2. **Sensor events are off by default on both sides**: the sensor *and* the
   shape that walks into it. In `entities/player.odin`, after the body is
   created, turn them on for the player's shape:

   ```odin
   shapes: [4]b2.ShapeId
   for shape in b2.Body_GetShapes(p.body, shapes[:]) do b2.Shape_EnableSensorEvents(shape, true)
   ```

3. In `game_set_level`, make a sensor body for every `.Pickup` thing. You will
   need to know later **which thing** a sensor body belongs to, so keep both:

   ```odin
   Coin_Body :: struct {
       body:  b2.BodyId,
       thing: int, // index into s.level.things
   }
   ```

   Add a `[dynamic]Coin_Body` to `Game_Scene`. Clear it with the other lists
   when a level loads.

### Part D: pick it up

1. Box2D reports sensor events after the step, next to the contact events.
   After the `World_GetContactEvents` loop in `game_tick`, add:

   ```odin
   sensor_events := b2.World_GetSensorEvents(s.world)
   for e in sensor_events.beginEvents[:sensor_events.beginCount] {
       // e.sensorShapeId  = the coin's shape
       // e.visitorShapeId = whoever walked in
   }
   ```

2. Only the **player** picks coins up. Check the visitor's category
   (`physics.category_of`) against `physics.PLAYER`.
3. Find the `Coin_Body` whose body is `b2.Shape_GetBody(e.sensorShapeId)`.
   Then:
   - add 1 to a `coins: int` in `Game_Scene`;
   - remember that thing is **taken**. One way is a `taken: [dynamic]bool`
     with one entry per level thing, resized when a level loads;
   - `b2.DestroyBody` the sensor, and remove it from the list
     (`unordered_remove`);
   - play `assets/ninja-adventure/Audio/Sounds/Bonus/Coin.wav`. Load it in
     `game_load` and unload it in `game_unload`, like `hit_sound`.
4. In `draw_sorted`, skip pickups that are taken.
5. **HUD:** after `rl.EndMode2D()`, draw the counter. Text drawn after
   `EndMode2D` stays on the screen and does not move with the camera:

   ```odin
   rl.DrawText(fmt.ctprintf("Coins: %d", s.coins), 4, 4, 10, rl.GOLD)
   ```

### Check

- [ ] Coins show in the game, and the player walks **through** them.
- [ ] Each coin disappears once, with a sound, and the counter goes up by 1.
- [ ] Animals and shurikens do **not** pick up coins.
- [ ] `F1`: no box left where a coin was taken. (The debug view only draws
      the bodies you pass it. Add the coin bodies if you want to see them.)

**Stretch:** animate the coin. `Coin2.png` has 4 frames, so move `src.x` by
10 px every 0.1 s, as `animal_draw` does with its 2 frames.

---

## 4. Tune the feel

**Goal:** understand what each number does by changing **one at a time**
and writing down what happened.

**You will learn:** game feel is mostly numbers, and Box2D's parameters
(damping, restitution, density) have names you can reason about.

Make a table with three columns: **number, from → to, what changed**. Do each
row, run, write one line, then **put the number back**.

| File | Number | Try |
|---|---|---|
| `entities/player.odin` | `SPEED` (80) | 40, then 200 |
| `entities/player.odin` | `RADIUS` (5) | 2, then 9. Walk between two pines |
| `entities/shuriken.odin` | `THROW_SPEED` (12) | 4, then 40 |
| `entities/shuriken.odin` | `LIFETIME` (1.2) | 0.3, then 5 |
| `entities/shuriken.odin` | restitution in `throw_shuriken` (0.8) | **0**, then 1.0 |
| `entities/animal.odin` | `b2.Body_SetLinearDamping(body, 3)` | 0, then 20. Push a pig |
| `entities/player.odin` | density in `player_spawn` (4) | 0.2. Push a pig |
| `scenes/game_scene.odin` | `def.gravity = {0, 0}` | `{0, 10}` |

### Questions

1. With restitution 0, what does a shuriken do when it hits a house? Which
   value would you ship, and why?
2. With damping 0, what happens to a pig after you push it? What is damping
   *for* in a top-down game?
3. With player density 0.2, who pushes whom? Why?
4. With gravity `{0, 10}`, what happens, and why does a top-down game use
   `{0, 0}`?
5. `RADIUS` 9: can the player still walk between the pines? What does that
   tell you about choosing a collision shape smaller than the sprite?

---

## 5. A third level

**Goal:** a **Farm** level, reached from the Forest. Coming back, the player
should appear at the **forest's east exit**, not at the forest's start.

**You will learn:** levels and portals in LDtk, entity **fields**, and
passing data from a portal to the level it opens.

### Part A: the level (LDtk)

1. **World** panel → add a level. Name it `Farm`, about 20 x 12 cells. It
   becomes level **2** (Village = 0, Forest = 1).
2. Paint grass on `Ground`, put trees along the edges, a few chickens.
3. Place a `PlayerStart` near the west edge, and a `Portal` on the west edge
   with `level_destination = 1`.
4. In the **Forest**, make room on the **east** edge (move some trees) and put
   a `Portal` there with `level_destination = 2`.

Save and run: Village → Forest → Farm works. But Farm → Forest puts you at the
forest's **west** start, far from where you came in.

### Part B: where do I arrive? (LDtk)

The fix is to give each `PlayerStart` an **id**, and have each `Portal` say
which id to arrive at.

1. Entities panel → `PlayerStart` → **+ Add field** → *Integer*, name `id`,
   default 0.
2. `Portal` → add an *Integer* field `spawn_id`, default 0.
3. `PlayerStart` has **Max count: 1**. Change it so a level can have more than
   one.
4. In the Forest, add a second `PlayerStart` next to the east exit, with
   `id = 1`. Do the same in the Village next to its east exit.
5. Set every portal's `spawn_id`: Farm → Forest = 1, Forest → Village = 1,
   the others 0. Make sure **no PlayerStart is inside a portal**, or you will
   bounce back and forth.

### Part C: the code

1. `scenes/level.odin`: add `spawn_id: int` to `Thing`. Fill it from the
   `id` field for a PlayerStart and from `spawn_id` for a Portal
   (`field_int`). If the field is missing, `field_int` returns −1. Treat that
   as 0.
2. `scenes/game_scene.odin`: give `game_set_level` a parameter
   `spawn_id := 0`. The `:= 0` makes it optional, so `game_load` does not
   change.
3. In the loop that builds the world, **do not** spawn the player at the
   first PlayerStart you meet. Remember the index of the one whose
   `spawn_id` matches, or the first one if none does. Spawn the player
   **after** the loop.
4. Where the portal is touched, pass `t.spawn_id` to `game_set_level`.

### Check

- [ ] Village → Forest → Farm → Forest → Village, and each time you arrive
      next to the exit you came through.
- [ ] Starting a new game still begins at the village's original start.

---

## 6. A pen for the animals

**Goal:** a fenced pen on the Farm. The HUD shows **"Home: 2/4"**. When all
animals are inside, the text turns green and a sound plays **once**.

**You will learn:** building with entities in LDtk, and a resizable
**area** entity the game reads as a rectangle. It also shows that Box2D is
what keeps things in, while a plain rectangle test is enough to count them.

### Part A: LDtk

1. Add an entity `Fence`: tileset `House`, the wooden picket tile at
   x 176, y 80 (16 x 16), size **16 x 16**, tag `solid`. Here the footprint
   is the whole tile: a fence must stop chickens on *every* side.
2. On the Farm, build a rectangle of fences about 6 x 6 tiles, with a
   **gate** (a 2-tile gap) on one side.
3. Add an entity `Pen`: **no tile** (Editor visual: rectangle), pivot
   **top-left**, tick **Resizable**. Place one and stretch it over the
   *inside* of the fence.
4. Put 3–4 chickens **outside** the pen. Save.

### Part B: the code

1. `level.odin`: add `Pen` to `Thing_Kind`, chosen by the identifier
   `"Pen"` (like `"Portal"`). Pens are invisible in the game: check that
   `draw_sorted` does not draw them.
2. `game_scene.odin`: write

   ```odin
   count_home :: proc(s: ^Game_Scene) -> (home, total: int, has_pen: bool)
   ```

   For each `.Pen` thing, count the animals whose **feet**
   (`entities.animal_feet`) are inside its footprint
   (`rl.CheckCollisionPointRec`). `total` is `len(s.animals)`. `has_pen`
   is false on levels without a pen.
3. HUD: if `has_pen`, draw `Home: home/total` under the coins, green when
   `home == total`.
4. Sound: load `Audio/Sounds/Bonus/Bonus.wav`. Play it the **first** frame
   that `home == total`, not every frame. You need a `bool` in
   `Game_Scene`, reset when a level loads.
5. In `draw_debug`, outline pens in orange so you can see them with `F1`.

### Check

- [ ] Push chickens through the gate. You cannot carry them: push them, or
      scare them with a shuriken so they run.
- [ ] Animals inside the pen cannot get out except through the gate.
- [ ] The counter is right, and the sound plays once.
- [ ] No "Home" text in the Village and the Forest.

---

## 7. An NPC who talks

**Goal:** an old man in the village. Stand next to him and press `E`: a dialog
box with his face and a line of text appears, and the game **freezes** until
you press `E` again.

**You will learn:** *String* and *File path* fields in LDtk, drawing UI from
a picture, and pausing the world without a new scene.

### Part A: LDtk

1. Add a tileset `OldMan` from
   `assets/ninja-adventure/Actor/Character/OldMan/SpriteSheet.png`, grid 16.
2. Add an entity `Npc`: tile = the first frame of `OldMan` (x 0, y 0), size
   12 x 8, pivot bottom-centre, tags **`npc` and `solid`**.
3. Add two fields to `Npc`:
   - `line`, type **String**: what they say;
   - `portrait`, type **File path**, allowed extension `png`.
4. Place him in the village. Set `line` to something useful, and `portrait` to
   `ninja-adventure/Actor/Character/OldMan/Faceset.png`. The path is
   relative to `world.ldtk`, and LDtk writes it that way when you pick the
   file. Save.

### Part B: read it (`scenes/level.odin`)

1. Add `Npc` to `Thing_Kind`, and to `Thing`: `line: string` and
   `portrait: rl.Texture2D`.
2. Write `field_string`, like `field_int`. A text field's value is a
   `json.String`:

   ```odin
   if v, is_string := f.value.(json.String); is_string do return v
   ```

3. In `read_entity`, check the tag `"npc"` **before** `"solid"`. An NPC has
   both tags, and the first matching `case` wins. Fill `line` and
   `portrait` (use `texture(lv, path)`, so it is unloaded with the level).
4. ⚠ **The JSON is in temporary memory**, freed at the end of the frame.
   A `string` that points into it will show garbage on a later frame, and
   may *look* fine for a while first, because the memory is reused, not
   removed. Keep your own copy with `strings.clone`, and `delete` it in
   `unload_level`.

### Part C: talk (`scenes/game_scene.odin`)

1. In `game_set_level`, give an `.Npc` a solid box, like a `.Solid`.
2. Draw NPCs in `draw_sorted`.
3. Add `talking: int` to `Game_Scene`: the index of the NPC thing we are
   talking to, `-1` for nobody. Set it to `-1` when a level loads.
4. Write `npc_in_reach :: proc(s: ^Game_Scene) -> int`: the closest
   `.Npc` whose feet are within ~20 px of `entities.player_feet`, or `-1`.
5. At the top of `game_tick`:
   - if `talking >= 0`: close on `E`/`SPACE`/`ESC`, **draw** the scene and
     return, with no update and no `World_Step`. That is the freeze. To do
     this, move the drawing part of `game_tick` into its own
     `draw_game :: proc(s: ^Game_Scene)` so you can call it from both places;
   - otherwise, on `E`, `s.talking = npc_in_reach(s)`.
6. Draw the box **after** `EndMode2D` (screen space), at the bottom:
   `assets/ninja-adventure/Ui/Dialog/DialogBoxFaceset.png` (300 x 58).
   The face goes in the dark square, about 6 px right and 13 px down from
   the box's corner. The text starts about 56 px right.
7. `rl.DrawText` does not wrap long lines. Either keep `line` short, or write
   a small word-wrap: add words to a line until `rl.MeasureText` says the
   next one does not fit, then start a new line 12 px lower.

### Check

- [ ] Far from him, `E` does nothing. Next to him, the box opens with his face
      and his line.
- [ ] While the box is open, chickens stop, shurikens hang in the air, and
      `SPACE` does not throw.
- [ ] `E` closes it and everything continues. `ESC` closes the box and does
      **not** jump to the title.
- [ ] Change his `line` in LDtk, save, walk through a portal and back: the
      new text shows.

**Stretch:** make the dialog its own **scene** (`Scene.Dialog`) instead of a
`talking` field. What does the scene manager need so the game is still there
when the dialog closes?
