package scenes

// -----------------------------------------------------------------------------
// GAME SCENE  --  an LDtk level, a Box2D world built from it, the player,
// animals and shurikens, a camera that follows, music and sounds.
// (C++ template: scenes/GameScene/GameScene.cpp)
//
// Keys: WASD / arrows move, SPACE throw a shuriken, F1 debug view.
// Walk through the gap in the trees (a Portal, magenta in F1) to change level.
//
// Who does what:
//   LDtk    where everything is (level.odin reads it)
//   Box2D   what may overlap: nothing walks through houses, trees or water,
//           animals get pushed, shurikens bounce
//   raylib  pictures, camera, sound
//   Odin    the glue: structs, arrays, procs
// -----------------------------------------------------------------------------

import "../config"
import "../entities"
import "../physics"
import "core:slice"
import b2 "vendor:box2d"
import rl "vendor:raylib"

STEP      :: 1.0 / 60.0 // fixed physics step (Chapter 10)
SUB_STEPS :: 4

MUSIC       :: config.ART + "Audio/Musics/36 - Village.ogg"
THROW_SOUND :: config.ART + "Audio/Sounds/Whoosh & Slash/Whoosh.wav"
HIT_SOUND   :: config.ART + "Audio/Sounds/Hit & Impact/Hit1.wav"

Game_Scene :: struct {
	level:       Level,
	world:       b2.WorldId,
	bodies:      [dynamic]b2.BodyId, // every static body we made, for the debug view
	player:      entities.Player,
	animals:     [dynamic]entities.Animal,
	shurikens:   #soa[dynamic]entities.Shuriken,
	puffs:       [dynamic]entities.Puff,
	camera:      rl.Camera2D,
	accumulator: f32,
	debug:       bool,

	// loaded once for the whole scene
	shuriken_tex: rl.Texture2D,
	smoke_tex:    rl.Texture2D,
	music:        rl.Music,
	throw_sound:  rl.Sound,
	hit_sound:    rl.Sound,
}

game_load :: proc(s: ^Game_Scene) {
	entities.player_load(&s.player)
	s.shuriken_tex = rl.LoadTexture(config.asset_path(entities.SHURIKEN_IMAGE))
	s.smoke_tex = rl.LoadTexture(config.asset_path(entities.SMOKE_SHEET))
	s.music = rl.LoadMusicStream(config.asset_path(MUSIC))
	s.throw_sound = rl.LoadSound(config.asset_path(THROW_SOUND))
	s.hit_sound = rl.LoadSound(config.asset_path(HIT_SOUND))
	rl.SetMusicVolume(s.music, config.music_volume)
	if config.music_on do rl.PlayMusicStream(s.music)

	s.camera.zoom = 1
	s.camera.offset = {config.WORLD_W / 2, config.WORLD_H / 2} // the target sits in the middle of the view
	game_set_level(s, 0)
}

game_unload :: proc(s: ^Game_Scene) {
	unload_level(&s.level)
	if b2.World_IsValid(s.world) do b2.DestroyWorld(s.world)
	delete(s.bodies)
	delete(s.animals)
	delete_soa(s.shurikens)
	delete(s.puffs)
	entities.player_unload(&s.player)
	rl.UnloadTexture(s.shuriken_tex)
	rl.UnloadTexture(s.smoke_tex)
	rl.UnloadMusicStream(s.music)
	rl.UnloadSound(s.throw_sound)
	rl.UnloadSound(s.hit_sound)
	s^ = {}
}

// Throw away the old level and its world; build the new ones from LDtk.
game_set_level :: proc(s: ^Game_Scene, index: int) {
	unload_level(&s.level)
	if b2.World_IsValid(s.world) do b2.DestroyWorld(s.world) // destroys every body in it
	clear(&s.bodies)
	clear(&s.animals)
	clear_soa(&s.shurikens)
	clear(&s.puffs)
	s.accumulator = 0

	lv, ok := load_level(index)
	if !ok do return
	s.level = lv

	def := b2.DefaultWorldDef()
	def.gravity = {0, 0} // seen from above: nothing falls
	s.world = b2.CreateWorld(def)

	// the edges of the level are walls
	W, H := s.level.size.x, s.level.size.y
	for wall in ([]rl.Rectangle{{-16, -16, W + 32, 16}, {-16, H, W + 32, 16}, {-16, 0, 16, H}, {W, 0, 16, H}}) {
		append(&s.bodies, physics.add_solid_box(s.world, wall))
	}
	for rect in s.level.water {
		append(&s.bodies, physics.add_solid_box(s.world, rect))
	}
	for t in s.level.things {
		#partial switch t.kind {
		case .Solid:
			append(&s.bodies, physics.add_solid_box(s.world, t.footprint))
		case .Animal:
			append(&s.animals, entities.animal_spawn(s.world, t.sprite, t.footprint))
		case .Player_Start:
			feet := rl.Vector2{t.footprint.x + t.footprint.width / 2, t.footprint.y + t.footprint.height}
			entities.player_spawn(&s.player, s.world, feet)
		}
	}
}

