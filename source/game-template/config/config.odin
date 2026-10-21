package config

// -----------------------------------------------------------------------------
// The numbers every other folder reads. (C++ template: Constants.hpp)
// No other package is imported here, so anyone can import this one.
// -----------------------------------------------------------------------------

import "core:fmt"
import rl "vendor:raylib"

WINDOW_TITLE :: "game-template"

// The game is drawn at WORLD_W x WORLD_H pixels (what the camera sees),
// then scaled up to the window. 320 x 180 = 20 x 11.25 tiles of 16 px.
WORLD_W      :: 320
WORLD_H      :: 180
SCREEN_SCALE :: 4
SCREEN_W     :: WORLD_W * SCREEN_SCALE
SCREEN_H     :: WORLD_H * SCREEN_SCALE

TILE :: 16 // LDtk grid and sprite size, in pixels

// Box2D works in metres. One tile = one metre.
PIXELS_PER_METRE :: 16.0

// Settings the title screen changes and the game reads.
music_on     := true
music_volume: f32 = 0.5

// Where assets/ is: "odin run ." from this folder, or "odin run source/game-template"
// from the repository root. Set once by find_assets, read by asset_path.
assets_dir := "assets"

find_assets :: proc() {
	for dir in ([]string{"assets", "source/game-template/assets"}) {
		if rl.DirectoryExists(fmt.ctprintf("%s", dir)) {
			assets_dir = dir
			return
		}
	}
	fmt.eprintln("assets/ folder not found; run from game-template/ or the repository root")
}

// "world.ldtk" -> "assets/world.ldtk", as a C string for raylib.
// Lives in the temp allocator: use it right away, do not keep it.
asset_path :: proc(name: string) -> cstring {
	return fmt.ctprintf("%s/%s", assets_dir, name)
}

// The art pack lives in its own folder under assets/.
ART :: "ninja-adventure/"

to_metres :: proc(p: rl.Vector2) -> rl.Vector2 {return p / PIXELS_PER_METRE}
to_pixels :: proc(p: rl.Vector2) -> rl.Vector2 {return p * PIXELS_PER_METRE}
