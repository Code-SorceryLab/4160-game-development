# CSCI 4160U — Game Development

Sample code for **CSCI 4160U - Game Development** (Ontario Tech University,
Fall 2026). Every sample is a small program in **Odin** with **raylib**, written
to be read: the comments explain the idea, and each folder has its own README
with things to look for and things to try.

## Samples

| Folder | Chapter | What it shows |
|---|---|---|
| [`source/collision`](source/collision) | 9 - Collision detection (2D) | Stop, bounce, trigger and tunneling, one small scene each |
| [`source/box2d-start`](source/box2d-start) | 10 - Physics | Crates and balls simulated by Box2D; starting point for Encounter E4 (on Linux, build Box2D once: see its README) |

## Versions

The samples are tested with:

| Tool | Version | Where it comes from |
|---|---|---|
| Odin | `dev-2026-10` | <https://github.com/odin-lang/Odin/releases/tag/dev-2026-10> |
| raylib | 6.0 | ships with Odin (`vendor:raylib`) |
| Box2D | 3.1.1 | ships with Odin (`vendor:box2d`) |

Check yours with `odin version`. Odin changes often, and an older or newer
release can fail to compile these samples. For example, before `dev-2026-07`
`b2.CreatePolygonShape` took the shape by value, not by pointer. If a sample
does not compile, check your version first.

## Setup

1. Install **Odin** `dev-2026-10`: <https://odin-lang.org/docs/install/>.
   raylib and Box2D come with it, so there is nothing else to install.
2. Get the code:

   ```sh
   git clone https://github.com/Code-SorceryLab/4160-game-development.git
   cd 4160-game-development
   ```

3. Run a sample from the repository root:

   ```sh
   odin run source/collision
   ```

## How to study a sample

1. **Run it first.** Play with it until you can say what it does.
2. **Open its README.** It tells you which part of the file matters and gives
   you questions to answer.
3. **Read the code with the program running next to it.**
4. **Change one line and predict what will happen before you run it.** Being
   wrong is the useful part.

You may use an LLM to help you read the code. The course rule still applies:
you must be able to explain any line yourself.
