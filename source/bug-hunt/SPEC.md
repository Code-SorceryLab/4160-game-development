# Bug Hunt — design document

This is the **specification**. When the game and this document disagree, the
game is wrong. Every rule below is numbered so a test case or a bug report can
point to it (for example, "violates R12").

## 1. Screens

- **R1.** The game opens on the **title screen**: Play, Settings, Quit.
  UP/DOWN select, ENTER confirms.
- **R2.** **Play** always starts a **new game**: level 1, full health,
  0 coins, no key.
- **R3.** **Settings** has four options and Back. UP/DOWN select, LEFT/RIGHT or
  ENTER change the value, ENTER on Back (or ESC) returns to the title screen.
  Settings are kept until the game is closed.
- **R4.** **Quit** closes the game.
- **R5.** **ESC** during play returns to the title screen. The game in progress
  is abandoned.
- **R6.** When health reaches 0 the **game over** screen appears. ENTER returns
  to the title screen.
- **R7.** Reaching the exit of level 2 shows the **win** screen with the coins
  collected, out of 12. ENTER returns to the title screen.

## 2. Settings

| Option | Values | Effect |
|---|---|---|
| **R8.** Difficulty | Easy, Hard | see the table in §4 |
| **R9.** Language | English, French | all text in the game |
| **R10.** Screen shake | On, Off | the screen shakes for 0.25 s when the player is hit |
| **R11.** Assist mode | On, Off | enemies move at **half** speed |

- **R12.** Every combination of settings is valid and the game is playable with
  any of them.

## 3. Playing

- **R13.** The player moves one tile per press of an arrow key or WASD
  (holding the key repeats). Walls (dark) and locked doors block movement.
- **R14.** **Dash:** hold SHIFT and press a direction to move up to **3 tiles**
  in a straight line. The dash **stops at the first wall or locked door**; it
  never passes through them. Only the tile where the dash ends counts (coin,
  key, spikes, stairs). After a dash, the next one is available after 0.8 s.
- **R15.** **Coins** (gold circles): +1 when the player steps on one. There are
  6 per level, 12 in total. The coin count **carries over** from level 1 to
  level 2.
- **R16.** **Key** (orange): picked up when stepped on; the HUD shows "Key".
- **R17.** **Door** (brown): walking into it while holding the key opens it and
  uses up the key. Without the key, the door blocks.
- **R18.** **Stairs** (green square) on level 1 lead to level 2. The green
  square on level 2 is the **exit** (R7).
- **R19.** **Spikes** (red triangles) hurt the player when stepped on, and once
  per second while the player stands on them.
- **R20.** **Enemies** (red squares) walk left and right and turn around at
  walls. Touching an enemy hurts the player.
- **R21.** After being hurt, the player is invulnerable for **1 s** and blinks.
- **R22.** **Health never goes below 0.**

## 4. Numbers

| | Easy | Hard |
|---|---|---|
| **R23.** Health at start | 5 | 3 |
| **R24.** Spike damage | 1 | 2 |
| **R25.** Enemy damage | 1 | 1 |
| **R26.** Seconds between enemy steps | 0.40 | 0.25 |

With Assist mode on, the time between enemy steps is doubled (R11).

## 5. Interface and text

- **R27.** The HUD (top bar) shows health (current / maximum), coins
  (collected / 12), "Key" while the player holds one, and the level number.
- **R28.** All text appears in the selected language. No English remains when
  French is selected.
- **R29.** All text fits inside its box or panel, in both languages.

## 6. Performance

- **R30.** The game runs at 60 frames per second.
- **R31.** Footsteps raise dust particles. At most **200** particles are alive
  at any time.
- **R32.** **F3** toggles a debug overlay with the frame rate and the number of
  live particles.
