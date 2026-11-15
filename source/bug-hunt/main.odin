package bughunt

// Bug Hunt: a small top-down game with a design document (SPEC.md).
// main.odin reads the keyboard and draws. The rules are in game.odin.

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

HUD_H :: 64
SCREEN_W :: COLS * TILE
SCREEN_H :: ROWS * TILE + HUD_H

main :: proc() {
	rl.InitWindow(SCREEN_W, SCREEN_H, "Bug Hunt")
	defer rl.CloseWindow()
	rl.SetExitKey(.KEY_NULL) // ESC is used by the game
	rl.SetTargetFPS(60)

	g: Game
	defer destroy_game(&g)

	for !rl.WindowShouldClose() {
		if !update(&g, rl.GetFrameTime()) do break
		rl.BeginDrawing()
		draw(&g)
		rl.EndDrawing()
	}
}

// Returns false when the player chooses Quit.
update :: proc(g: ^Game, dt: f32) -> bool {
	switch g.scene {
	case .Title:
		items := 3
		if pressed(.UP, .W) do g.menu = (g.menu + items - 1) % items
		if pressed(.DOWN, .S) do g.menu = (g.menu + 1) % items
		if rl.IsKeyPressed(.ENTER) {
			switch g.menu {
			case 0:
				new_game(g)
			case 1:
				g.scene = .Settings
				g.menu = 0
			case 2:
				return false
			}
		}
	case .Settings:
		rows := 5
		if pressed(.UP, .W) do g.menu = (g.menu + rows - 1) % rows
		if pressed(.DOWN, .S) do g.menu = (g.menu + 1) % rows
		change := pressed(.LEFT, .A) || pressed(.RIGHT, .D) || rl.IsKeyPressed(.ENTER)
		if change {
			s := &g.settings
			switch g.menu {
			case 0:
				s.difficulty = s.difficulty == .Easy ? .Hard : .Easy
			case 1:
				s.language = s.language == .English ? .French : .English
			case 2:
				s.shake = !s.shake
			case 3:
				s.assist = !s.assist
			case 4:
				if rl.IsKeyPressed(.ENTER) {g.scene = .Title; g.menu = 1}
			}
		}
		if rl.IsKeyPressed(.ESCAPE) {g.scene = .Title; g.menu = 1}
	case .Playing:
		dash := rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT)
		if pressed(.UP, .W) do move_player(g, {0, -1}, dash)
		else if pressed(.DOWN, .S) do move_player(g, {0, 1}, dash)
		else if pressed(.LEFT, .A) do move_player(g, {-1, 0}, dash)
		else if pressed(.RIGHT, .D) do move_player(g, {1, 0}, dash)
		if g.scene == .Playing do update_world(g, dt)
		if rl.IsKeyPressed(.ESCAPE) {g.scene = .Title; g.menu = 0}
	case .Game_Over, .Win:
		if rl.IsKeyPressed(.ENTER) {g.scene = .Title; g.menu = 0}
	}
	if rl.IsKeyPressed(.F3) do show_debug = !show_debug
	return true
}

show_debug := false

// A key press, or the key held down long enough to repeat.
pressed :: proc(a, b: rl.KeyboardKey) -> bool {
	return rl.IsKeyPressed(a) || rl.IsKeyPressedRepeat(a) || rl.IsKeyPressed(b) || rl.IsKeyPressedRepeat(b)
}

// ---------------------------------------------------------------- drawing

INK :: rl.Color{30, 34, 44, 255}
PAPER :: rl.Color{236, 232, 220, 255}

draw :: proc(g: ^Game) {
	rl.ClearBackground(PAPER)
	switch g.scene {
	case .Title:
		center_text("BUG HUNT", 150, 64, INK)
		items := [3]Text{.Play, .Settings, .Quit}
		for t, i in items {
			col := i == g.menu ? rl.MAROON : INK
			label := i == g.menu ? fmt.ctprintf("> %s <", tr(g, t)) : fmt.ctprintf("%s", tr(g, t))
			center_text(label, 300 + i32(i) * 50, 32, col)
		}
	case .Settings:
		draw_settings(g)
	case .Playing:
		draw_world(g)
	case .Game_Over:
		draw_world(g)
		rl.DrawRectangle(0, 0, SCREEN_W, SCREEN_H, {0, 0, 0, 150})
		center_text(fmt.ctprintf("%s", tr(g, .Game_Over)), 280, 56, rl.WHITE)
		center_text(fmt.ctprintf("%s", tr(g, .Press_Enter)), 360, 24, rl.WHITE)
	case .Win:
		center_text(fmt.ctprintf("%s", tr(g, .You_Win)), 240, 56, INK)
		center_text(fmt.ctprintf("%s: %d / %d", tr(g, .Coins), g.coins, COINS_TOTAL), 320, 32, INK)
		center_text(fmt.ctprintf("%s", tr(g, .Press_Enter)), 400, 24, INK)
	}
	if show_debug {
		rl.DrawRectangle(SCREEN_W - 220, HUD_H + 8, 212, 56, {0, 0, 0, 170})
		rl.DrawText(fmt.ctprintf("FPS: %d", rl.GetFPS()), SCREEN_W - 210, HUD_H + 14, 20, rl.GREEN)
		rl.DrawText(fmt.ctprintf("particles: %d", alive_particles(g)), SCREEN_W - 210, HUD_H + 38, 20, rl.GREEN)
	}
}

