// map-gen - Chapter 15, Side Quest SQ4 (CSCI 4160U - Game Development)
//
// Six pieces are yours, in order, each marked TODO:
//   [A] random_fill   [B] smooth   [C] reachable      - the generator and its check
//   [D] keep_largest  [E] place_content  [F] test_report - repair, your content, evidence
// The game runs before you start: it shows an empty box. See README.md.
//
// A cave generator: random fill -> smoothing passes -> "is the exit reachable?"
// If the check fails, re-roll with the next seed.
//
// Run:  odin run source/map-gen      (from the repository root)
// Keys: SPACE new seed, R same seed again, UP / DOWN smoothing passes,
//       T test report (printed in the terminal)
package map_gen

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

// ---------------------------------------------------------------------------
// [1] The numbers you will change
// ---------------------------------------------------------------------------
MAP_W     :: 60
MAP_H     :: 32
CELL      :: 16       // pixels per cell
FILL      :: 0.45     // chance that a cell starts as wall
MAX_TRIES :: 100      // re-rolls before giving up
REPAIR    :: false    // [D] set to true once keep_largest works
MAX_ITEMS :: 8        // [E] room for up to 8 things you place

WALL  :: 1
FLOOR :: 0

Grid :: [MAP_H][MAP_W]u8
Cell :: [2]int        // x, y

Map :: struct {
	cells:  Grid,
	seed:   u64,      // the seed that produced THIS map (after re-rolls)
	tries:  int,      // how many seeds were rejected first
	start:  Cell,
	exit:   Cell,
	ok:     bool,     // the exit is reachable from the start, and [E] says yes
	items:  [MAX_ITEMS]Cell,   // [E] what you place (drawn as gold squares)
	n_items: int,
}

// ---------------------------------------------------------------------------
// [A] Random fill. Same seed -> same map.
// ---------------------------------------------------------------------------
random_fill :: proc(g: ^Grid, seed: u64) {
	// TODO [A]
	// 1. Make a generator from the seed - NOT the global one, so the same seed
	//    always gives the same map:
	//        state := rand.create(seed)
	//        gen := rand.default_random_generator(&state)
	// 2. Loop over every cell (y in 0 ..< MAP_H, x in 0 ..< MAP_W).
	// 3. A cell on the border (x == 0, y == 0, x == MAP_W - 1, y == MAP_H - 1)
	//    is always WALL.
	// 4. Any other cell is WALL if rand.float32(gen) < FILL, else FLOOR.
	//
	// For now: walls on the border only, so the game runs.
	for y in 0 ..< MAP_H {
		for x in 0 ..< MAP_W {
			border := x == 0 || y == 0 || x == MAP_W - 1 || y == MAP_H - 1
			g[y][x] = WALL if border else FLOOR
		}
	}
}

// ---------------------------------------------------------------------------
// [B] One smoothing pass: the 4-5 rule, written into a COPY.
// ---------------------------------------------------------------------------
count_walls :: proc(g: ^Grid, x, y: int) -> int {
	n := 0
	for dy in -1 ..= 1 {
		for dx in -1 ..= 1 {
			if dx == 0 && dy == 0 do continue
			nx, ny := x + dx, y + dy
			if nx < 0 || ny < 0 || nx >= MAP_W || ny >= MAP_H || g[ny][nx] == WALL do n += 1
		}
	}
	return n
}

smooth :: proc(g: ^Grid) {
	// TODO [B]
	// 1. Make a copy:  next := g^   (fixed arrays are values, so this copies)
	// 2. For every cell NOT on the border (1 ..< MAP_H - 1, 1 ..< MAP_W - 1):
	//        n := count_walls(g, x, y)      // read the OLD grid
	//        if n >= 5 -> next[y][x] = WALL
	//        if n <= 3 -> next[y][x] = FLOOR
	//        (exactly 4: leave it as it was)
	// 3. Copy back:  g^ = next
	//
	// Why the copy: if you write into g while you read it, cells you already
	// changed feed the counts of the ones you haven't, and the pattern drifts.
}

// ---------------------------------------------------------------------------
// [C] The check: flood fill from start. Did we reach the exit?
// ---------------------------------------------------------------------------
reachable :: proc(g: ^Grid, start, exit: Cell) -> bool {
	// TODO [C] flood fill with a stack.
	// 1. visited: [MAP_H][MAP_W]bool
	//    stack := make([dynamic]Cell, context.temp_allocator)
	// 2. Push start, mark it visited.
	// 3. While the stack is not empty:
	//        c := pop(&stack)
	//        if c == exit -> return true
	//        for each of the 4 neighbours n = c + {1,0}, {-1,0}, {0,1}, {0,-1}:
	//            skip it if it is outside the map, a WALL, or already visited
	//            otherwise mark it visited and push it
	// 4. The stack ran out without finding the exit -> return false
	//
	// For now it says yes to everything, so nothing is ever rejected.
	return true
}

