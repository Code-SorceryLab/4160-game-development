// collision - Chapter 9 demo (CSCI 4160U - Game Development)
//
// Four small scenes, one idea each. Press 1-4 to switch.
//   1 STOP       the player cannot walk through walls
//   2 BOUNCE     the ball changes direction when it hits a wall
//   3 TRIGGER    coins are picked up, the zone knows you are inside it
//   4 TUNNELING  a fast bullet jumps over a thin wall
//
// Run:  odin run source/collision          (from the repository root)
// Keys: 1-4 scene, WASD / arrows move, SPACE shoot, T small steps on/off,
//       F1 show hitboxes, R reset
//
// HOW TO READ THIS FILE
//
// Only the TOP HALF matters for collision. Read it in this order; the numbers
// in [brackets] are the same ones the README uses.
//
//   [1] the data        what a hitbox is                      Player, Ball, ...
//   [2] static things   the walls                             room, lane
//   [3] detection       "did they touch?"  -> yes or no       box_hits_wall, circle_hits_wall
//   [4] response        "what happens because they did?"      move_player, move_ball,
//                                                             collect_coins, move_bullet
//   [5] who tests whom  one `case` per scene                  update
//
// Stop at the line that says "Everything below only DRAWS and EXPLAINS".
// The bottom half is tabs, arrows, dots and text. Nothing down there changes
// where anything is.
package collision

import rl "vendor:raylib"

SCREEN_W :: 960
SCREEN_H :: 540

// Speeds are in pixels per SECOND. Every frame we multiply by `dt`, the time
// the frame took (about 1/60 of a second), to get pixels per FRAME.
//   player: 240 / 60 =  4 pixels per frame
//   bullet: 3000 / 60 = 50 pixels per frame   <- remember this number
PLAYER_SPEED  :: 240  // pixels per second
BULLET_SPEED  :: 3000 // pixels per second: 50 pixels in one frame at 60 FPS
BULLET_RADIUS :: 2
COIN_RADIUS   :: 12
BOUNCE        :: 1.0  // 1.0 keeps all the speed; try 0.8

Scene :: enum {
	Stop,
	Bounce,
	Trigger,
	Tunneling,
}

// ---------------------------------------------------------------------------
// [1] The data. A hitbox is a plain shape: a Rectangle, or a centre + a radius.
// ---------------------------------------------------------------------------
//
// There is no special "collider" type. raylib gives us two things:
//   rl.Rectangle{x, y, width, height}   x, y is the TOP-LEFT corner, y grows DOWN
//   rl.Vector2{x, y}                    a point; with a radius it is a circle
// If your own entity has a position and a size, it already has a hitbox.

Player :: struct {
	box:    rl.Rectangle, // the hitbox - smaller than what we draw
	facing: f32,          // -1 left, +1 right
}

// `vel` is the speed: how many pixels per second on x and on y.
// A negative x means "moving left", a negative y means "moving up".
Ball :: struct {
	pos, vel: rl.Vector2,
	radius:   f32,
}

Coin :: struct {
	pos:   rl.Vector2,
	taken: bool, // a taken coin stays in the array; we just skip it
}

Bullet :: struct {
	pos, vel: rl.Vector2,
	alive:    bool,
}

// ---------------------------------------------------------------------------
// [2] Static things: the walls.
// ---------------------------------------------------------------------------

// Static: these never move, so they are just lists of rectangles.
room := [?]rl.Rectangle {
	{40, 124, 880, 12},  // top
	{40, 452, 880, 12},  // bottom
	{40, 124, 12, 340},  // left
	{908, 124, 12, 340}, // right
	{420, 220, 90, 150}, // a block in the middle
}

// Scene 4 uses these two instead. The bullet flies left to right at y = 295.
lane := [?]rl.Rectangle {
	{470, 150, 4, 290},  // a THIN wall: 4 pixels
	{800, 150, 70, 290}, // a thick wall: 70 pixels
}

// The walls of the scene on screen: `room` or `lane`.
// (A slice: it does not copy the list, it points at it.)
walls: []rl.Rectangle

// A trigger zone: it does not block anything, it only knows who is inside.
// Notice it is NOT in `room`: nothing ever asks "did I hit the zone?" in order
// to stop. It is only asked about in scene 3 (search for `in_zone`).
zone := rl.Rectangle{580, 230, 220, 150}

