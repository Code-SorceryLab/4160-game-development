package entities

// -----------------------------------------------------------------------------
// Shurikens: thrown with SPACE, they fly, bounce off houses and trees, knock
// animals away, and disappear in a puff of smoke after LIFETIME seconds.
//
// They live in a #soa[dynamic] array: the update loop below
// only reads `life` and `spin`, and with #soa those sit in their own arrays.
// A dead one is swap-removed, so the array has no holes.
// -----------------------------------------------------------------------------

import "../config"
import "../physics"
import b2 "vendor:box2d"
import rl "vendor:raylib"

SHURIKEN_IMAGE :: config.ART + "Items/Projectile/Shuriken.png"
SMOKE_SHEET    :: config.ART + "FX/Smoke/Smoke/SpriteSheet.png" // 6 frames of 32x32

THROW_SPEED     :: 12.0 // metres per second
LIFETIME        :: 1.2 // seconds
SHURIKEN_RADIUS :: 3.0 // pixels
SMOKE_TIME      :: 0.4 // seconds for the whole puff

Shuriken :: struct {
	body: b2.BodyId,
	life: f32, // seconds left
	spin: f32, // degrees, only for drawing
}

Puff :: struct {
	pos: rl.Vector2,
	age: f32,
}

throw_shuriken :: proc(list: ^#soa[dynamic]Shuriken, world: b2.WorldId, from: rl.Vector2, dir: rl.Vector2) {
	body := physics.add_dynamic_circle(world, from, SHURIKEN_RADIUS, 0.5,
		physics.SHURIKEN, physics.SOLID | physics.ANIMAL)
	b2.Body_SetBullet(body, true) // fast and small: check the whole path, not just the end
	shapes: [1]b2.ShapeId
	for shape in b2.Body_GetShapes(body, shapes[:]) {
		b2.Shape_SetRestitution(shape, 0.8) // bouncy
		b2.Shape_SetFriction(shape, 0)
		b2.Shape_EnableContactEvents(shape, true) // off by default: we want to hear about hits
	}
	b2.Body_SetLinearVelocity(body, dir * THROW_SPEED)
	append_soa(list, Shuriken{body = body, life = LIFETIME})
}

// Age them; the old ones become smoke.
update_shurikens :: proc(list: ^#soa[dynamic]Shuriken, puffs: ^[dynamic]Puff, dt: f32) {
	for i := len(list) - 1; i >= 0; i -= 1 {
		list[i].life -= dt
		list[i].spin += 900 * dt
		if list[i].life <= 0 {
			append(puffs, Puff{pos = physics.position(list[i].body)})
			b2.DestroyBody(list[i].body)
			unordered_remove_soa(list, i) // the last one moves into the hole
		}
	}
}

update_puffs :: proc(puffs: ^[dynamic]Puff, dt: f32) {
	for i := len(puffs) - 1; i >= 0; i -= 1 {
		puffs[i].age += dt
		if puffs[i].age >= SMOKE_TIME do unordered_remove(puffs, i)
	}
}

draw_shuriken :: proc(tex: rl.Texture2D, s: Shuriken) {
	pos := physics.position(s.body)
	size := f32(tex.width)
	// drawn a little above its shadow-less body so it looks thrown, not slid
	dest := rl.Rectangle{pos.x, pos.y - 4, size, size}
	rl.DrawTexturePro(tex, {0, 0, size, size}, dest, {size / 2, size / 2}, s.spin, rl.WHITE)
}

draw_puff :: proc(tex: rl.Texture2D, p: Puff) {
	frame := min(int(p.age / SMOKE_TIME * 6), 5)
	src := rl.Rectangle{f32(frame) * 32, 0, 32, 32}
	rl.DrawTextureRec(tex, src, p.pos - {16, 20}, rl.WHITE)
}
