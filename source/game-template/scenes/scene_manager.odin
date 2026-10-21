package scenes

// -----------------------------------------------------------------------------
// SCENE MANAGER  --  which scene is running, and switching between them.
// (C++ template: scenes/SceneManager.hpp, Scenes.hpp, BaseScene.hpp)
//
// Every scene has three procs:
//   <name>_load    set it up        (C++: the constructor)
//   <name>_tick    update + draw    returns the scene to switch to, or .None
//   <name>_unload  free everything  (C++: the destructor)
// The switch statements below are the only place that lists all scenes.
// To add one: a value in Scene, a struct, its three procs, three `case` lines.
// -----------------------------------------------------------------------------

Scene :: enum {
	None, // "stay where you are" -- a tick returns this almost every frame
	Title,
	Game,
}

current: Scene
title:   Title_Scene
game:    Game_Scene

set_scene :: proc(next: Scene) {
	if next == .None do return
	unload_current()
	current = next
	switch current {
	case .None:
	case .Title: title_load(&title)
	case .Game:  game_load(&game)
	}
}

tick :: proc(dt: f32) {
	next: Scene
	switch current {
	case .None:
	case .Title: next = title_tick(&title, dt)
	case .Game:  next = game_tick(&game, dt)
	}
	set_scene(next) // does nothing when next is .None
}

unload_current :: proc() {
	switch current {
	case .None:
	case .Title: title_unload(&title)
	case .Game:  game_unload(&game)
	}
	current = .None
}