// The whole state of the program. Dynamic things are the ones `update` changes.
scene:       Scene
player:      Player
ball:        Ball
coins:       [5]Coin
bullet:      Bullet
score:       int
small_steps: bool // T: move the bullet in many small steps instead of one
show_boxes:  bool // F1

// Called when you press 1-4 or R: put everything back where it starts.
set_scene :: proc(s: Scene) {
	scene = s
	walls = s == .Tunneling ? lane[:] : room[:]

	player = {box = {140, 280, 26, 34}, facing = 1}
	ball = {pos = {200, 200}, vel = {230, 170}, radius = 14}
	coins = {{pos = {250, 200}}, {pos = {250, 400}}, {pos = {600, 180}}, {pos = {700, 420}}, {pos = {850, 300}}}
	bullet = {}
	score = 0
	hud = {}
}

// ---------------------------------------------------------------------------
// [3] Detection: "did they touch?" - raylib answers, true or false.
// ---------------------------------------------------------------------------
//
// raylib does the geometry:
//   rl.CheckCollisionRecs(a, b)                    rectangle vs. rectangle
//   rl.CheckCollisionCircleRec(center, radius, r)  circle vs. rectangle
// Each returns a bool and changes nothing. All we add is the loop: one moving
// thing against EVERY wall. The answer is only yes or no - not which wall,
// and not how deep.

box_hits_wall :: proc(box: rl.Rectangle) -> bool {
	for wall in walls {
		if rl.CheckCollisionRecs(box, wall) do return true // one hit is enough
	}
	return false
}

circle_hits_wall :: proc(center: rl.Vector2, radius: f32) -> bool {
	for wall in walls {
		if rl.CheckCollisionCircleRec(center, radius, wall) do return true
	}
	return false
}

// ---------------------------------------------------------------------------
// [4] Response: "what happens because they did?" - that part is our code.
// ---------------------------------------------------------------------------
//
// The four procedures below all have the same shape:
//   1. move the thing
//   2. ask the detection question
//   3. if the answer is yes, do something about it
// Only step 3 is different. That step is the response.

// STOP. Try the move one axis at a time; if it put us inside a wall, undo it.
// Doing x and y separately is what lets the player slide along a wall.
//
// `move` is how far to go THIS FRAME, in pixels (about 4). Pushing down-right
// into a wall on the right: the x move is undone, the y move is kept, so the
// player slides down the wall.
// Honest limit: after an undo the player can be up to one frame of movement
// (4 pixels) away from the wall. Chapter 10 snaps it exactly to the wall.
move_player :: proc(move: rl.Vector2) {
	player.box.x += move.x
	if box_hits_wall(player.box) do player.box.x -= move.x

	player.box.y += move.y
	if box_hits_wall(player.box) do player.box.y -= move.y
}

// BOUNCE. Same idea, but instead of only undoing the move we flip the speed
// on that axis.
//
// Hit while moving on x -> it was a wall on the left or right -> `vel.x`
// changes sign and `vel.y` is left alone. Same story for y.
// This only works because every wall here is straight up-down or left-right.
// A slanted wall needs the real reflection formula (Chapter 10).
move_ball :: proc(dt: f32) {
	ball.pos.x += ball.vel.x * dt
	if circle_hits_wall(ball.pos, ball.radius) {
		ball.pos.x -= ball.vel.x * dt
		ball.vel.x = -ball.vel.x * BOUNCE
	}

	ball.pos.y += ball.vel.y * dt
	if circle_hits_wall(ball.pos, ball.radius) {
		ball.pos.y -= ball.vel.y * dt
		ball.vel.y = -ball.vel.y * BOUNCE
	}
}

// TRIGGER. Nothing is pushed or stopped; touching just makes something happen.
//
// Look at what the `if` body changes: a bool and a number. No position.
// (`for &coin` gives us the real coin, not a copy, so we can change it.)
collect_coins :: proc() {
	for &coin in coins {
		if coin.taken do continue
		if rl.CheckCollisionCircleRec(coin.pos, COIN_RADIUS, player.box) {
			coin.taken = true
			score += 1
		}
	}
}