draw_settings :: proc(g: ^Game) {
	s := g.settings
	on_off :: proc(g: ^Game, b: bool) -> string {return tr(g, b ? .On : .Off)}
	rows := [5]cstring {
		fmt.ctprintf("%s: %s", tr(g, .Difficulty), tr(g, s.difficulty == .Easy ? .Easy : .Hard)),
		fmt.ctprintf("%s: %s", tr(g, .Language), tr(g, .Language_Name)),
		fmt.ctprintf("%s: %s", tr(g, .Shake), on_off(g, s.shake)),
		fmt.ctprintf("%s: %s", tr(g, .Assist), on_off(g, s.assist)),
		fmt.ctprintf("%s", tr(g, .Back)),
	}
	center_text(fmt.ctprintf("%s", tr(g, .Settings)), 120, 48, INK)
	box := rl.Rectangle{SCREEN_W / 2 - 180, 210, 360, 290}
	rl.DrawRectangleRec(box, rl.RAYWHITE)
	rl.DrawRectangleLinesEx(box, 3, INK)
	for r, i in rows {
		col := i == g.menu ? rl.MAROON : INK
		y := i32(box.y) + 30 + i32(i) * 50
		rl.DrawText(r, i32(box.x) + 24, y, 28, col)
		if i == g.menu do rl.DrawText(">", i32(box.x) + 6, y, 28, col)
	}
	center_text("UP/DOWN, LEFT/RIGHT, ENTER", 560, 20, rl.GRAY)
}

draw_world :: proc(g: ^Game) {
	off := [2]f32{0, HUD_H}
	if g.shake > 0 do off += {rand.float32_range(-5, 5), rand.float32_range(-5, 5)}
	ox, oy := i32(off.x), i32(off.y)

	for y in 0 ..< ROWS {
		for x in 0 ..< COLS {
			px, py := ox + i32(x * TILE), oy + i32(y * TILE)
			c := g.tiles[y][x]
			rl.DrawRectangle(px, py, TILE, TILE, c == '#' ? INK : PAPER)
			switch c {
			case 'C':
				rl.DrawCircle(px + TILE / 2, py + TILE / 2, 7, rl.GOLD)
			case 'K':
				rl.DrawCircle(px + 11, py + TILE / 2, 6, rl.ORANGE)
				rl.DrawRectangle(px + 15, py + TILE / 2 - 2, 12, 4, rl.ORANGE)
			case 'D':
				rl.DrawRectangle(px + 2, py, TILE - 4, TILE, rl.BROWN)
				rl.DrawRectangle(px + TILE / 2 - 3, py + TILE / 2 - 3, 6, 6, rl.GOLD)
			case '^':
				for k in 0 ..< i32(3) {
					bx := f32(px + 2 + k * 10)
					rl.DrawTriangle({bx + 5, f32(py + 6)}, {bx, f32(py + 26)}, {bx + 10, f32(py + 26)}, rl.RED)
				}
			case 'S':
				rl.DrawRectangle(px + 4, py + 4, TILE - 8, TILE - 8, rl.DARKGREEN)
			}
		}
	}
	for p in g.particles {
		if p.life > 0 do rl.DrawCircleV(p.pos + off, 2, rl.Fade(rl.GRAY, p.life * 2))
	}
	for e in g.enemies {
		rl.DrawRectangle(ox + i32(e.pos.x * TILE) + 4, oy + i32(e.pos.y * TILE) + 4, TILE - 8, TILE - 8, rl.RED)
	}
	blink := g.invuln > 0 && int(g.invuln * 10) % 2 == 0
	if !blink {
		rl.DrawRectangle(ox + i32(g.player.x * TILE) + 4, oy + i32(g.player.y * TILE) + 4, TILE - 8, TILE - 8, rl.BLUE)
	}
	draw_hud(g)
}

draw_hud :: proc(g: ^Game) {
	rl.DrawRectangle(0, 0, SCREEN_W, HUD_H, INK)
	hp := fmt.ctprintf("%s: %d / %d", tr(g, .Health), g.health, max_health(g.settings.difficulty))
	rl.DrawText(hp, 20, 20, 24, rl.RAYWHITE)
	rl.DrawText(fmt.ctprintf("Coins: %d / %d", g.coins, COINS_TOTAL), 300, 20, 24, rl.GOLD)
	if g.has_key do rl.DrawText(fmt.ctprintf("%s", tr(g, .Key)), 560, 20, 24, rl.ORANGE)
	rl.DrawText(fmt.ctprintf("%s %d", tr(g, .Level), g.level), SCREEN_W - 140, 20, 24, rl.RAYWHITE)
}

center_text :: proc(text: cstring, y, size: i32, col: rl.Color) {
	w := rl.MeasureText(text, size)
	rl.DrawText(text, SCREEN_W / 2 - w / 2, y, size, col)
}
