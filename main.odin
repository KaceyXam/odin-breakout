package breakout

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1124
WINDOW_HEIGHT :: 820
WINDOW_COLOR :: rl.RAYWHITE

PADDLE_WIDTH :: 150
PADDLE_HEIGHT :: 10
PADDLE_SPEED :: 500
PADDLE_COLOR :: rl.GREEN

BALL_SIZE :: 25
BALL_SPEED :: 500
BALL_COLOR :: rl.RED

BRICK_WIDTH :: 50
BRICK_HEIGHT :: 20
BRICK_PADDING :: 2
BRICK_COLOR :: rl.BLUE
BRICK_COLS :: 16
BRICK_ROWS :: 18
BRICK_COUNT :: BRICK_ROWS * BRICK_COLS
BRICK_SCORE :: 100

GameState :: enum {
	Menu,
	Game,
	Won,
	Dead,
}

State :: struct {
	player:     rl.Rectangle,
	ball:       rl.Rectangle,
	ball_vel:   rl.Vector2,
	bricks:     [dynamic]rl.Rectangle,
	game_state: GameState,
	score:      int,
}

global_state: State

reset_state :: proc(state: ^State) {
	state.player = rl.Rectangle {
		(WINDOW_WIDTH / 2) - (PADDLE_WIDTH / 2),
		WINDOW_HEIGHT - PADDLE_HEIGHT * 2,
		PADDLE_WIDTH,
		PADDLE_HEIGHT,
	}
	state.ball = rl.Rectangle {
		(WINDOW_WIDTH / 2) - (BALL_SIZE / 2),
		(WINDOW_HEIGHT / 2) - (BALL_SIZE / 2) + BALL_SIZE,
		BALL_SIZE,
		BALL_SIZE,
	}
	ball_dir := rl.Vector2Normalize(rl.Vector2{rand.float32_range(-1, 1), 1})
	state.ball_vel = ball_dir * BALL_SPEED

	total_brick_size := rl.Vector2{BRICK_WIDTH, BRICK_HEIGHT} + BRICK_PADDING
	brick_spawn_point := rl.Vector2{(WINDOW_WIDTH - (total_brick_size.x * BRICK_ROWS)) / 2, 50}
	state.bricks = [dynamic]rl.Rectangle{}
	for i in 0 ..< BRICK_COUNT {
		brick_pos :=
			brick_spawn_point +
			rl.Vector2 {
					(f32)(i % BRICK_ROWS) * total_brick_size.x,
					(f32)(i / BRICK_ROWS) * total_brick_size.y,
				}
		append(&state.bricks, rl.Rectangle{brick_pos.x, brick_pos.y, BRICK_WIDTH, BRICK_HEIGHT})
	}

	state.score = 0
}

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

collision :: proc(a: ^rl.Rectangle, vel: ^rl.Vector2, b: ^rl.Rectangle) -> bool {
	col := rl.GetCollisionRec(a^, b^)
	if !rl.CheckCollisionRecs(a^, b^) {return false}

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

	return true
}

update :: proc() {
	using global_state
	switch game_state {
	case .Menu:
		if rl.IsKeyPressed(.SPACE) {game_state = .Game}
	case .Won, .Dead:
		if rl.IsKeyPressed(.SPACE) {
			reset_state(&global_state)
			game_state = .Menu
		}
	case .Game:
		delta := rl.GetFrameTime()

		move: f32 = 0
		if rl.IsKeyDown(.LEFT) {move -= 1}
		if rl.IsKeyDown(.RIGHT) {move += 1}

		player.x += move * delta * PADDLE_SPEED
		if player.x < 0 {
			player.x = 0
		} else if player.x > WINDOW_WIDTH - PADDLE_WIDTH {
			player.x = WINDOW_WIDTH - PADDLE_WIDTH
		}

		ball.x += ball_vel.x * delta
		ball.y += ball_vel.y * delta
		if ball.x < 0 {
			ball.x = 0
			ball_vel.x *= -1
		} else if ball.x > WINDOW_WIDTH - BALL_SIZE {
			ball.x = WINDOW_WIDTH - BALL_SIZE
			ball_vel.x *= -1
		}
		if ball.y < 0 {
			ball.y = 0
			ball_vel.y *= -1
		}
		if ball.y > WINDOW_HEIGHT {
			game_state = .Dead
		}

		collision(&ball, &ball_vel, &player)

		for &brick, i in bricks {
			if collision(&ball, &ball_vel, &brick) {
				unordered_remove(&bricks, i)
				score += BRICK_SCORE
			}
		}

		if len(bricks) <= 0 {
			game_state = .Won
		}
	}
}

render :: proc() {
	using global_state

	rl.BeginDrawing()
	rl.ClearBackground(WINDOW_COLOR)

	for brick in bricks {
		rl.DrawRectangleRec(brick, BRICK_COLOR)
	}

	rl.DrawRectangleRounded(ball, 50, 50, BALL_COLOR)
	rl.DrawRectangleRounded(player, 50, 50, PADDLE_COLOR)

	score_str := fmt.caprintf("Score: %d", score)
	score_width := rl.MeasureText(score_str, 20)
	score_pos := [2]i32{(WINDOW_WIDTH / 2 - score_width / 2), 10}
	rl.DrawText(score_str, score_pos.x, score_pos.y, 20, rl.BLACK)

	if game_state == .Menu {
		menu_text: cstring = "Breakout!"
		menu_width := rl.MeasureText(menu_text, 70)
		rl.DrawText(
			menu_text,
			WINDOW_WIDTH / 2 - menu_width / 2,
			WINDOW_HEIGHT - 300,
			70,
			rl.BLACK,
		)

		menu_text = "Press space to begin"
		menu_width = rl.MeasureText(menu_text, 40)
		rl.DrawText(
			menu_text,
			WINDOW_WIDTH / 2 - menu_width / 2,
			WINDOW_HEIGHT - 200,
			40,
			rl.BLACK,
		)
	}

	if game_state == .Won || game_state == .Dead {
		score_str := fmt.caprintf("Score: %d", score)
		score_width := rl.MeasureText(score_str, 70)
		score_pos := [2]i32{(WINDOW_WIDTH / 2 - score_width / 2), WINDOW_HEIGHT - 300}
		rl.DrawText(score_str, score_pos.x, score_pos.y, 70, rl.BLACK)
	}

	rl.EndDrawing()
}

main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.VSYNC_HINT})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Breakout!!!!")
	defer rl.CloseWindow()

	reset_state(&global_state)

	game_state := GameState.Menu

	for !rl.WindowShouldClose() {
		update()

		render()
	}
}
