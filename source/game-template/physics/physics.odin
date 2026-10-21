package physics

// -----------------------------------------------------------------------------
// Box2D helpers shared by scenes/ and entities/.
// (C++ template: physics/PhysicsTypes.hpp, physics/RaycastUtils.hpp, the
//  debug drawing in utils/DebugUtils.hpp)
// -----------------------------------------------------------------------------

import "../config"
import b2 "vendor:box2d"
import rl "vendor:raylib"

// What a shape IS, as collision category bits. The C++ template tagged bodies
// with a string ("SOLID_BLOCK"); Box2D 3 has a bit mask for exactly this.
SOLID    :: u64(1 << 0) // houses, trees, rocks, water, the level's edges
PLAYER   :: u64(1 << 1)
ANIMAL   :: u64(1 << 2)
SHURIKEN :: u64(1 << 3)

// A static box from a rectangle in PIXELS (top-left + size), the way LDtk gives it.
add_solid_box :: proc(world: b2.WorldId, rect: rl.Rectangle) -> b2.BodyId {
	half := config.to_metres({rect.width, rect.height}) / 2
	body_def := b2.DefaultBodyDef() // static: never moves
	body_def.position = config.to_metres({rect.x, rect.y}) + half
	body := b2.CreateBody(world, body_def)

	shape_def := b2.DefaultShapeDef()
	shape_def.filter.categoryBits = SOLID
	_ = b2.CreatePolygonShape(body, shape_def, b2.MakeBox(half.x, half.y))
	return body
}

// A moving round body. `at` is in PIXELS, the radius too.
// `collides_with` lists the categories it bumps into.
add_dynamic_circle :: proc(world: b2.WorldId, at: rl.Vector2, radius: f32, density: f32,
	category, collides_with: u64) -> b2.BodyId {
	body_def := b2.DefaultBodyDef()
	body_def.type = .dynamicBody
	body_def.fixedRotation = true // top-down: nothing should spin
	body_def.position = config.to_metres(at)
	body := b2.CreateBody(world, body_def)

	shape_def := b2.DefaultShapeDef()
	shape_def.density = density
	shape_def.filter.categoryBits = category
	shape_def.filter.maskBits = collides_with
	_ = b2.CreateCircleShape(body, shape_def, {radius = radius / config.PIXELS_PER_METRE})
	return body
}

// Body position in pixels.
position :: proc(body: b2.BodyId) -> rl.Vector2 {
	return config.to_pixels(b2.Body_GetPosition(body))
}

// Whose shape is it? The category bits answer that.
category_of :: proc(shape: b2.ShapeId) -> u64 {
	return b2.Shape_GetFilter(shape).categoryBits
}

// F1 view: every box and circle, and every body's centre.
draw_debug :: proc(world: b2.WorldId, bodies: []b2.BodyId) {
	shapes: [8]b2.ShapeId
	for body in bodies {
		if !b2.Body_IsValid(body) do continue
		pos := b2.Body_GetPosition(body)
		rl.DrawCircleV(config.to_pixels(pos), 1, rl.PURPLE)

		for shape in b2.Body_GetShapes(body, shapes[:]) {
			#partial switch b2.Shape_GetType(shape) {
			case .polygonShape:
				poly := b2.Shape_GetPolygon(shape)
				n := int(poly.count)
				for i in 0 ..< n {
					a := config.to_pixels(pos + poly.vertices[i])
					b := config.to_pixels(pos + poly.vertices[(i + 1) % n])
					rl.DrawLineV(a, b, rl.GREEN)
				}
			case .circleShape:
				circle := b2.Shape_GetCircle(shape)
				rl.DrawCircleLinesV(config.to_pixels(pos), circle.radius * config.PIXELS_PER_METRE, rl.YELLOW)
			}
		}
	}
}
