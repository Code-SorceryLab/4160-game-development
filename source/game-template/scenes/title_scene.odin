package scenes

// -----------------------------------------------------------------------------
// TITLE SCENE  --  a title, the hero's portrait, and a few raygui widgets
// that change config.music_on / config.music_volume for the game.
// (C++ template: scenes/TitleScene/TitleScene.cpp)
//
// raygui ships inside vendor:raylib: the widgets are rl.Gui* procs.
// They are "immediate mode": you call GuiButton every frame, and it both
// draws the button and returns true on the frame it is clicked.
// -----------------------------------------------------------------------------

import "../config"
import rl "vendor:raylib"

FACESET :: config.ART + "Actor/Character/NinjaGreen/Faceset.png"
FONT    :: config.ART + "Ui/Font/NormalFont.ttf"

Title_Scene :: struct {
	portrait: rl.Texture2D,
	font:     rl.Font,
}

title_load :: proc(s: ^Title_Scene) {
	s.portrait = rl.LoadTexture(config.asset_path(FACESET))
	// a pixel font stays sharp only at the size it was loaded at, with no smoothing
	s.font = rl.LoadFontEx(config.asset_path(FONT), 32, nil, 0)
	rl.SetTextureFilter(s.font.texture, .POINT)

	// The game is drawn at 1/SCREEN_SCALE size, so the mouse must be too,
	// or the widgets would react in the wrong place.
	rl.SetMouseScale(1.0 / config.SCREEN_SCALE, 1.0 / config.SCREEN_SCALE)
	rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), 10)
}

title_unload :: proc(s: ^Title_Scene) {
	rl.SetMouseScale(1, 1)
	rl.UnloadTexture(s.portrait)
	rl.UnloadFont(s.font)
	s^ = {}
}

title_tick :: proc(s: ^Title_Scene, dt: f32) -> Scene {
	next := Scene.None
	rl.ClearBackground({40, 44, 52, 255})

	rl.DrawTextEx(s.font, "Ninja Village", {20, 16}, 32, 1, rl.GOLD)
	rl.DrawText("Odin + raylib + LDtk + Box2D", 22, 50, 10, rl.LIGHTGRAY)

	// the portrait, 2.5 times bigger, nearest-neighbour so pixels stay sharp
	rl.DrawTextureEx(s.portrait, {220, 60}, 0, 2.5, rl.WHITE)

	if rl.GuiButton({20, 76, 120, 24}, "Start") do next = .Game
	rl.GuiCheckBox({20, 110, 12, 12}, "Music", &config.music_on)
	rl.GuiSliderBar({60, 130, 80, 12}, "Volume", nil, &config.music_volume, 0, 1)

	rl.DrawText("Art: Ninja Adventure by Pixel-boy & AAA (CC0)", 20, 160, 10, rl.GRAY)

	if rl.IsKeyPressed(.ENTER) do next = .Game
	return next
}
