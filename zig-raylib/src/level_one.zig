const AppState = @import("app_state.zig").AppState;
const std = @import("std");

const c = @cImport({
    @cInclude("raylib.h");
});

gpa: std.mem.Allocator,
app_state: *AppState,
golf_ball: c.Vector2,
golf_ball_velocity: c.Vector2,
hole_pos: c.Vector2,
width: usize,
height: usize,
drag_start_pos: ?c.Vector2,
count: usize,

const GOLF_BALL_COLOR = c.GRAY;
const GOLF_BALL_RADIUS = 5;

const HOLE_COLOR = c.BLACK;
const HOLE_RADIUS = 3;

const Self = @This();

inline fn float32FromUsize(integer: usize) f32 {
    return @as(f32, @floatFromInt(integer));
}

pub fn init(gpa: std.mem.Allocator, app_state: *AppState, width: c_int, height: c_int) Self {
    return Self{
        .gpa = gpa,
        .app_state = app_state,
        .golf_ball = .{ .x = float32FromUsize(@intCast(width)) / 3, .y = float32FromUsize(@intCast(height)) / 2 },
        .hole_pos = .{ .x = (float32FromUsize(@intCast(width)) / 3) * 2, .y = float32FromUsize(@intCast(height)) / 2 },
        .width = @intCast(width),
        .height = @intCast(height),
        .golf_ball_velocity = .{ .x = 0, .y = 0 },
        .drag_start_pos = null,
        .count = 0,
    };
}

pub fn tick(self: *Self) void {
    // if there is resizing in the future
    self.width = @intCast(c.GetScreenWidth());
    self.height = @intCast(c.GetScreenHeight());

    if (doCircleCollideV(self.hole_pos, HOLE_RADIUS, self.golf_ball, GOLF_BALL_RADIUS)) {
        self.app_state.* = .choose;
        self.golf_ball = .{ .x = float32FromUsize(self.width) / 3, .y = float32FromUsize(self.height) / 2 };
        self.count = 0;
    }

    if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_LEFT)) {
        self.drag_start_pos = c.GetMousePosition();
    }

    if (c.IsMouseButtonReleased(c.MOUSE_BUTTON_LEFT)) {
        const mouse = c.GetMousePosition();
        if (self.drag_start_pos) |drag| {
            const v: c.Vector2 = .{ .x = drag.x - mouse.x, .y = drag.y - mouse.y };
            self.golf_ball_velocity = v;
            self.drag_start_pos = null;
            self.count += 1;
        }
    }
    self.wallCollision();
    self.updateBallPosition();
}

fn updateBallPosition(self: *Self) void {
    self.golf_ball_velocity.x *= 0.8;
    self.golf_ball_velocity.y *= 0.8;
    self.golf_ball.x += self.golf_ball_velocity.x;
    self.golf_ball.y += self.golf_ball_velocity.y;
}

fn doCircleCollideV(pos1: c.Vector2, radius1: f32, pos2: c.Vector2, radius2: f32) bool {
    const rad_squared = std.math.pow(f32, radius1 + radius2, 2);
    const length_squared = std.math.pow(f32, pos1.x - pos2.x, 2) + std.math.pow(f32, pos1.y - pos2.y, 2);
    return if (length_squared - rad_squared > 0) false else true;
}

fn wallCollision(self: *Self) void {
    if (self.golf_ball.x + GOLF_BALL_RADIUS >= @as(f32, @floatFromInt(self.width)) and self.golf_ball_velocity.x > 0) {
        self.golf_ball_velocity.x *= -1;
    }
    if (self.golf_ball.x - GOLF_BALL_RADIUS <= 0 and self.golf_ball_velocity.x < 0) {
        self.golf_ball_velocity.x *= -1;
    }
    if (self.golf_ball.y + GOLF_BALL_RADIUS >= @as(f32, @floatFromInt(self.height)) and self.golf_ball_velocity.y > 0) {
        self.golf_ball_velocity.y *= -1;
    }
    if (self.golf_ball.y - GOLF_BALL_RADIUS <= 0 and self.golf_ball_velocity.y < 0) {
        self.golf_ball_velocity.y *= -1;
    }
}

pub fn draw(self: Self) void {
    c.ClearBackground(c.RAYWHITE);
    self.drawEntities();
    self.drawCount();
}

fn drawCount(self: Self) void {
    c.DrawText(c.TextFormat("Count: %d", self.count), 10, 10, 10, c.BLACK);
}

fn drawEntities(self: Self) void {
    c.DrawCircleV(self.golf_ball, GOLF_BALL_RADIUS, GOLF_BALL_COLOR);
    c.DrawCircleV(self.hole_pos, HOLE_RADIUS, HOLE_COLOR);
}

pub fn deinit(self: *Self) void {
    _ = self;
}
