# game-template — Ninja Village

A small top-down game that uses the four tools of this course together, laid
out like a real project:

| Tool | Its job here |
|---|---|
| **LDtk** | where everything is: grass, the lake, houses, trees, animals, the exits |
| **Box2D** | what may overlap: you can't walk through houses, trees or water; animals get pushed; shurikens bounce and knock things |
| **raylib** | pictures, animation, the camera, music and sound |
| **Odin** | the glue: structs, arrays, procs, one folder per package |

The folder layout comes from
[tupini07/raylib-cpp-cmake-template](https://github.com/tupini07/raylib-cpp-cmake-template)
(C++/CMake); the art and sound from
[Ninja Adventure](https://pixel-boy.itch.io/ninja-adventure-asset-pack)
by Pixel-boy and AAA (CC0).

```sh
odin run source/game-template      # from the repository root
odin run .                         # from inside this folder
```

**Title:** mouse or `ENTER`. **Game:** `WASD`/arrows move, `SPACE` throw a
shuriken, `F1` debug view (every Box2D shape), `ESC` back to the title. Walk
off the right edge of the village to reach the forest. `Q` quits.

Linux only, once: `<your odin folder>/vendor/box2d/build_box2d.sh` (needs cmake).

## Where things live

```text
game-template/
├── main.odin               window, audio, loop; draws a 320x180 canvas stretched 4x
├── config/config.odin      sizes, pixels <-> metres, asset paths, music settings
├── scenes/
│   ├── scene_manager.odin  which scene runs; switching
│   ├── title_scene.odin    title, portrait, raygui widgets (music on/off, volume)
│   ├── game_scene.odin     builds the Box2D world from the level; camera; draw order
│   └── level.odin          reads assets/world.ldtk
├── entities/
│   ├── player.odin         the ninja: input, 4-direction animation
│   ├── animal.odin         chickens and pigs that wander and get scared
│   ├── shuriken.odin       thrown stars and their smoke puffs
│   └── sprite.odin         "draw this picture standing here"
├── physics/physics.odin    collision categories, body helpers, debug drawing
└── assets/
    ├── world.ldtk          the levels (open it in LDtk 1.5.3)
    └── ninja-adventure/    the art pack files we use, same folders as the pack
```

Each folder is one Odin **package**. A file imports another folder with a
relative path (`import "../config"`). Odin does not allow two packages to
import each other, so the arrows only go one way:

```text
main ──> scenes ──> entities ──> physics ──> config
```

## The level: `assets/world.ldtk`

Two levels, **Village** (30x20 tiles) and **Forest** (20x15), 16 px tiles.

| Layer | Type | What the game does with it |
|---|---|---|
| `Entities` | Entities | see below |
| `Water` | IntGrid, `1` = water | LDtk's **auto-rules** pick the lake tiles; the game turns the same cells into Box2D boxes |
| `Ground` | Tiles (`TilesetFloor.png`) | drawn |

Every entity has a **size** and a **tile**, and they mean different things:

- the **tile** is the picture (a 64x48 house);
- the **size** is the **footprint**, the part that collides (the bottom 60x26
  of the house). The picture stands on it: pivot bottom-centre.

So you can walk *behind* a roof but not *through* a wall. The game draws
everything sorted by where its feet are, so whoever is lower on the screen is
in front.

What an entity **is** comes from its **tags** in LDtk (Entities panel → the
entity → Tags), not from its name:

| Tag | Game | Examples |
|---|---|---|
| `solid` | a static Box2D box on the footprint | House, HouseBeige, HouseRed, Tree, Pine, BigTree, Rock |
| `animal` | a dynamic Box2D circle that wanders | Chicken, Pig |
| none | just a picture | Bush, Flower |

Plus two special ones: `PlayerStart`, and `Portal` with an Int field
`level_destination`.

**To add a new kind of thing, no code changes:** in LDtk, add an entity, pick
its tile from a tileset, set its size to the part that should collide, tag it
`solid` (or `animal`, or nothing). Place it, save, run.

To make a lake: select the `Water` layer and paint `water` cells. Keep lakes
rectangular and at least 2x2: the rules have no inner corners.

## Box2D in this game

- **No gravity** (`{0, 0}`): it is seen from above.
- **Static boxes**: the four level edges, every `solid` footprint, each row of
  water cells.
- **Dynamic circles**: the player (heavy, so it pushes animals), animals
  (light, with damping so they slide to a stop), shurikens (bullets, bouncy).
- **Categories** (`physics.SOLID`, `PLAYER`, `ANIMAL`, `SHURIKEN`) say who
  collides with whom: shurikens pass through the player, for example.
- **Contact events**: after each step, `World_GetContactEvents` lists what
  started touching. A shuriken touching an animal plays a sound and scares it.
- The step is **fixed** (1/60 s, with an accumulator), as in Chapter 10.

## Memory, in Odin

- Shurikens live in `#soa[dynamic]Shuriken`, and a dead one is swap-removed
  (`unordered_remove_soa`): the array stays packed.
- The draw list in `game_scene.odin` is built in `context.temp_allocator`
  every frame and freed by the one `free_all` in `main.odin`.
- The level is read once into flat arrays (`things`, `water`, tile lists);
  the frame loop never touches JSON.


## Assets

Everything in `assets/ninja-adventure/` is from the **Ninja Adventure Asset
Pack** by [Pixel-boy](https://pixel-boy.itch.io/) and
[AAA](https://www.instagram.com/challenger.aaa/), released under **CC0**
(public domain): free to use, change and redistribute. The pack's
`LICENSE.txt` and `README.md` are included. Only the files this game uses were
copied, in the pack's own folder structure; the full pack (characters,
monsters, bosses, tilesets, items, UI, 37 music tracks) is at the link above.

`world.ldtk` was made for this course.
