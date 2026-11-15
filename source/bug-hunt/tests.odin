package bughunt

// Tests. Run them all with:   odin test .
// Add your regression tests (Part C) at the bottom of this file.

import "core:testing"

@(test)
damage_lowers_health :: proc(t: ^testing.T) {
	testing.expect_value(t, apply_damage(5, 1), 4)
	testing.expect_value(t, apply_damage(3, 0), 3)
}

@(test)
new_game_starts_on_level_1_with_full_health :: proc(t: ^testing.T) {
	g: Game
	defer destroy_game(&g)
	g.settings.difficulty = .Easy
	new_game(&g)
	testing.expect_value(t, g.level, 1)
	testing.expect_value(t, g.health, 5)
	testing.expect_value(t, g.scene, Scene.Playing)
}

@(test)
walls_block_walking :: proc(t: ^testing.T) {
	g: Game
	defer destroy_game(&g)
	new_game(&g)
	start := g.player // (1, 1): the wall is on the left
	move_player(&g, {-1, 0}, false)
	testing.expect_value(t, g.player, start)
}

// ---- Part C: your regression tests go here ----
