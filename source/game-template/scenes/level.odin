package scenes

// -----------------------------------------------------------------------------
// LEVEL  --  read one level of assets/world.ldtk, keep only what the game needs.
// (C++ template: the LDtkLoader library + GameScene::set_selected_level)
//
// Same two sets of types as source/swords:
//   Ldtk_*  mirrors LDtk's JSON (the AUTHORING format)
//   Level   is what the game uses (the RUNTIME format)
//
// The layers of world.ldtk (top first, as LDtk lists them):
//   Entities  everything placed by hand. Each one's TAGS decide what it is:
//               "solid"  -> a static Box2D box under it (house, tree, rock)
//               "animal" -> a moving Box2D body (chicken, pig)
//               no tag   -> just a picture (bush, flower)
//             plus PlayerStart and Portal (field level_destination).
//             The entity's SIZE is its footprint, the part that collides;
//             its TILE is the picture, standing on the footprint.
//   Water     IntGrid, 1 = water. LDtk's auto-rules turn the cells into lake
//             tiles; we turn the same cells into Box2D boxes.
//   Ground    painted grass tiles.
// -----------------------------------------------------------------------------

import "../config"
import "../entities"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:slice"
import rl "vendor:raylib"

WORLD_FILE :: "world.ldtk"

// --- authoring format: only the fields we read; json.unmarshal skips the rest.

Ldtk_Project :: struct {
	defs:   struct {
		tilesets: []Ldtk_Tileset,
	},
	levels: []Ldtk_Level,
}

Ldtk_Tileset :: struct {
	uid:      int,
	rel_path: string `json:"relPath"`, // relative to world.ldtk
}

Ldtk_Level :: struct {
	identifier: string,
	width:      int `json:"pxWid"`,
	height:     int `json:"pxHei"`,
	layers:     []Ldtk_Layer `json:"layerInstances"`, // TOP layer first
}

Ldtk_Layer :: struct {
	identifier: string `json:"__identifier"`,
	cols:       int `json:"__cWid"`,
	rows:       int `json:"__cHei"`,
	grid:       int `json:"__gridSize"`,
	tileset:    string `json:"__tilesetRelPath"`,
	int_grid:   []int `json:"intGridCsv"`, // IntGrid layers: one value per cell, row by row
	tiles:      []Ldtk_Tile `json:"gridTiles"`, // painted tiles
	auto_tiles: []Ldtk_Tile `json:"autoLayerTiles"`, // tiles made by auto-rules
	entities:   []Ldtk_Entity `json:"entityInstances"`,
}

Ldtk_Tile :: struct {
	px:  [2]f32, // where it goes
	src: [2]f32, // which rectangle of the tileset
	f:   int, // flip bits: 1 = mirror x, 2 = mirror y
}

Ldtk_Entity :: struct {
	identifier: string `json:"__identifier"`,
	px:         [2]f32, // the pivot point
	pivot:      [2]f32 `json:"__pivot"`, // (0.5, 1) = bottom-centre
	width:      f32,
	height:     f32,
	tags:       []string `json:"__tags"`,
	tile:       Ldtk_Tile_Rect `json:"__tile"`, // null in the file (all zero here) when there is no picture
	fields:     []Ldtk_Field `json:"fieldInstances"`,
}

Ldtk_Tile_Rect :: struct {
	tileset:    int `json:"tilesetUid"`,
	x, y, w, h: f32,
}

Ldtk_Field :: struct {
	identifier: string `json:"__identifier"`,
	value:      json.Value `json:"__value"`, // any type: we check it when we read it
}

// --- runtime format

Thing_Kind :: enum {
	Decor, // a picture, nothing else
	Solid, // a picture + a static box
	Animal, // a picture + a moving body
	Player_Start,
	Portal,
}

Thing :: struct {
	kind:        Thing_Kind,
	footprint:   rl.Rectangle, // pixels: the part that collides
	sprite:      entities.Sprite, // empty for PlayerStart and Portal
	destination: int, // Portal only: level index
}

// A tile ready to draw.
Tile :: struct {
	src: rl.Rectangle, // negative size = flipped
	pos: rl.Vector2,
}

Tile_Layer :: struct {
	tileset: rl.Texture2D,
	tiles:   [dynamic]Tile,
}

Level :: struct {
	index:    int,
	size:     rl.Vector2, // pixels
	layers:   [dynamic]Tile_Layer, // bottom layer first: draw in this order
	things:   [dynamic]Thing,
	water:    [dynamic]rl.Rectangle, // pixels: rows of water cells, for Box2D
	textures: map[string]rl.Texture2D, // every texture this level loaded, by path
}

