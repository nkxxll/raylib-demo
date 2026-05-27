const std = @import("std");
const rl = @import("raylib.zig");

const Field = enum {
    blank,
    ball,
    hole,
    obstacle,
};

const ParseLevelError = error{
    NoBallFound,
    NoHoleFound,
    OutOfMemory,
};

const WIDTH = 64;
const HEIGHT = 36;
// width * height + newlines
const LEVEL_STRING_LENGTH = WIDTH * HEIGHT + HEIGHT;

const Self = @This();
window_width: i32,
window_height: i32,
gpa: std.mem.Allocator,
io: std.Io,
level_file: []const u8,

pub const Level = struct {
    ball: rl.Vector2,
    hole: rl.Vector2,
    obstacles: []rl.Vector2,
    gpa: std.mem.Allocator,

    pub fn init(gpa: std.mem.Allocator, ball: rl.Vector2, hole: rl.Vector2, obstacles: []const rl.Vector2) !Level {
        const obs = try gpa.dupe(rl.Vector2, obstacles);
        return Level{
            .ball = ball,
            .hole = hole,
            .obstacles = obs,
            .gpa = gpa,
        };
    }

    pub fn deinit(self: *Level) void {
        self.gpa.free(self.obstacles);
    }
};

pub fn init(gpa: std.mem.Allocator, io: std.Io, width: i32, height: i32, level_file: []const u8) Self {
    return Self{
        .gpa = gpa,
        .window_height = height,
        .window_width = width,
        .io = io,
        .level_file = level_file,
    };
}

fn readFile(self: *const Self, level_file: []const u8) ![]const Field {
    var buffer = [_]u8{'.'} ** LEVEL_STRING_LENGTH;
    // read the level file if the file is too short well then I am just gonna
    // fill it up if its too long well then the rest is not in the level you
    // will see
    _ = std.Io.Dir.cwd().readFile(self.io, level_file, &buffer) catch @panic("The level file could not be read!");
    const level = try self.gpa.alloc(Field, LEVEL_STRING_LENGTH - HEIGHT);
    var index: usize = 0;
    for (buffer) |char| {
        switch (char) {
            '.' => {
                level[index] = Field.blank;
                index += 1;
            },
            'x' => {
                level[index] = Field.hole;
                index += 1;
            },
            '#' => {
                level[index] = Field.obstacle;
                index += 1;
            },
            '*' => {
                level[index] = Field.ball;
                index += 1;
            },
            '\n' => continue,
            else => |other| {
                std.debug.print("Char: {c}", .{other});
                @panic("This char was not expected in level file");
            },
        }
    }
    return level;
}

fn findObstacles(self: *const Self, level: []const Field) ![]const rl.Vector2 {
    var obstacle_list = try std.ArrayList(rl.Vector2).initCapacity(self.gpa, 16);
    for (level, 0..) |f, i| {
        switch (f) {
            .obstacle => {
                try obstacle_list.append(self.gpa, Self.translateIndexToWindowPos(i, self.window_width, self.window_height, true));
            },
            else => continue,
        }
    }
    return try obstacle_list.toOwnedSlice(self.gpa);
}

fn findHolePos(self: *const Self, level: []const Field) ParseLevelError!rl.Vector2 {
    for (level, 0..) |f, i| {
        switch (f) {
            .hole => {
                return Self.translateIndexToWindowPos(i, self.window_width, self.window_height, false);
            },
            else => continue,
        }
    }
    return ParseLevelError.NoHoleFound;
}

fn findBallPos(self: *const Self, level: []const Field) ParseLevelError!rl.Vector2 {
    for (level, 0..) |f, i| {
        switch (f) {
            .ball => {
                return Self.translateIndexToWindowPos(i, self.window_width, self.window_height, false);
            },
            else => continue,
        }
    }
    return ParseLevelError.NoBallFound;
}

pub fn cellWidth(window_width: i32) f32 {
    return @as(
        f32,
        @floatFromInt(window_width),
    ) / @as(
        f32,
        @floatFromInt(WIDTH),
    );
}

pub fn cellHeight(window_height: i32) f32 {
    return @as(
        f32,
        @floatFromInt(window_height),
    ) / @as(
        f32,
        @floatFromInt(HEIGHT),
    );
}

pub fn translateIndexToWindowPos(index: usize, window_width: i32, window_height: i32, for_rect: bool) rl.Vector2 {
    const cell_width = Self.cellWidth(window_width);
    const cell_height = Self.cellHeight(window_height);
    const row = index / WIDTH;
    const column = index % WIDTH;
    if (for_rect) {
        const point = rl.Vector2{
            .x = @as(f32, @floatFromInt(column)) * cell_width,
            .y = @as(f32, @floatFromInt(row)) * cell_height,
        };
        return point;
    }
    const point = rl.Vector2{
        .x = @as(f32, @floatFromInt(column)) * cell_width + cell_width / 2,
        .y = @as(f32, @floatFromInt(row)) * cell_height + cell_height / 2,
    };
    return point;
}

pub fn parseLevel(self: *const Self) ParseLevelError!Level {
    const board = try self.readFile(self.level_file);
    defer self.gpa.free(board);
    const ball = try self.findBallPos(board);
    const obstacles = try self.findObstacles(board);
    defer self.gpa.free(obstacles);
    const hole = try self.findHolePos(board);
    const level = try Level.init(self.gpa, ball, hole, obstacles);
    return level;
}
