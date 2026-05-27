const BaseLevel = @import("base_level.zig");
const LevelParser = @import("level_parser.zig");
const Level = @import("level_parser.zig").Level;
const rl = @import("raylib.zig");

const AppState = @import("app_state.zig").AppState;
const std = @import("std");

const c = @cImport({
    @cInclude("raylib.h");
});

const Self = @This();

base: BaseLevel,
level: Level,

pub fn init(gpa: std.mem.Allocator, io: std.Io, app_state: *AppState, width: i32, height: i32) Self {
    // todo: width and height here should be usize not c_int
    const lp: LevelParser = LevelParser.init(gpa, io, width, height, "./levels/level_two.txt");
    const cell_width = LevelParser.cellWidth(width);
    const level = lp.parseLevel() catch |err| {
        switch (err) {
            error.NoBallFound => @panic("The level input is malformed because there was no ball found!"),
            error.NoHoleFound => @panic("The level input is malformed because there was no hole found!"),
            else => @panic("parseFile paniced"),
        }
    };
    const base = BaseLevel.init(
        gpa,
        app_state,
        width,
        height,
        level.ball,
        level.hole,
        cell_width / 2 - 4,
        cell_width / 2 - 4,
    );
    return Self{
        .base = base,
        .level = level,
    };
}

pub fn tick(self: *Self) void {
    self.base.tick();
    self.obstacleCollision();
}

fn obstacleCollision(self: *Self) void {
    const cell_width = LevelParser.cellWidth(self.base.width);
    const cell_height = LevelParser.cellHeight(self.base.height);
    for (self.level.obstacles) |obst| {
        const rect = rl.Rectangle{
            .x = obst.x,
            .y = obst.y,
            .width = cell_width,
            .height = cell_height,
        };
        if (rl.CheckCollisionCircleRec(self.base.golf_ball, self.base.golf_radius, rect)) {
            const ball = &self.base.golf_ball;
            const velocity = &self.base.golf_ball_velocity;

            const rect_center: rl.Vector2 = .{
                .x = rect.x + rect.width / 2.0,
                .y = rect.y + rect.height / 2.0,
            };
            const dx = ball.x - rect_center.x;
            const dy = ball.y - rect_center.y;
            const overlap_x = rect.width / 2.0 + self.base.golf_radius - @abs(dx);
            const overlap_y = rect.height / 2.0 + self.base.golf_radius - @abs(dy);

            if (overlap_x < overlap_y) {
                const direction: f32 = if (dx < 0.0) -1.0 else 1.0;
                ball.x += overlap_x * direction;
                if (velocity.x * direction < 0.0) {
                    velocity.x = -velocity.x;
                }
            } else {
                const direction: f32 = if (dy < 0.0) -1.0 else 1.0;
                ball.y += overlap_y * direction;
                if (velocity.y * direction < 0.0) {
                    velocity.y = -velocity.y;
                }
            }
        }
    }
}

pub fn draw(self: *const Self) void {
    self.base.draw();
    self.drawObstacles();
}

fn drawObstacles(self: *const Self) void {
    for (self.level.obstacles) |obstacle| {
        rl.DrawRectangleV(obstacle, rl.Vector2{
            .x = LevelParser.cellWidth(self.base.width),
            .y = LevelParser.cellHeight(self.base.height),
        }, rl.BLACK);
    }
}

pub fn deinit(self: *Self) void {
    self.level.deinit();
    self.base.deinit();
}
