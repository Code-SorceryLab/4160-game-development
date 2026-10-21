package main

// -----------------------------------------------------------------------------
// game-template  --  Odin + raylib + LDtk + Box2D, in the folder layout of
// tupini07/raylib-cpp-cmake-template, with the Ninja Adventure art (CC0).
//
// Run:   odin run .                        (from this folder)
//        odin run source/game-template     (from the repository root)
// Keys:  title: mouse or ENTER   game: WASD/arrows, SPACE throw, F1 debug,
//        ESC back to the title   Q quit
//
// Linux only, once: Odin does not ship a compiled Box2D for Linux. Run
//   <your odin folder>/vendor/box2d/build_box2d.sh      (needs cmake)
//
// This file only opens the window and runs the loop. The game is drawn into a
// small WORLD_W x WORLD_H texture, then that texture is stretched over the
// window, so all game code thinks in game pixels whatever the window size.
// (C++ template: main.cpp)
// -----------------------------------------------------------------------------

import "config"
import "scenes"
import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(config.SCREEN_W, config.SCREEN_H, config.WINDOW_TITLE)
	defer rl.CloseWindow()
	rl.InitAudioDevice()
	defer rl.CloseAudioDevice()
	rl.SetTargetFPS(60)
	rl.SetExitKey(.Q) // ESC goes back to the title instead of quitting

	config.find_assets()
	rl.GuiLoadStyleDefault()

	canvas := rl.LoadRenderTexture(config.WORLD_W, config.WORLD_H)
	defer rl.UnloadRenderTexture(canvas)

	scenes.set_scene(.Title)
	defer scenes.unload_current()

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		// 1. the scene updates and draws itself into the small canvas
		rl.BeginTextureMode(canvas)
		scenes.tick(dt)
		rl.EndTextureMode()

		// 2. the canvas is stretched over the whole window
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		src := rl.Rectangle{0, 0, config.WORLD_W, -config.WORLD_H} // negative: render textures are upside down
		dst := rl.Rectangle{0, 0, config.SCREEN_W, config.SCREEN_H}
		rl.DrawTexturePro(canvas.texture, src, dst, {0, 0}, 0, rl.WHITE)
		rl.EndDrawing()

		free_all(context.temp_allocator) // everything ctprintf/tprintf/temp lists made this frame
	}
}
