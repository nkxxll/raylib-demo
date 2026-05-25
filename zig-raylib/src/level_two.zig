const BaseLevel = @import("level_one.zig");

const AppState = @import("app_state.zig").AppState;
const std = @import("std");

const c = @cImport({
    @cInclude("raylib.h");
});

const Self = @This();

const Obstacle = struct {
    const RASTER_SIZE: usize = 25;
    x: f32,
    y: f32,
};

base: BaseLevel,
obstacles: []Obstacle,

pub fn new(gpa: std.mem.Allocator, AppState: *AppState, width: usize, height: usize) Self {
    // todo: width and height here should be usize not c_int
    const base = BaseLevel.init(gpa, app_state: *AppState, width: c_int, height: c_int)
    return Self {
        .base = base,
        .obstacles =
    };

}
