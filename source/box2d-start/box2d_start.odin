// box2d-start - Chapter 10 encounter (CSCI 4160U - Game Development)
//
// A box of crates and balls, simulated by Box2D and drawn by raylib.
// Every idea from Chapter 10 is in here under Box2D's name.
//
// Run:  odin run source/box2d-start          (from the repository root)
// Keys: LEFT click drop a crate, RIGHT click drop a ball, SPACE drop 20 crates,
//       R reset
//
// Linux only, once: Odin does not ship a compiled Box2D for Linux. Run
//   <your odin folder>/vendor/box2d/build_box2d.sh      (needs cmake)
// Windows and macOS work out of the box.
//
// HOW TO READ THIS FILE
//
//   [1] the numbers you will change     the constants right below
//   [2] the world and the static things make_world
//   [3] dropping a body                 drop_crate, drop_ball
//   [4] the fixed step                  main, the `for accumulator` loop
//
// Stop at "Everything below only DRAWS". Nothing down there moves anything.
package box2d_start

import "core:fmt"
import b2 "vendor:box2d"
import rl "vendor:raylib"

SCREEN_W :: 960
SCREEN_H :: 540

// ---------------------------------------------------------------------------
// [1] The numbers you will change. Box2D works in METRES, not pixels.
// ---------------------------------------------------------------------------
PIXELS_PER_METRE :: 40.0          // 960 x 540 pixels = 24 x 13.5 metres
GRAVITY          :: 10.0          // metres per second^2, y points DOWN like raylib
CRATE_HALF       :: 0.4           // half the crate's width, in METRES (a 0.8 m crate)
BALL_RADIUS      :: 0.3           // metres
RESTITUTION      :: 0.2           // today's "e": 0 = no bounce, 1 = bounces forever
FRICTION         :: 0.6           // 0 = ice
DENSITY          :: 1.0           // kg per square metre: mass comes from size * density
STEP             :: 1.0 / 60.0    // the fixed timestep, in seconds
SUB_STEPS        :: 4             // Box2D splits every step into this many smaller ones

Kind :: enum { Crate, Ball }

Thing :: struct {
	id:   b2.BodyId,
	kind: Kind,
}

// A static box, kept so we can draw it. Box2D does not draw anything.
Wall :: struct {
	centre: b2.Vec2, // metres
	half:   b2.Vec2, // metres
	angle:  f32,     // radians
}

world:  b2.WorldId
things: [dynamic]Thing
walls:  [dynamic]Wall

// ---------------------------------------------------------------------------
// [2] The world, and the static things: a floor, two walls and a ramp.
// ---------------------------------------------------------------------------
make_world :: proc() {
	def := b2.DefaultWorldDef()
	def.gravity = {0, GRAVITY}
	world = b2.CreateWorld(def)

	clear(&things)
	clear(&walls)
	add_wall({12, 13}, {12, 0.5}, 0)        // floor
	add_wall({0.25, 6.75}, {0.25, 6.75}, 0) // left wall
	add_wall({23.75, 6.75}, {0.25, 6.75}, 0) // right wall
	add_wall({7, 8}, {4, 0.2}, 0.3)         // a ramp, tilted 0.3 radians (~17 degrees)
}

add_wall :: proc(centre, half: b2.Vec2, angle: f32) {
	body_def := b2.DefaultBodyDef()          // the default type is STATIC: it never moves
	body_def.position = centre
	body_def.rotation = b2.MakeRot(angle)
	body := b2.CreateBody(world, body_def)
	_ = b2.CreatePolygonShape(body, b2.DefaultShapeDef(), b2.MakeBox(half.x, half.y))
	append(&walls, Wall{centre, half, angle})
}

// ---------------------------------------------------------------------------
// [3] Dropping a body: a DYNAMIC body, plus one shape with a material.
// ---------------------------------------------------------------------------
shape_def :: proc() -> b2.ShapeDef {
	def := b2.DefaultShapeDef()
	def.density = DENSITY
	def.material.friction = FRICTION
	def.material.restitution = RESTITUTION
	return def
}