// ---------------------------------------------------------------------------
// [D] Repair: keep only the largest cave, wall off the rest.
// ---------------------------------------------------------------------------
keep_largest :: proc(g: ^Grid) {
	// TODO [D]
	// 1. id: [MAP_H][MAP_W]int, every cell -1 ("no cave yet").
	// 2. For every FLOOR cell with id -1: flood fill from it (like [C]) and give
	//    every cell you reach the same new id. Count the cells of each id.
	// 3. Every FLOOR cell whose id is not the biggest one becomes WALL.
	// Then set REPAIR :: true at the top.
}

// ---------------------------------------------------------------------------
// [E] Your content + its check. Return false to reject this map.
// ---------------------------------------------------------------------------
place_content :: proc(m: ^Map, seed: u64) -> bool {
	// TODO [E] pick ONE option (README.md, Part E), place it in m.items /
	// m.n_items (or add your own fields to Map), and return false if the
	// placement breaks your rule.
	// Use its OWN generator, so changing this code never moves the caves:
	//     state := rand.create(seed ~ 0x17E35)
	//     gen := rand.default_random_generator(&state)
	return true
}

// ---------------------------------------------------------------------------
// [F] Evidence: run many seeds, print what happened. Bound to the T key.
// ---------------------------------------------------------------------------
test_report :: proc(passes: int) {
	// TODO [F]
	// For seed in 1 ..= 1000: m := generate(seed, passes), then
	// free_all(context.temp_allocator). Count and print with fmt.printfln:
	//   - how many were accepted on the first try (m.tries == 0)
	//   - the average number of rejections (m.tries)
	//   - the worst seed and how many re-rolls it needed
	//   - how many gave up (m.ok == false after MAX_TRIES)
	fmt.println("test_report: TODO [F]")
}

// ---------------------------------------------------------------------------
// Generate and test. Given: you do not need to change this.
// ---------------------------------------------------------------------------
first_floor :: proc(g: ^Grid, from_end: bool) -> Cell {
	for i in 0 ..< MAP_W * MAP_H {
		k := MAP_W * MAP_H - 1 - i if from_end else i
		x, y := k % MAP_W, k / MAP_W
		if g[y][x] == FLOOR do return {x, y}
	}
	return {1, 1}
}

generate :: proc(seed: u64, passes: int) -> (m: Map) {
	for try in 0 ..< MAX_TRIES {
		m.seed = seed + u64(try)
		m.tries = try
		random_fill(&m.cells, m.seed)
		for _ in 0 ..< passes do smooth(&m.cells)
		when REPAIR do keep_largest(&m.cells)
		m.start = first_floor(&m.cells, false)   // top-left-most floor
		m.exit = first_floor(&m.cells, true)     // bottom-right-most floor
		m.ok = reachable(&m.cells, m.start, m.exit) && place_content(&m, m.seed)
		if m.ok do return
	}
	return
}

// ---------------------------------------------------------------------------
// Everything below only DRAWS.
// ---------------------------------------------------------------------------
main :: proc() {
	rl.InitWindow(MAP_W * CELL, MAP_H * CELL + 40, "map-gen")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	seed: u64 = 42
	passes := 4
	m := generate(seed, passes)

	for !rl.WindowShouldClose() {
		regen := false
		if rl.IsKeyPressed(.SPACE) { seed = m.seed + 1; regen = true }
		if rl.IsKeyPressed(.R)     { regen = true }
		if rl.IsKeyPressed(.UP)    { passes = min(passes + 1, 8); regen = true }
		if rl.IsKeyPressed(.DOWN)  { passes = max(passes - 1, 0); regen = true }
		if rl.IsKeyPressed(.T)     do test_report(passes)
		if regen do m = generate(seed, passes)
		free_all(context.temp_allocator)

		rl.BeginDrawing()
		rl.ClearBackground(rl.Color{28, 25, 23, 255})
		for y in 0 ..< MAP_H {
			for x in 0 ..< MAP_W {
				col := rl.Color{87, 83, 78, 255} if m.cells[y][x] == WALL else rl.Color{231, 229, 228, 255}
				rl.DrawRectangle(i32(x * CELL), i32(y * CELL), CELL, CELL, col)
			}
		}
		half :: CELL / 2
		rl.DrawCircle(i32(m.start.x * CELL + half), i32(m.start.y * CELL + half), half, rl.BLUE)
		rl.DrawCircle(i32(m.exit.x * CELL + half), i32(m.exit.y * CELL + half), half, rl.RED)
		for i in 0 ..< m.n_items do rl.DrawRectangle(i32(m.items[i].x * CELL + 3), i32(m.items[i].y * CELL + 3), CELL - 6, CELL - 6, rl.GOLD)

		hud := fmt.ctprintf("seed %v   passes %v   rejected %v   exit %v   [SPACE new  R again  UP/DOWN passes  T test]",
			m.seed, passes, m.tries, "reachable" if m.ok else "NOT reachable")
		rl.DrawText(hud, 10, MAP_H * CELL + 12, 18, rl.GREEN if m.ok else rl.RED)
		rl.EndDrawing()
	}
}
