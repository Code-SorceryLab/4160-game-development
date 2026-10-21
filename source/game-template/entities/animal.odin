package entities

// -----------------------------------------------------------------------------
// Animals: chickens and pigs that wander. Each is a light round Box2D body,
// so the player can push them and a shuriken knocks them away.
//
// The sprite comes from LDtk (the entity's tile). The sheets in the pack are
// two 16x16 frames side by side, facing right; we flip them to walk left.
// -----------------------------------------------------------------------------

import "../physics"
import "core:math"
import "core:math/rand"
import b2 "vendor:box2d"
import rl "vendor:raylib"

ANIMAL_FRAME_TIME :: 0.25
ANIMAL_SPEED      :: 1.2 // metres per second while walking
SCARED_SPEED      :: 4.0 // ... and while running away

Animal :: struct {
	sprite:     Sprite, // frame 0; frame 1 is the next rectangle to the right
	body:       b2.BodyId,
	radius:     f32, // pixels
	think:      f32, // seconds until it picks a new direction
	heading:    rl.Vector2, // where it is walking; {0,0} = standing
	scared:     f32, // seconds left of running away
	anim_timer: f32,
}

// `footprint` is the LDtk entity's box, in pixels.
animal_spawn :: proc(world: b2.WorldId, sprite: Sprite, footprint: rl.Rectangle) -> Animal {
	radius := footprint.width / 2
	feet := rl.Vector2{footprint.x + radius, footprint.y + footprint.height - radius}
	body := physics.add_dynamic_circle(world, feet, radius, 1,
		physics.ANIMAL, physics.SOLID | physics.PLAYER | physics.ANIMAL | physics.SHURIKEN)
	b2.Body_SetLinearDamping(body, 3) // slides to a stop after a push
	return {sprite = sprite, body = body, radius = radius, think = rand.float32_range(0, 2)}
}

animal_update :: proc(a: ^Animal, dt: f32) {
	a.anim_timer += dt
	a.scared = max(a.scared - dt, 0)
	a.think -= dt
	if a.think <= 0 {
		a.think = rand.float32_range(1, 3)
		// half the time stand still, half the time walk somewhere
		a.heading = {}
		if rand.float32() < 0.5 {
			angle := rand.float32_range(0, 2 * math.PI)
			a.heading = {math.cos(angle), math.sin(angle)}
		}
	}

	speed: f32 = a.scared > 0 ? SCARED_SPEED : ANIMAL_SPEED
	if a.heading != {0, 0} {
		b2.Body_SetLinearVelocity(a.body, a.heading * speed)
	}
}

// Hit by something: run away from it for a second.
animal_scare :: proc(a: ^Animal, from: rl.Vector2) {
	away := physics.position(a.body) - from
	if away == {0, 0} do away = {1, 0}
	a.heading = rl.Vector2Normalize(away)
	a.scared = 1
	a.think = 1
}

animal_feet :: proc(a: ^Animal) -> rl.Vector2 {
	return physics.position(a.body) + {0, a.radius}
}

animal_draw :: proc(a: ^Animal) {
	vel := b2.Body_GetLinearVelocity(a.body)
	moving := abs(vel.x) + abs(vel.y) > 0.1
	s := a.sprite
	if moving do s.src.x += f32(int(a.anim_timer / ANIMAL_FRAME_TIME) % 2) * s.src.width
	draw_standing(s, animal_feet(a), flip = vel.x < -0.05)
}
