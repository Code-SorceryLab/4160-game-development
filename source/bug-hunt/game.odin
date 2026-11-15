package bughunt

// Game rules. Nothing in this file draws or reads the keyboard,
// so every procedure here can be called from a test.

import "core:math/rand"

COLS :: 30
ROWS :: 20

Vec :: [2]int

Difficulty :: enum {
	Easy,
	Hard,
}

Language :: enum {
	English,
	French,
}

Settings :: struct {
	difficulty: Difficulty,
	language:   Language,
	shake:      bool, // screen shake when the player is hit
	assist:     bool, // enemies move at half speed
}

Scene :: enum {
	Title,
	Settings,
	Playing,
	Game_Over,
	Win,
}

Enemy :: struct {
	pos: Vec,
	dir: int, // +1 right, -1 left: enemies patrol horizontally
}

Particle :: struct {
	pos, vel: [2]f32, // pixels, pixels per second
	life:     f32, // seconds left
}

Game :: struct {
	scene:      Scene,
	settings:   Settings,
	level:      int, // 1 or 2
	tiles:      [ROWS][COLS]u8,
	player:     Vec,
	facing:     Vec,
	health:     int,
	coins:      int,
	has_key:    bool,
	invuln:     f32, // seconds of invulnerability left after a hit
	dash_cool:  f32, // seconds until the next dash
	enemy_wait: f32, // seconds until enemies take their next step
	enemies:    [dynamic]Enemy,
	particles:  [dynamic]Particle,
	shake:      f32, // seconds of screen shake left
	menu:       int, // selected row in the title / settings menu
}

// ---------------------------------------------------------------- numbers

INVULN_TIME :: 1.0
DASH_TILES :: 3
DASH_COOLDOWN :: 0.8
MAX_PARTICLES :: 200

max_health :: proc(d: Difficulty) -> int {
	return d == .Easy ? 5 : 3
}

spike_damage :: proc(d: Difficulty) -> int {
	return d == .Easy ? 1 : 2
}

ENEMY_DAMAGE :: 1

// Seconds between enemy steps.
ENEMY_STEP_TIMES := [3]f32{0.40, 0.80, 0.25}

enemy_step_time :: proc(s: Settings) -> f32 {
	i := int(s.assist) + (s.difficulty == .Hard ? 2 : 0)
	return ENEMY_STEP_TIMES[i]
}

// ---------------------------------------------------------------- rules

apply_damage :: proc(health, damage: int) -> int {
	return health - damage
}

walkable :: proc(g: ^Game, p: Vec) -> bool {
	if p.x < 0 || p.y < 0 || p.x >= COLS || p.y >= ROWS do return false
	t := g.tiles[p.y][p.x]
	return t != '#' && t != 'D'
}

// Where a dash from `from` in direction `dir` ends.
dash_target :: proc(g: ^Game, from, dir: Vec) -> Vec {
	for d := DASH_TILES; d >= 1; d -= 1 {
		t := from + dir * d
		if walkable(g, t) do return t
	}
	return from
}

// Starts a brand-new game on level 1. Keeps the settings.
new_game :: proc(g: ^Game) {
	g.health = max_health(g.settings.difficulty)
	g.invuln = 0
	g.dash_cool = 0
	g.shake = 0
	clear(&g.particles)
	start_level(g, 1)
	g.scene = .Playing
}

// Loads level n: tiles, player start, enemies.
start_level :: proc(g: ^Game, n: int) {
	g.level = n
	g.coins = 0
	g.facing = {1, 0}
	g.enemy_wait = enemy_step_time(g.settings)
	clear(&g.enemies)
	rows := n == 1 ? LEVEL_1 : LEVEL_2
	for row, y in rows {
		for x in 0 ..< COLS {
			c := row[x]
			switch c {
			case 'P':
				g.player = {x, y}
				c = '.'
			case 'E':
				append(&g.enemies, Enemy{pos = {x, y}, dir = 1})
				c = '.'
			}
			g.tiles[y][x] = c
		}
	}
}

destroy_game :: proc(g: ^Game) {
	delete(g.enemies)
	delete(g.particles)
}

hurt :: proc(g: ^Game, damage: int) {
	if g.invuln > 0 do return
	g.health = apply_damage(g.health, damage)
	g.invuln = INVULN_TIME
	if g.settings.shake do g.shake = 0.25
	if g.health == 0 do g.scene = .Game_Over
}

// One step of the player: a walk of 1 tile, or a dash.
move_player :: proc(g: ^Game, dir: Vec, dash: bool) {
	g.facing = dir
	target := g.player + dir
	if dash {
		if g.dash_cool > 0 do return
		target = dash_target(g, g.player, dir)
		g.dash_cool = DASH_COOLDOWN
	}
	// Bumping into the door with the key opens it (and uses the key).
	if g.tiles[target.y][target.x] == 'D' && g.has_key {
		g.tiles[target.y][target.x] = '.'
		g.has_key = false
	}
	if !walkable(g, target) do return
	g.player = target
	spawn_dust(g)
	enter_tile(g)
}

// What happens when the player arrives on a tile.
enter_tile :: proc(g: ^Game) {
	p := g.player
	switch g.tiles[p.y][p.x] {
	case 'C':
		g.coins += 1
		g.tiles[p.y][p.x] = '.'
	case 'K':
		g.has_key = true
		g.tiles[p.y][p.x] = '.'
	case '^':
		hurt(g, spike_damage(g.settings.difficulty))
	case 'S':
		if g.level == 1 {
			start_level(g, 2)
		} else {
			g.scene = .Win
		}
	}
	for e in g.enemies {
		if e.pos == g.player do hurt(g, ENEMY_DAMAGE)
	}
}

// Enemies walk left and right and turn around at walls.
step_enemies :: proc(g: ^Game) {
	for &e in g.enemies {
		next := e.pos + {e.dir, 0}
		if !walkable(g, next) {
			e.dir = -e.dir
			next = e.pos + {e.dir, 0}
		}
		if walkable(g, next) do e.pos = next
		if e.pos == g.player do hurt(g, ENEMY_DAMAGE)
	}
}

// Timers and enemies; called once per frame while playing.
update_world :: proc(g: ^Game, dt: f32) {
	g.invuln = max(g.invuln - dt, 0)
	g.dash_cool = max(g.dash_cool - dt, 0)
	g.shake = max(g.shake - dt, 0)
	g.enemy_wait -= dt
	if g.enemy_wait <= 0 {
		step_enemies(g)
		g.enemy_wait = enemy_step_time(g.settings)
	}
	// Standing on spikes keeps hurting (once per second, see INVULN_TIME).
	if g.tiles[g.player.y][g.player.x] == '^' do hurt(g, spike_damage(g.settings.difficulty))
	update_particles(g, dt)
}

// ---------------------------------------------------------------- particles

TILE :: 32 // pixels; also used by the drawing code

spawn_dust :: proc(g: ^Game) {
	c := [2]f32{f32(g.player.x * TILE + TILE / 2), f32(g.player.y * TILE + TILE - 4)}
	for _ in 0 ..< 4 {
		v := [2]f32{rand.float32_range(-40, 40), rand.float32_range(-30, -5)}
		append(&g.particles, Particle{pos = c, vel = v, life = 0.5})
	}
}

update_particles :: proc(g: ^Game, dt: f32) {
	for &p in g.particles {
		p.life -= dt
		p.pos += p.vel * dt
	}
}

alive_particles :: proc(g: ^Game) -> int {
	return len(g.particles)
}