load_level :: proc(index: int) -> (lv: Level, ok: bool) {
	data, err := os.read_entire_file_from_path(string(config.asset_path(WORLD_FILE)), context.temp_allocator)
	if err != nil {
		fmt.eprintln("missing level file:", WORLD_FILE)
		return
	}
	project: Ldtk_Project
	if err := json.unmarshal(data, &project, allocator = context.temp_allocator); err != nil {
		fmt.eprintln("bad level file:", err)
		return
	}
	if index < 0 || index >= len(project.levels) do return
	src := project.levels[index]
	fmt.printfln("level %d (%s): %dx%d px", index, src.identifier, src.width, src.height)
	lv.index = index
	lv.size = {f32(src.width), f32(src.height)}

	// LDtk lists layers top-first; walk it backwards to get draw order.
	#reverse for layer in src.layers {
		switch layer.identifier {
		case "Water":
			read_water(&lv, layer)
		case "Entities":
			for e in layer.entities do read_entity(&lv, e, project.defs.tilesets[:])
		}
		if layer.tileset == "" do continue
		tl := Tile_Layer{tileset = texture(&lv, layer.tileset)}
		size := f32(layer.grid)
		for t in layer.auto_tiles do append(&tl.tiles, make_tile(t, size))
		for t in layer.tiles do append(&tl.tiles, make_tile(t, size))
		append(&lv.layers, tl)
	}
	return lv, true
}

// Each row of water cells becomes one rectangle: fewer Box2D bodies than one per cell.
// The lake tiles have a grassy shore drawn inside the outer cells, so the
// rectangle is pulled in by SHORE pixels on every side that faces land.
SHORE :: 6

read_water :: proc(lv: ^Level, layer: Ldtk_Layer) {
	size := f32(layer.grid)
	is_water := proc(layer: Ldtk_Layer, col, row: int) -> bool {
		if col < 0 || row < 0 || col >= layer.cols || row >= layer.rows do return false
		return layer.int_grid[row * layer.cols + col] == 1
	}
	for row in 0 ..< layer.rows {
		col := 0
		for col < layer.cols {
			if !is_water(layer, col, row) {
				col += 1
				continue
			}
			start := col
			for is_water(layer, col, row) do col += 1
			r := rl.Rectangle{f32(start) * size + SHORE, f32(row) * size, f32(col - start) * size - 2 * SHORE, size}
			if !is_water(layer, start, row - 1) { r.y += SHORE; r.height -= SHORE } // land above
			if !is_water(layer, start, row + 1) do r.height -= SHORE / 2 // land below
			append(&lv.water, r)
		}
	}
}

read_entity :: proc(lv: ^Level, e: Ldtk_Entity, tilesets: []Ldtk_Tileset) {
	t: Thing
	// the footprint: the entity's box, placed by its pivot
	t.footprint = {e.px.x - e.pivot.x * e.width, e.px.y - e.pivot.y * e.height, e.width, e.height}

	switch {
	case e.identifier == "PlayerStart":
		t.kind = .Player_Start
	case e.identifier == "Portal":
		t.kind = .Portal
		t.destination = field_int(e, "level_destination")
	case slice.contains(e.tags, "solid"):
		t.kind = .Solid
	case slice.contains(e.tags, "animal"):
		t.kind = .Animal
	case:
		t.kind = .Decor
	}

	if e.tile.w > 0 {
		for ts in tilesets {
			if ts.uid == e.tile.tileset do t.sprite.texture = texture(lv, ts.rel_path)
		}
		t.sprite.src = {e.tile.x, e.tile.y, e.tile.w, e.tile.h}
	}
	append(&lv.things, t)
}

// Load a texture once per level, however many things use it.
texture :: proc(lv: ^Level, rel_path: string) -> rl.Texture2D {
	if tex, found := lv.textures[rel_path]; found do return tex
	tex := rl.LoadTexture(config.asset_path(rel_path))
	// the path string lives in temporary memory: the map needs its own copy
	lv.textures[fmt.aprint(rel_path)] = tex
	return tex
}

make_tile :: proc(t: Ldtk_Tile, size: f32) -> Tile {
	return {
		src = {t.src.x, t.src.y, (t.f & 1 != 0) ? -size : size, (t.f & 2 != 0) ? -size : size},
		pos = t.px,
	}
}

// An integer field of an entity; -1 if it is missing or not a number.
field_int :: proc(e: Ldtk_Entity, name: string) -> int {
	for f in e.fields {
		if f.identifier != name do continue
		#partial switch v in f.value {
		case json.Integer:
			return int(v)
		case json.Float:
			return int(v)
		}
	}
	return -1
}

unload_level :: proc(lv: ^Level) {
	for path, tex in lv.textures {
		rl.UnloadTexture(tex)
		delete(path)
	}
	delete(lv.textures)
	for &tl in lv.layers do delete(tl.tiles)
	delete(lv.layers)
	delete(lv.things)
	delete(lv.water)
	lv^ = {}
}

// The ground and the water: everything that is flat, so it is drawn first.
draw_tiles :: proc(lv: ^Level) {
	for tl in lv.layers {
		for t in tl.tiles do rl.DrawTextureRec(tl.tileset, t.src, t.pos, rl.WHITE)
	}
}
