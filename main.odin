package breakout

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1124
WINDOW_HEIGHT :: 820
WINDOW_COLOR :: rl.RAYWHITE

PADDLE_WIDTH :: 250
PADDLE_HEIGHT :: 50
PADDLE_SPEED :: 500
PADDLE_COLOR :: rl.GREEN

BALL_SIZE :: 75
BALL_SPEED :: 750
BALL_COLOR :: rl.RED

BRICK_WIDTH :: 150
BRICK_HEIGHT :: 50
BRICK_PADDING :: 10
BRICK_COLOR :: rl.BLUE
BRICK_COLS :: 6
BRICK_ROWS :: 6
BRICK_COUNT :: BRICK_ROWS * BRICK_COLS

float_to_signum :: proc(f: f32) -> f32 {
	if f < 0 {
		return -1
	} else if f > 0 {
		return 1
	} else {
		return 0
	}
}

vector_to_signum :: proc(p: rl.Vector2) -> rl.Vector2 {
	return {float_to_signum(p.x), float_to_signum(p.y)}
}

collision :: proc(a: ^rl.Rectangle, vel: ^rl.Vector2, b: ^rl.Rectangle) {
	col := rl.GetCollisionRec(a^, b^)
	if !rl.CheckCollisionRecs(a^, b^) {return}

	a_center := rl.Vector2{a.x + a.width / 2, a.y + a.height / 2}
	b_center := rl.Vector2{b.x + b.width / 2, b.y + b.height / 2}
	dir := b_center - a_center
	signum := vector_to_signum(dir)

	if col.width > col.height {
		a^.y -= signum.y * col.height
		vel.y = -signum.y * math.abs(vel.y)
	} else {
		a^.x -= signum.x * col.height
		vel.x = -signum.x * math.abs(vel.x)
	}
}

main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.VSYNC_HINT})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Breakout!!!!")
	defer rl.CloseWindow()

	player_rect := rl.Rectangle {
		(WINDOW_WIDTH / 2) - (PADDLE_WIDTH / 2),
		WINDOW_HEIGHT - 100,
		PADDLE_WIDTH,
		PADDLE_HEIGHT,
	}
	ball_rect := rl.Rectangle {
		(WINDOW_WIDTH / 2) - (BALL_SIZE / 2),
		(WINDOW_HEIGHT / 2) - (BALL_SIZE / 2) + BALL_SIZE,
		BALL_SIZE,
		BALL_SIZE,
	}
	ball_dir := rl.Vector2Normalize(rl.Vector2{rand.float32_range(-1, 1), 1})
	ball_vel := ball_dir * BALL_SPEED

	total_brick_size := rl.Vector2{BRICK_WIDTH, BRICK_HEIGHT} + BRICK_PADDING
	brick_spawn_point := rl.Vector2{(WINDOW_WIDTH - (total_brick_size.x * BRICK_ROWS)) / 2, 50}
	bricks := [dynamic]rl.Vector2{}
	for i in 0 ..< BRICK_COUNT {
		brick_pos :=
			brick_spawn_point +
			rl.Vector2 {
					(f32)(i % BRICK_ROWS) * total_brick_size.x,
					(f32)(i / BRICK_COLS) * total_brick_size.y,
				}
		append(&bricks, brick_pos)
	}

	for !rl.WindowShouldClose() {
		// UPDATE:
		delta := rl.GetFrameTime()

		move: f32 = 0
		if rl.IsKeyDown(.LEFT) {move -= 1}
		if rl.IsKeyDown(.RIGHT) {move += 1}

		player_rect.x += move * delta * PADDLE_SPEED
		if player_rect.x < 0 {
			player_rect.x = 0
		} else if player_rect.x > WINDOW_WIDTH - PADDLE_WIDTH {
			player_rect.x = WINDOW_WIDTH - PADDLE_WIDTH
		}

		ball_rect.x += ball_vel.x * delta
		ball_rect.y += ball_vel.y * delta
		if ball_rect.x < 0 {
			ball_rect.x = 0
			ball_vel.x *= -1
		} else if ball_rect.x > WINDOW_WIDTH - BALL_SIZE {
			ball_rect.x = WINDOW_WIDTH - BALL_SIZE
			ball_vel.x *= -1
		}
		if ball_rect.y < 0 {
			ball_rect.y = 0
			ball_vel.y *= -1
		}

		collision(&ball_rect, &ball_vel, &player_rect)

		// RENDER:
		rl.BeginDrawing()
		rl.ClearBackground(WINDOW_COLOR)

		for brick in bricks {
			rl.DrawRectangleV(brick, {BRICK_WIDTH, BRICK_HEIGHT}, BRICK_COLOR)
		}

		rl.DrawRectangleRec(ball_rect, BALL_COLOR)
		rl.DrawRectangleRec(player_rect, PADDLE_COLOR)

		rl.EndDrawing()
	}
}
