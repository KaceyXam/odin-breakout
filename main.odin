package breakout

import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(1280, 720, "Breakout!!!!")
	defer rl.CloseWindow()

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		rl.ClearBackground(rl.RAYWHITE)

		rl.DrawText("Hello World", 10, 10, 30, rl.BLACK)

		rl.EndDrawing()
	}
}
