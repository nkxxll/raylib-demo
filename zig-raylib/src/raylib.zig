const c = @cImport({
    @cInclude("raylib.h");
});

pub const Vector2 = c.Vector2;

pub fn Vector2LengthSquared(self: Vector2) f32 {
    return self.x * self.x + self.y * self.y;
}

pub const Rectangle = c.Rectangle;
pub const Color = c.Color;
pub const MouseButton = c.MouseButton;

pub const BLACK = c.BLACK;
pub const BLUE = c.BLUE;
pub const GRAY = c.GRAY;
pub const GREEN = c.GREEN;
pub const MAGENTA = c.MAGENTA;
pub const PURPLE = c.PURPLE;
pub const RAYWHITE = c.RAYWHITE;
pub const RED = c.RED;
pub const WHITE = c.WHITE;

pub const MOUSE_BUTTON_LEFT = c.MOUSE_BUTTON_LEFT;

pub const BeginDrawing = c.BeginDrawing;
pub const ClearBackground = c.ClearBackground;
pub const CloseWindow = c.CloseWindow;
pub const DrawCircleV = c.DrawCircleV;
pub const DrawLineV = c.DrawLineV;
pub const DrawRectangleV = c.DrawRectangleV;
pub const EndDrawing = c.EndDrawing;
pub const GetMousePosition = c.GetMousePosition;
pub const IsMouseButtonPressed = c.IsMouseButtonPressed;
pub const IsMouseButtonReleased = c.IsMouseButtonReleased;
pub const TextFormat = c.TextFormat;
pub const WindowShouldClose = c.WindowShouldClose;
pub const GetFPS = c.GetFPS;
pub const CheckCollisionCircles = c.CheckCollisionCircles;

pub fn DrawText(text: [*:0]const u8, pos_x: i32, pos_y: i32, font_size: i32, color: Color) void {
    c.DrawText(text, @intCast(pos_x), @intCast(pos_y), @intCast(font_size), color);
}

pub fn Vector2Add(first: Vector2, second: Vector2) Vector2 {
    return Vector2{ .x = first.x + second.x, .y = first.y + second.y };
}

pub fn CheckCollisionCircleRec(center: Vector2, radius: f32, rec: Rectangle) bool {
    return c.CheckCollisionCircleRec(center, radius, rec);
}

pub fn GetMouseX() i32 {
    return @intCast(c.GetMouseX());
}

pub fn GetMouseY() i32 {
    return @intCast(c.GetMouseY());
}

pub fn GetScreenHeight() i32 {
    return @intCast(c.GetScreenHeight());
}

pub fn GetScreenWidth() i32 {
    return @intCast(c.GetScreenWidth());
}

pub fn InitWindow(width: i32, height: i32, title: [*c]const u8) void {
    c.InitWindow(@intCast(width), @intCast(height), title);
}

pub fn SetTargetFPS(fps: i32) void {
    c.SetTargetFPS(@intCast(fps));
}
