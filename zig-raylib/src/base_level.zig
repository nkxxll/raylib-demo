const AppState = @import("app_state.zig").AppState;
const LevelParser = @import("level_parser.zig");
const std = @import("std");
const WormHoles = @import("level_parser.zig").WormHoles;

const rl = @import("raylib.zig");

gpa: std.mem.Allocator,
app_state: *AppState,
ball_start: rl.Vector2,
golf_ball: rl.Vector2,
golf_ball_velocity: rl.Vector2,
hole_pos: rl.Vector2,
width: i32,
height: i32,
drag_start_pos: ?rl.Vector2,
count: usize,
golf_radius: f32,
hole_radius: f32,
obstacles: []rl.Vector2,
cell_width: f32,
cell_height: f32,
worm_holes: ?WormHoles,
worm_hole_radius: f32,
worm_hole_jump: bool,

const GOLF_BALL_COLOR = rl.GRAY;
const SAMPLE_SIZE = 10.0;
const WORM_HOLE_COLOR = rl.PURPLE;

const HOLE_COLOR = rl.BLUE;

const Self = @This();

pub fn init(
    gpa: std.mem.Allocator,
    io: std.Io,
    app_state: *AppState,
    width: i32,
    height: i32,
    file_name: []const u8,
) Self {
    const lp: LevelParser = LevelParser.init(gpa, io, width, height, file_name);
    const cell_width = LevelParser.cellWidth(width);
    const level = lp.parseLevel() catch |err| {
        switch (err) {
            error.NoBallFound => @panic("The level input is malformed because there was no ball found!"),
            error.NoHoleFound => @panic("The level input is malformed because there was no hole found!"),
            else => @panic("parseFile paniced"),
        }
    };
    return Self{
        .gpa = gpa,
        .app_state = app_state,
        .cell_height = LevelParser.cellHeight(height),
        .cell_width = cell_width,
        .golf_ball = level.ball,
        .ball_start = level.ball,
        .golf_radius = cell_width / 2 - 4,
        .hole_pos = level.hole,
        .hole_radius = cell_width / 2 - 4,
        .width = width,
        .height = height,
        .golf_ball_velocity = .{ .x = 0, .y = 0 },
        .drag_start_pos = null,
        .obstacles = level.obstacles,
        .count = 0,
        .worm_holes = level.worm_holes,
        .worm_hole_radius = cell_width / 2 - 4,
        .worm_hole_jump = false,
    };
}

pub fn tick(self: *Self) void {
    self.beginTick();
    const speed = std.math.sqrt(self.golf_ball_velocity.x * self.golf_ball_velocity.x + self.golf_ball_velocity.y * self.golf_ball_velocity.y);
    if (speed > SAMPLE_SIZE) {
        const steps: usize = @ceil(speed / SAMPLE_SIZE);
        var velocity = rl.Vector2{ .x = self.golf_ball_velocity.x / @as(f32, @floatFromInt(steps)), .y = self.golf_ball_velocity.y / @as(f32, @floatFromInt(steps)) };
        for (0..steps) |_| {
            velocity = self.tickSubstep(velocity);
        }
        self.updatePrefix(velocity);
        self.endTick();
    } else {
        self.beginTick();
        self.golf_ball_velocity = self.tickSubstep(self.golf_ball_velocity);
        self.endTick();
    }
}

fn updatePrefix(self: *Self, velocity: rl.Vector2) void {
    if ((self.golf_ball_velocity.x > 0 and velocity.x < 0) or (self.golf_ball_velocity.x < 0 and velocity.x > 0)) {
        self.golf_ball_velocity.x *= -1;
    }
    if ((self.golf_ball_velocity.y > 0 and velocity.y < 0) or (self.golf_ball_velocity.y < 0 and velocity.y > 0)) {
        self.golf_ball_velocity.y *= -1;
    }
}

fn obstacleCollision(self: *Self, velocity: rl.Vector2) rl.Vector2 {
    var v = velocity;
    for (self.obstacles) |obst| {
        const rect = rl.Rectangle{
            .x = obst.x,
            .y = obst.y,
            .width = self.cell_width,
            .height = self.cell_height,
        };
        if (rl.CheckCollisionCircleRec(self.golf_ball, self.golf_radius, rect)) {
            const ball = &self.golf_ball;

            const rect_center: rl.Vector2 = .{
                .x = rect.x + rect.width / 2.0,
                .y = rect.y + rect.height / 2.0,
            };
            const dx = ball.x - rect_center.x;
            const dy = ball.y - rect_center.y;
            const overlap_x = rect.width / 2.0 + self.golf_radius - @abs(dx);
            const overlap_y = rect.height / 2.0 + self.golf_radius - @abs(dy);

            if (overlap_x < overlap_y) {
                const direction: f32 = if (dx < 0.0) -1.0 else 1.0;
                ball.x += overlap_x * direction;
                if (v.x * direction < 0.0) {
                    v.x = -v.x;
                }
            } else {
                const direction: f32 = if (dy < 0.0) -1.0 else 1.0;
                ball.y += overlap_y * direction;
                if (v.y * direction < 0.0) {
                    v.y = -v.y;
                }
            }
        }
    }
    return v;
}