// TUNNELING. With steps = 1 the bullet jumps 50 pixels and is tested once,
// where it lands - it can land on the far side of the thin wall without ever
// having been inside it. With more steps each jump is shorter than the wall
// is thick.
//
// The numbers: this frame the bullet must travel `vel * dt` = 50 pixels.
//   steps = 1    one jump of 50 pixels,     1 test
//   steps = 32   32 jumps of ~1.6 pixels,  32 tests
// The detection (`circle_hits_wall`) is identical in both cases. The only
// thing that changes is how many times we ask.
move_bullet :: proc(b: ^Bullet, dt: f32, steps: int) {
	step := b.vel * (dt / f32(steps))
	for _ in 0 ..< steps {
		b.pos += step
		mark_tested(b.pos) // only for the picture: one dot per test
		if circle_hits_wall(b.pos, BULLET_RADIUS) {
			b.alive = false
			return
		}
	}
}

// ---------------------------------------------------------------------------
// [5] Who tests whom. Runs once per frame, before `draw`.
// ---------------------------------------------------------------------------
//
// `dt` is the time since the last frame, in seconds (about 0.0167 at 60 FPS).
// The `switch` at the bottom is the part to read: each scene calls only the
// procedures it needs. A pair that should never collide (a coin and a wall,
// say) is simply a call nobody wrote.
// The `watch_...` calls and `hud` only feed the picture on screen; skip them.

update :: proc(dt: f32) {
	if rl.IsKeyPressed(.ONE) do set_scene(.Stop)
	if rl.IsKeyPressed(.TWO) do set_scene(.Bounce)
	if rl.IsKeyPressed(.THREE) do set_scene(.Trigger)
	if rl.IsKeyPressed(.FOUR) do set_scene(.Tunneling)
	if rl.IsKeyPressed(.R) do set_scene(scene)
	if rl.IsKeyPressed(.F1) do show_boxes = !show_boxes
	if rl.IsKeyPressed(.T) do small_steps = !small_steps

	// The keys give a direction (-1, 0 or +1 on each axis)...
	input: rl.Vector2
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) do input.x += 1
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) do input.x -= 1
	if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) do input.y += 1
	if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) do input.y -= 1
	if input.x != 0 do player.facing = input.x
	// ...and direction * speed * time = how far to go this frame.
	move := input * PLAYER_SPEED * dt

	// Who is tested against whom, scene by scene.
	switch scene {
	case .Stop: // player -> walls
		watch_player(input, move)
		move_player(move)

	case .Bounce: // ball -> walls
		before := ball.vel
		move_ball(dt)
		if ball.vel != before do hud.bounces += 1
		watch_ball()

	case .Trigger: // player -> walls, coins, zone. Coins never test walls.
		move_player(move)
		collect_coins()

	case .Tunneling: // bullet -> walls
		if rl.IsKeyPressed(.SPACE) && !bullet.alive do shoot()
		if bullet.alive {
			move_bullet(&bullet, dt, small_steps ? 32 : 1)
			if !bullet.alive do watch_bullet()
		}
	}
}

shoot :: proc() {
	// A slightly different start each time, like a real game.
	start := rl.Vector2{90 + f32(rl.GetRandomValue(0, 49)), 295}
	bullet = {pos = start, vel = {BULLET_SPEED, 0}, alive = true}
	hud.tested_count = 0
	mark_tested(start)
}

// The game loop: update, then draw, sixty times a second.
main :: proc() {
	rl.SetConfigFlags({.MSAA_4X_HINT})
	rl.InitWindow(SCREEN_W, SCREEN_H, "collision - stop, bounce, trigger, tunneling")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	set_scene(.Stop)
	for !rl.WindowShouldClose() {
		update(rl.GetFrameTime())
		draw()
	}
}

// ===========================================================================
// Everything below only DRAWS and EXPLAINS. The collision code is above.
// ===========================================================================

// What the screen shows about the scene, besides the objects themselves.
hud: struct {
	input:                rl.Vector2,       // STOP: which way the player is pushing
	blocked_x, blocked_y: bool,             // STOP: is that way blocked?
	bounces:              int,              // BOUNCE
	trail:                [90]rl.Vector2,   // BOUNCE: where the ball has been
	trail_count:          int,
	tested:               [1024]rl.Vector2, // TUNNELING: every position that was tested
	tested_count:         int,
	stopped, passed:      int,              // TUNNELING: thin wall results
}