dynamic_body :: proc(at: b2.Vec2) -> b2.BodyId {
	body_def := b2.DefaultBodyDef()
	body_def.type = .dynamicBody
	body_def.position = at
	return b2.CreateBody(world, body_def)
}

drop_crate :: proc(at: b2.Vec2) {
	body := dynamic_body(at)
	_ = b2.CreatePolygonShape(body, shape_def(), b2.MakeBox(CRATE_HALF, CRATE_HALF))
	append(&things, Thing{body, .Crate})
}

drop_ball :: proc(at: b2.Vec2) {
	body := dynamic_body(at)
	_ = b2.CreateCircleShape(body, shape_def(), {radius = BALL_RADIUS})
	append(&things, Thing{body, .Ball})
}

to_metres :: proc(p: rl.Vector2) -> b2.Vec2 {return p / PIXELS_PER_METRE}
to_pixels :: proc(p: b2.Vec2) -> rl.Vector2 {return p * PIXELS_PER_METRE}

// ---------------------------------------------------------------------------
// [4] The game loop. Physics always takes the same step (Chapter 10).
// ---------------------------------------------------------------------------
main :: proc() {
	rl.InitWindow(SCREEN_W, SCREEN_H, "box2d-start - Chapter 10")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	make_world()
	defer b2.DestroyWorld(world)
	accumulator: f32

	for !rl.WindowShouldClose() {
		mouse := to_metres(rl.GetMousePosition())
		if rl.IsMouseButtonPressed(.LEFT) do drop_crate(mouse)
		if rl.IsMouseButtonPressed(.RIGHT) do drop_ball(mouse)
		if rl.IsKeyPressed(.SPACE) {
			for i in 0 ..< 20 do drop_crate({4 + f32(i % 10) * 1.6, 1 + f32(i / 10)})
		}
		if rl.IsKeyPressed(.R) {
			b2.DestroyWorld(world)
			make_world()
		}

		accumulator += min(rl.GetFrameTime(), 0.25)
		for accumulator >= STEP {
			b2.World_Step(world, STEP, SUB_STEPS)
			accumulator -= STEP
		}

		draw()
	}
}

// ===========================================================================
// Everything below only DRAWS. Nothing down here moves anything.
// ===========================================================================

draw :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground({245, 245, 240, 255})

	for w in walls do draw_box(w.centre, w.half, w.angle, rl.GRAY)

	for t in things {
		pos := b2.Body_GetPosition(t.id)
		rot := b2.Body_GetRotation(t.id)
		angle := b2.Rot_GetAngle(rot)
		// Awake bodies are coloured; sleeping ones turn light grey.
		colour := b2.Body_IsAwake(t.id) ? rl.ORANGE : rl.LIGHTGRAY
		switch t.kind {
		case .Crate:
			draw_box(pos, {CRATE_HALF, CRATE_HALF}, angle, colour)
		case .Ball:
			rl.DrawCircleV(to_pixels(pos), BALL_RADIUS * PIXELS_PER_METRE, colour)
			// a line from the centre, so you can see it roll
			tip := pos + b2.Vec2{rot.c, rot.s} * BALL_RADIUS
			rl.DrawLineEx(to_pixels(pos), to_pixels(tip), 2, rl.DARKGRAY)
		}
	}

	awake := b2.World_GetAwakeBodyCount(world)
	text := fmt.ctprintf("bodies: %d   awake: %d   (grey = asleep)   e = %.2f",
		len(things), awake, RESTITUTION)
	rl.DrawText(text, 20, 16, 20, rl.DARKGRAY)
	rl.DrawText("LEFT crate  RIGHT ball  SPACE 20 crates  R reset", 20, 40, 18, rl.GRAY)
}

// A box given in metres (centre, half size, angle in radians), drawn in pixels.
draw_box :: proc(centre, half: b2.Vec2, angle: f32, colour: rl.Color) {
	size := half * 2 * PIXELS_PER_METRE
	rect := rl.Rectangle{to_pixels(centre).x, to_pixels(centre).y, size.x, size.y}
	rl.DrawRectanglePro(rect, size / 2, angle * rl.RAD2DEG, colour)
}
