const std = @import("std");
const App = @import("app.zig").App;

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var app = try App.init(gpa, io);
    defer app.deinit();

    try app.loop();
}