pub fn beginTick(self: *Self) void {
    // if there is resizing in the future
    self.width = @intCast(rl.GetScreenWidth());
    self.height = @intCast(rl.GetScreenHeight());
    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
        self.drag_start_pos = rl.GetMousePosition();
    }

    if (rl.IsMouseButtonReleased(rl.MOUSE_BUTTON_LEFT)) {
        const mouse = rl.GetMousePosition();
        if (self.drag_start_pos) |drag| {
            const v: rl.Vector2 = .{ .x = drag.x - mouse.x, .y = drag.y - mouse.y };
            self.golf_ball_velocity = v;
            self.drag_start_pos = null;
            self.count += 1;
        }
    }
}

pub fn tickSubstep(self: *Self, velocity: rl.Vector2) rl.Vector2 {
    var v = velocity;
    self.updateBallPosition(v);
    self.wormHoleJump(v);
    v = self.wallCollision(v);
    v = self.obstacleCollision(v);
    return v;
}

fn wormHoleJump(self: *Self, velocity: rl.Vector2) void {
    if (self.worm_holes) |wh| {
        if (!self.worm_hole_jump) {
            if (rl.CheckCollisionCircles(self.golf_ball, self.golf_radius, wh.entry, self.worm_hole_radius)) {
                self.golf_ball = rl.Vector2Add(wh.exit, velocity);
                self.worm_hole_jump = true;
            }
            if (rl.CheckCollisionCircles(self.golf_ball, self.golf_radius, wh.exit, self.worm_hole_radius)) {
                self.golf_ball = rl.Vector2Add(wh.entry, velocity);
                self.worm_hole_jump = true;
            }
        } else if (!rl.CheckCollisionCircles(self.golf_ball, self.golf_radius, wh.exit, self.worm_hole_radius) and self.worm_hole_jump){
            self.worm_hole_jump = false;
        }
    }
}

pub fn endTick(self: *Self) void {
    self.golf_ball_velocity.x *= 0.8;
    self.golf_ball_velocity.y *= 0.8;
    if (doCircleCollideV(self.hole_pos, self.hole_radius, self.golf_ball, self.golf_radius)) {
        self.app_state.* = .choose;
        self.golf_ball = self.ball_start;
        self.count = 0;
    }
}

fn updateBallPosition(self: *Self, velocity: rl.Vector2) void {
    self.golf_ball.x += velocity.x;
    self.golf_ball.y += velocity.y;
}

fn doCircleCollideV(pos1: rl.Vector2, radius1: f32, pos2: rl.Vector2, radius2: f32) bool {
    const rad_squared = std.math.pow(f32, radius1 + radius2, 2);
    const length_squared = std.math.pow(f32, pos1.x - pos2.x, 2) + std.math.pow(f32, pos1.y - pos2.y, 2);
    return if (length_squared - rad_squared > 0) false else true;
}

// todo: the collision logic needs to be fixed a bit here haha need to see where the ball is going to go
// then I have to update the next position of the ball
fn wallCollision(self: *Self, velocity: rl.Vector2) rl.Vector2 {
    var v = velocity;
    if (self.golf_ball.x + self.golf_radius >= @as(f32, @floatFromInt(self.width)) and v.x > 0) {
        v.x *= -1;
    }
    if (self.golf_ball.x - self.golf_radius <= 0 and v.x < 0) {
        v.x *= -1;
    }
    if (self.golf_ball.y + self.golf_radius >= @as(f32, @floatFromInt(self.height)) and v.y > 0) {
        v.y *= -1;
    }
    if (self.golf_ball.y - self.golf_radius <= 0 and v.y < 0) {
        v.y *= -1;
    }
    return v;
}

pub fn draw(self: *const Self) void {
    rl.ClearBackground(rl.RAYWHITE);
    self.drawEntities();
    self.drawCount();
    Self.drawFPS();
    self.drawObstacles();
    self.drawWormHoles();
}

fn drawWormHoles(self: *const Self) void {
    if (self.worm_holes) |wh| {
        rl.DrawCircleV(wh.entry, self.worm_hole_radius, WORM_HOLE_COLOR);
        rl.DrawCircleV(wh.exit, self.worm_hole_radius, WORM_HOLE_COLOR);
    }
}

fn drawObstacles(self: *const Self) void {
    for (self.obstacles) |obstacle| {
        rl.DrawRectangleV(obstacle, rl.Vector2{
            .x = LevelParser.cellWidth(self.width),
            .y = LevelParser.cellHeight(self.height),
        }, rl.BLACK);
    }
}
fn drawCount(self: Self) void {
    rl.DrawText(rl.TextFormat("Count: %d", self.count), 10, 10, 10, rl.BLACK);
}

fn drawFPS() void {
    const fps = rl.GetFPS();
    rl.DrawText(rl.TextFormat("Fps: %d", fps), 10, 25, 10, rl.BLACK);
}

fn drawEntities(self: Self) void {
    rl.DrawCircleV(self.golf_ball, self.golf_radius, GOLF_BALL_COLOR);
    rl.DrawCircleV(self.hole_pos, self.hole_radius, HOLE_COLOR);
}

pub fn deinit(self: *Self) void {
    self.gpa.free(self.obstacles);
}
