package entities

import rl "vendor:raylib"

// A picture: which texture, which rectangle of it.
Sprite :: struct {
	texture: rl.Texture2D,
	src:     rl.Rectangle,
}

// Draw a sprite standing on `feet` (bottom-centre), the way LDtk places
// things with pivot (0.5, 1). `flip` mirrors it left-right.
draw_standing :: proc(s: Sprite, feet: rl.Vector2, flip := false) {
	src := s.src
	if flip do src.width = -src.width
	dest := rl.Rectangle{feet.x - s.src.width / 2, feet.y - s.src.height, s.src.width, s.src.height}
	rl.DrawTexturePro(s.texture, src, dest, {0, 0}, 0, rl.WHITE)
}
