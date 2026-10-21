package entities

// -----------------------------------------------------------------------------
// The player: a ninja seen from above. A round Box2D body at the feet, a
// 16x16 sprite standing on it. (C++ template: entities/Player/Player.cpp)
//
// No class: a Player struct plus procs that take ^Player.
//   player_load   once, when the game scene starts (loads the texture)
//   player_spawn  every level (makes the body at the LDtk PlayerStart)
//   player_update every frame
//   player_draw   every frame
//   player_unload when the game scene ends
//
// The sheet (Actor/Character/NinjaGreen/SpriteSheet.png) is 4 columns x 7 rows
// of 16x16: one COLUMN per direction, one ROW per frame.
//   rows 0-3  walk (row 0 is also standing still)
//   row  4    attack (we show it while throwing)
// -----------------------------------------------------------------------------

import "../config"
import "../physics"
import b2 "vendor:box2d"
import rl "vendor:raylib"

SPRITE_SHEET :: config.ART + "Actor/Character/NinjaGreen/SpriteSheet.png"

FRAME_TIME :: 0.15 // seconds per walk frame
SPEED      :: 80.0 // pixels per second
RADIUS     :: 5.0 // pixels: the body is a small circle at the feet
THROW_POSE :: 0.2 // seconds the attack frame stays after a throw

// The column of the sheet for each direction.
Facing :: enum {
	Down  = 0,
	Up    = 1,
	Left  = 2,
	Right = 3,
}

FACING_VECTOR := [Facing]rl.Vector2 {
	.Down  = {0, 1},
	.Up    = {0, -1},
	.Left  = {-1, 0},
	.Right = {1, 0},
}

Player :: struct {
	sheet:       rl.Texture2D,
	body:        b2.BodyId,
	facing:      Facing,
	moving:      bool,
	walk_timer:  f32,
	throw_timer: f32,
}

player_load :: proc(p: ^Player) {
	p.sheet = rl.LoadTexture(config.asset_path(SPRITE_SHEET))
}

player_unload :: proc(p: ^Player) {
	rl.UnloadTexture(p.sheet)
}

// `feet` is the LDtk PlayerStart position, in pixels.
player_spawn :: proc(p: ^Player, world: b2.WorldId, feet: rl.Vector2) {
	// heavier than an animal, so the player pushes them and not the other way round
	p.body = physics.add_dynamic_circle(world, feet, RADIUS, 4,
		physics.PLAYER, physics.SOLID | physics.ANIMAL)
	p.facing = .Down
}

// Read the keys and set the body's velocity. Box2D does the moving
// (and the stopping, at houses, trees and water).
player_update :: proc(p: ^Player, dt: f32) {
	dir: rl.Vector2
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) do dir.x -= 1
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) do dir.x += 1
	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) do dir.y -= 1
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) do dir.y += 1

	p.moving = dir != {0, 0}
	if p.moving {
		dir = rl.Vector2Normalize(dir) // diagonals are not faster
		// face the way you mostly go
		if abs(dir.x) > abs(dir.y) {
			p.facing = dir.x < 0 ? .Left : .Right
		} else {
			p.facing = dir.y < 0 ? .Up : .Down
		}
		p.walk_timer += dt
	} else {
		p.walk_timer = 0
	}
	p.throw_timer = max(p.throw_timer - dt, 0)

	b2.Body_SetLinearVelocity(p.body, config.to_metres(dir * SPEED))
}

player_feet :: proc(p: ^Player) -> rl.Vector2 {
	// the circle's centre sits a bit above the bottom of the sprite
	return physics.position(p.body) + {0, RADIUS - 1}
}

player_draw :: proc(p: ^Player) {
	row := 0
	if p.throw_timer > 0 {
		row = 4
	} else if p.moving {
		row = int(p.walk_timer / FRAME_TIME) % 4
	}
	src := rl.Rectangle{f32(int(p.facing)) * config.TILE, f32(row) * config.TILE, config.TILE, config.TILE}
	draw_standing({p.sheet, src}, player_feet(p))
}