// Would this frame's move be blocked? Asked before the move, per axis.
watch_player :: proc(input, move: rl.Vector2) {
	hud.input = input
	probe := player.box
	probe.x += move.x
	hud.blocked_x = input.x != 0 && box_hits_wall(probe)
	probe = player.box
	probe.y += move.y
	hud.blocked_y = input.y != 0 && box_hits_wall(probe)
}

watch_ball :: proc() {
	hud.trail[hud.trail_count % len(hud.trail)] = ball.pos
	hud.trail_count += 1
}

mark_tested :: proc(pos: rl.Vector2) {
	if hud.tested_count < len(hud.tested) {
		hud.tested[hud.tested_count] = pos
		hud.tested_count += 1
	}
}

// The bullet just died: on the thin wall, or further on?
watch_bullet :: proc() {
	if bullet.pos.x < lane[1].x - 50 {
		hud.stopped += 1
	} else {
		hud.passed += 1
	}
}

BG     :: rl.Color{248, 250, 252, 255}
INK    :: rl.Color{51, 65, 85, 255}
MUTED  :: rl.Color{100, 116, 139, 255}
WALL   :: rl.Color{148, 163, 184, 255}
BLUE   :: rl.Color{56, 189, 248, 255}
NAVY   :: rl.Color{3, 105, 161, 255}
ORANGE :: rl.Color{245, 158, 11, 255}
GOLD   :: rl.Color{250, 204, 21, 255}
BROWN  :: rl.Color{161, 98, 7, 255}
PURPLE :: rl.Color{168, 85, 247, 255}
RED    :: rl.Color{220, 38, 38, 255}
GREEN  :: rl.Color{22, 163, 74, 255}

TITLES := [Scene]cstring {
	.Stop      = "1  STOP",
	.Bounce    = "2  BOUNCE",
	.Trigger   = "3  TRIGGER",
	.Tunneling = "4  TUNNELING",
}

CAPTIONS := [Scene]cstring {
	.Stop      = "Walls stop the player. Blocked on one axis, it still slides on the other.",
	.Bounce    = "On a hit, the speed on that axis changes sign.",
	.Trigger   = "Coins and the zone block nothing. Touching them runs a game rule.",
	.Tunneling = "The bullet is only tested where it lands. Each dot is one test.",
}

KEYS := [Scene]cstring {
	.Stop      = "WASD move    F1 hitboxes    R reset",
	.Bounce    = "F1 hitboxes    R reset",
	.Trigger   = "WASD move    F1 hitboxes    R reset",
	.Tunneling = "SPACE shoot    T one big step / 32 small steps    R reset",
}

text :: proc(s: cstring, x, y: f32, color: rl.Color, size: i32 = 20) {
	rl.DrawText(s, i32(x), i32(y), size, color)
}

arrow :: proc(from, to: rl.Vector2, color: rl.Color) {
	rl.DrawLineEx(from, to, 4, color)
	dir := rl.Vector2Normalize(to - from)
	side := rl.Vector2{-dir.y, dir.x}
	rl.DrawLineEx(to, to - dir * 10 + side * 7, 4, color)
	rl.DrawLineEx(to, to - dir * 10 - side * 7, 4, color)
}

draw_walls :: proc() {
	for wall in walls {
		rl.DrawRectangleRec(wall, WALL)
		if show_boxes do rl.DrawRectangleLinesEx(wall, 2, GREEN)
	}
}

// What we DRAW for the player is bigger than the hitbox.
draw_player :: proc() {
	box := player.box
	body := rl.Rectangle{box.x - 7, box.y - 9, box.width + 14, box.height + 12}
	rl.DrawRectangleRounded(body, 0.5, 8, BLUE)
	eye := rl.Vector2{box.x + box.width / 2 + player.facing * 6, box.y + 4}
	rl.DrawCircleV(eye - {5, 0}, 3, NAVY)
	rl.DrawCircleV(eye + {5, 0}, 3, NAVY)
	if show_boxes do rl.DrawRectangleLinesEx(box, 2, GREEN)
}

