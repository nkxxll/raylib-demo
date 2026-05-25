const std = @import("std");

const Fild = enum {
    blank,
    ball,
    hole,
    obstacle,
};

const WIDTH = 64;
const HEIGHT = 36;
// width * height + newlines
const LEVEL_STRING_LENGTH = WIDTH * HEIGHT + HEIGHT;

pub fn read_file(gpa: std.mem.Allocator, io: std.Io, level_file: []const u8) ![]const Fild {
    const buffer = [LEVEL_STRING_LENGTH]u8{0};
    const file_contents = std.Io.Dir.cwd().readFile(io, level_file, buffer) catch @panic("The level file is not formatted as expected!");
    const level = try gpa.alloc(Fild, LEVEL_STRING_LENGTH);
    for (file_contents, 0..) |char, index| {
        switch (char) {
            '.' => level[index] = Fild.blank,
            '#' => level[index] = Fild.obstacle,
            '*' => level[index] = Fild.ball,
            'x' => level[index] = Fild.hole,
            else => |other| {
                std.debug.print("Char: {c}", .{other});
                @panic("This char was not expected in level file");
            },
        }
    }
    return level;
}
