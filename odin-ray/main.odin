#+feature dynamic-literals
package main

import "core:fmt"
import "vendor:raylib"

circleColor :: raylib.BLUE
radius :: 20
width :: 800
height :: 400
circleCenterX :: width / 2
circleCenterY :: height / 2

main :: proc() {

    vec := [2]f32{circleCenterX, circleCenterY}
    circles := [dynamic]raylib.Vector2{vec}
    velocities := [dynamic]raylib.Vector2{{3, 2}}
    defer delete(circles)
    defer delete(velocities)

    raylib.InitWindow(width, height, "Hello world")
    raylib.SetTargetFPS(60)
    for (!raylib.WindowShouldClose())    // Detect window close button or ESC key
    {
        onClick(&circles, &velocities)
        detectColision(circles, velocities)
        raylib.BeginDrawing()
        raylib.ClearBackground(raylib.RAYWHITE)
        drawCircles(circles, circleColor)
        raylib.EndDrawing()
    }
}

onClick :: proc(circles: ^[dynamic]raylib.Vector2, velocities: ^[dynamic]raylib.Vector2) {
    if (raylib.IsMouseButtonPressed(raylib.MouseButton.LEFT)) {
        append(circles, [2]f32{cast(f32)raylib.GetMouseX(), cast(f32)raylib.GetMouseY()})
        append(velocities, [2]f32{3, 2})
    }
}

drawCircles :: proc(circles: [dynamic]raylib.Vector2, color: raylib.Color) {
    for circle in circles {
        raylib.DrawCircleV(circle, radius, circleColor)
    }
}

detectColision :: proc(circles: [dynamic]raylib.Vector2, velocities: [dynamic]raylib.Vector2) {
    for &circle, index in circles {
        velocity := &velocities[index]
        if circle[0] > (width - radius) || circle[0] < radius {
            velocity[0] = -velocity[0]
            circle[0] = (circle[0] + velocity[0])
        } else {
            circle[0] = (circle[0] + velocity[0])
        }
        if circle[1] > (height - radius) || circle[1] < radius {
            velocity[1] = -velocity[1]
            circle[1] = (circle[1] + velocity[1])
        } else {
            circle[1] = (circle[1] + velocity[1])
        }
    }
}
