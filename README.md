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

## Setup

1. Install **Odin**: <https://odin-lang.org/docs/install/>. raylib comes with
   it (`vendor:raylib`), so there is nothing else to install.
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