game_tick :: proc(s: ^Game_Scene, dt: f32) -> Scene {
	if !b2.World_IsValid(s.world) do return .Title // the level failed to load (see the console)
	if rl.IsKeyPressed(.F1) do s.debug = !s.debug
	if rl.IsKeyPressed(.ESCAPE) do return .Title
	rl.UpdateMusicStream(s.music) // keeps the music playing: call it every frame

	// --- update: input and AI set velocities ...
	entities.player_update(&s.player, dt)
	for &a in s.animals do entities.animal_update(&a, dt)

	if rl.IsKeyPressed(.SPACE) {
		dir := entities.FACING_VECTOR[s.player.facing]
		from := physics.position(s.player.body) + dir * 8
		entities.throw_shuriken(&s.shurikens, s.world, from, dir)
		s.player.throw_timer = entities.THROW_POSE
		rl.PlaySound(s.throw_sound)
	}

	// ... then Box2D moves everything, at a fixed step
	s.accumulator += min(dt, 0.25)
	for s.accumulator >= STEP {
		b2.World_Step(s.world, STEP, SUB_STEPS)
		s.accumulator -= STEP
	}

	// Box2D tells us what started touching during the step
	events := b2.World_GetContactEvents(s.world)
	for e in events.beginEvents[:events.beginCount] {
		on_touch(s, e.shapeIdA, e.shapeIdB)
	}

	entities.update_shurikens(&s.shurikens, &s.puffs, dt)
	entities.update_puffs(&s.puffs, dt)

	// touching a portal? (a plain rectangle test, no Box2D needed)
	feet := entities.player_feet(&s.player)
	for t in s.level.things {
		if t.kind == .Portal && rl.CheckCollisionPointRec(feet, t.footprint) && t.destination >= 0 {
			game_set_level(s, t.destination)
			return .None
		}
	}

	// --- draw
	follow(&s.camera, physics.position(s.player.body), s.level.size)
	rl.ClearBackground(rl.BLACK)
	rl.BeginMode2D(s.camera)
	draw_tiles(&s.level)
	draw_sorted(s)
	for p in s.puffs do entities.draw_puff(s.smoke_tex, p)
	if s.debug do draw_debug(s)
	rl.EndMode2D()

	rl.DrawText("WASD move  SPACE throw  F1 debug  ESC title", 4, config.WORLD_H - 12, 10, rl.WHITE)
	return .None
}

// Two shapes started touching. Was it a shuriken hitting an animal?
on_touch :: proc(s: ^Game_Scene, a, b: b2.ShapeId) {
	star, other := a, b
	if physics.category_of(star) != physics.SHURIKEN do star, other = b, a
	if physics.category_of(star) != physics.SHURIKEN do return
	if physics.category_of(other) != physics.ANIMAL do return

	hit := b2.Shape_GetBody(other)
	for &animal in s.animals {
		if animal.body == hit {
			entities.animal_scare(&animal, physics.position(b2.Shape_GetBody(star)))
			rl.PlaySound(s.hit_sound)
		}
	}
}

// Keep the player in the middle of the view, but never show outside the level.
follow :: proc(cam: ^rl.Camera2D, target: rl.Vector2, level_size: rl.Vector2) {
	half := rl.Vector2{config.WORLD_W, config.WORLD_H} / 2
	cam.target = target
	for i in 0 ..< 2 {
		if level_size[i] <= half[i] * 2 {
			cam.target[i] = level_size[i] / 2 // level smaller than the view: centre it
		} else {
			cam.target[i] = clamp(cam.target[i], half[i], level_size[i] - half[i])
		}
	}
	// whole pixels, or the pixel art shimmers as the camera moves
	cam.target = {f32(int(cam.target.x)), f32(int(cam.target.y))}
}

// Everything that stands up is drawn back to front: whatever's feet are
// lower on screen is in front. The list lives in temporary memory, rebuilt
// every frame and thrown away by free_all in main.
Draw_Item :: struct {
	feet_y: f32,
	kind:   enum {Thing, Player, Animal, Shuriken},
	index:  int,
}

draw_sorted :: proc(s: ^Game_Scene) {
	items := make([dynamic]Draw_Item, context.temp_allocator)
	for t, i in s.level.things {
		if t.kind != .Decor && t.kind != .Solid do continue // animals draw themselves; start and portals are invisible
		append(&items, Draw_Item{t.footprint.y + t.footprint.height, .Thing, i})
	}
	for _, i in s.animals do append(&items, Draw_Item{entities.animal_feet(&s.animals[i]).y, .Animal, i})
	for i in 0 ..< len(s.shurikens) do append(&items, Draw_Item{physics.position(s.shurikens[i].body).y, .Shuriken, i})
	append(&items, Draw_Item{entities.player_feet(&s.player).y, .Player, 0})

	slice.sort_by(items[:], proc(a, b: Draw_Item) -> bool {return a.feet_y < b.feet_y})

	for it in items {
		switch it.kind {
		case .Thing:
			t := s.level.things[it.index]
			feet := rl.Vector2{t.footprint.x + t.footprint.width / 2, t.footprint.y + t.footprint.height}
			entities.draw_standing(t.sprite, feet)
		case .Animal:
			entities.animal_draw(&s.animals[it.index])
		case .Shuriken:
			entities.draw_shuriken(s.shuriken_tex, s.shurikens[it.index])
		case .Player:
			entities.player_draw(&s.player)
		}
	}
}

draw_debug :: proc(s: ^Game_Scene) {
	physics.draw_debug(s.world, s.bodies[:])
	moving := make([dynamic]b2.BodyId, context.temp_allocator)
	append(&moving, s.player.body)
	for a in s.animals do append(&moving, a.body)
	for i in 0 ..< len(s.shurikens) do append(&moving, s.shurikens[i].body)
	physics.draw_debug(s.world, moving[:])
	for t in s.level.things {
		if t.kind == .Portal do rl.DrawRectangleLinesEx(t.footprint, 1, rl.MAGENTA)
	}
}