draw_stop :: proc() {
	draw_walls()
	draw_player()

	// One arrow per axis the player is pushing on: green = free, red = blocked.
	center := rl.Vector2{player.box.x + player.box.width / 2, player.box.y + player.box.height / 2}
	if hud.input.x != 0 do arrow(center, center + {hud.input.x * 60, 0}, hud.blocked_x ? RED : GREEN)
	if hud.input.y != 0 do arrow(center, center + {0, hud.input.y * 60}, hud.blocked_y ? RED : GREEN)

	text("x:", 40, 484, INK)
	text(hud.blocked_x ? "BLOCKED" : "free", 70, 484, hud.blocked_x ? RED : GREEN)
	text("y:", 220, 484, INK)
	text(hud.blocked_y ? "BLOCKED" : "free", 250, 484, hud.blocked_y ? RED : GREEN)
}

draw_bounce :: proc() {
	draw_walls()

	// The path the ball took.
	for i in 0 ..< min(hud.trail_count, len(hud.trail)) {
		rl.DrawCircleV(hud.trail[i], 2, rl.Fade(ORANGE, 0.5))
	}
	rl.DrawCircleV(ball.pos, ball.radius, ORANGE)
	if show_boxes do rl.DrawCircleLinesV(ball.pos, ball.radius, GREEN)
	arrow(ball.pos, ball.pos + ball.vel * 0.25, BROWN)

	text(rl.TextFormat("speed x: %.0f     speed y: %.0f     bounces: %d", ball.vel.x, ball.vel.y, i32(hud.bounces)), 40, 484, INK)
}

draw_trigger :: proc() {
	// The zone lights up while the player is inside it.
	in_zone := rl.CheckCollisionRecs(player.box, zone)
	rl.DrawRectangleRec(zone, rl.Fade(PURPLE, in_zone ? 0.55 : 0.2))
	rl.DrawRectangleLinesEx(zone, 2, PURPLE)
	text("zone", zone.x + 10, zone.y + 8, PURPLE)

	draw_walls()
	for coin in coins {
		if coin.taken do continue
		rl.DrawCircleV(coin.pos, COIN_RADIUS, GOLD)
		rl.DrawCircleLinesV(coin.pos, COIN_RADIUS, show_boxes ? GREEN : BROWN)
	}
	draw_player()

	// GetCollisionRec gives back the overlapping area itself.
	if show_boxes && in_zone do rl.DrawRectangleRec(rl.GetCollisionRec(player.box, zone), rl.Fade(RED, 0.7))

	text(rl.TextFormat("coins: %d / %d", i32(score), i32(len(coins))), 40, 484, INK)
	text("in zone:", 240, 484, INK)
	text(in_zone ? "YES" : "no", 335, 484, in_zone ? PURPLE : MUTED)
}

draw_tunneling :: proc() {
	draw_walls()
	text("thin wall: 4 px", lane[0].x - 70, 126, MUTED)
	text("thick wall: 70 px", lane[1].x - 50, 126, MUTED)

	// Every position that was tested. The last one is where the bullet died.
	for i in 0 ..< hud.tested_count {
		last := i == hud.tested_count - 1 && !bullet.alive
		rl.DrawCircleV(hud.tested[i], last ? 7 : 4, last ? RED : GOLD)
		rl.DrawCircleLinesV(hud.tested[i], last ? 7 : 4, last ? RED : BROWN)
	}
	if hud.tested_count == 0 do text("press SPACE", 90, 285, MUTED)

	text(small_steps ? "32 small steps per frame" : "1 big step per frame", 40, 484, small_steps ? GREEN : RED)
	text(rl.TextFormat("stopped by the thin wall: %d", i32(hud.stopped)), 360, 484, INK)
	text(rl.TextFormat("went through: %d", i32(hud.passed)), 700, 484, hud.passed > 0 ? RED : INK)
}

draw :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(BG)

	// The four tabs, the one on screen filled in.
	for title, s in TITLES {
		tab := rl.Rectangle{40 + f32(int(s)) * 224, 14, 208, 36}
		if s == scene {
			rl.DrawRectangleRec(tab, INK)
		} else {
			rl.DrawRectangleLinesEx(tab, 2, WALL)
		}
		text(title, tab.x + 14, tab.y + 8, s == scene ? rl.WHITE : MUTED)
	}
	text(CAPTIONS[scene], 40, 64, INK)
	text(KEYS[scene], 40, 92, MUTED)

	switch scene {
	case .Stop:
		draw_stop()
	case .Bounce:
		draw_bounce()
	case .Trigger:
		draw_trigger()
	case .Tunneling:
		draw_tunneling()
	}
}
