const c = @cImport({
    @cInclude("raylib.h");
});

pub const Vec2 = c.Vector2;
pub const Vector2 = c.Vector2;
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

pub fn DrawText(text: [*:0]const u8, pos_x: i32, pos_y: i32, font_size: i32, color: Color) void {
    c.DrawText(text, @intCast(pos_x), @intCast(pos_y), @intCast(font_size), color);
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

pub fn InitWindow(width: i32, height: i32, title: [*:0]const u8) void {
    c.InitWindow(@intCast(width), @intCast(height), title);
}

pub fn SetTargetFPS(fps: i32) void {
    c.SetTargetFPS(@intCast(fps));
}
