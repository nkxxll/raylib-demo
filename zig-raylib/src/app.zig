const std = @import("std");
const AppState = @import("app_state.zig").AppState;
const LevelOne = @import("level_one.zig");

const c = @cImport({
    @cInclude("raylib.h");
});

const circle_color = c.BLUE;
const planet_color = c.RED;
const radius: f32 = 20.0;
const planet_radius: f32 = 5.0;
const width: c_int = 1600;
const height: c_int = 900;

const Planet = extern struct {
    pos: c.Vector2,
    gravity_const: f32,
    range: f32,
};

fn onClick(
    allocator: std.mem.Allocator,
    circles: *std.ArrayList(c.Vector2),
    velocities: *std.ArrayList(c.Vector2),
    random: *const std.Random,
) !void {
    if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_LEFT)) {
        const mouse_pos = c.GetMousePosition();
        try circles.append(allocator, .{ .x = mouse_pos.x, .y = mouse_pos.y });
        try velocities.append(allocator, .{
            .x = @as(f32, @floatFromInt(random.uintLessThan(u32, 100))) / 100.0,
            .y = @as(f32, @floatFromInt(random.uintLessThan(u32, 100))) / 100.0,
        });
    }
}

fn drawCircles(circles: []const c.Vector2, color: c.Color) void {
    for (circles) |circle| {
        c.DrawCircleV(circle, radius, color);
    }
}

fn drawPlanets(planets: []const Planet, color: c.Color) void {
    for (planets) |planet| {
        c.DrawCircleV(planet.pos, planet_radius, color);
    }
}

fn inRange(a: c.Vector2, b: c.Vector2, rad_a: f32, rad_b: f32) bool {
    const dist_x = a.x - b.x;
    const dist_y = a.y - b.y;
    const range_sum = rad_a + rad_b;
    return range_sum * range_sum > dist_x * dist_x + dist_y * dist_y;
}

fn applyGravity(
    circles: []const c.Vector2,
    velocities: []c.Vector2,
    planets: []const Planet,
) void {
    for (circles, 0..) |circle, i| {
        var velocity = &velocities[i];
        for (planets) |planet| {
            if (inRange(circle, planet.pos, radius, planet.range)) {
                const dx = planet.pos.x - circle.x;
                const dy = planet.pos.y - circle.y;
                const strength = @abs(planet.range - @sqrt(dx * dx + dy * dy));
                velocity.x += strength * planet.gravity_const / 1000.0 * dx;
                velocity.y += strength * planet.gravity_const / 1000.0 * dy;
            }
        }
    }
}

fn detectCollision(circles: []c.Vector2, velocities: []c.Vector2) void {
    const current_width = c.GetScreenWidth();
    const current_height = c.GetScreenHeight();
    var i: usize = 0;
    while (i < circles.len) : (i += 1) {
        const circle = &circles[i];
        const velocity = &velocities[i];

        var j: usize = i + 1;
        while (j < circles.len) : (j += 1) {
            const other_circle = &circles[j];
            const other_velocity = &velocities[j];

            const dx = other_circle.x - circle.x;
            const dy = other_circle.y - circle.y;
            const d = dx * dx + dy * dy;
            const min_dist = radius * 2.0;

            if (d < min_dist * min_dist) {
                const length = @sqrt(d);
                const normal = if (length > 0.0)
                    c.Vector2{ .x = dx / length, .y = dy / length }
                else
                    c.Vector2{ .x = 1.0, .y = 0.0 };

                const rv = c.Vector2{
                    .x = other_velocity.x - velocity.x,
                    .y = other_velocity.y - velocity.y,
                };
                const vel_along_normal = rv.x * normal.x + rv.y * normal.y;

                if (vel_along_normal > 0.0) continue;

                const restitution: f32 = 1.0;
                const impulse_magnitude = -(1.0 + restitution) * vel_along_normal / 2.0;
                const impulse = c.Vector2{
                    .x = impulse_magnitude * normal.x,
                    .y = impulse_magnitude * normal.y,
                };

                velocity.x -= impulse.x;
                velocity.y -= impulse.y;
                other_velocity.x += impulse.x;
                other_velocity.y += impulse.y;
            }
        }

        if (circle.x >= (@as(f32, @floatFromInt(current_width)) - radius)) {
            velocity.x = if (velocity.x > 0.0) -velocity.x else velocity.x;
        }
        if (circle.x <= radius) {
            velocity.x = if (velocity.x < 0.0) -velocity.x else velocity.x;
        }
        if (circle.y >= (@as(f32, @floatFromInt(current_height)) - radius)) {
            velocity.y = if (velocity.y > 0.0) -velocity.y else velocity.y;
        }
        if (circle.y <= radius) {
            velocity.y = if (velocity.y < 0.0) -velocity.y else velocity.y;
        }
    }
}

fn addRandomPlanets(
    allocator: std.mem.Allocator,
    planets: *std.ArrayList(Planet),
    random: std.Random,
) !void {
    const count = 3 + random.uintLessThan(u32, 5);
    const current_width = width;
    const current_height = height;

    var i: u32 = 0;
    while (i < count) : (i += 1) {
        try planets.append(allocator, .{
            .pos = .{
                .x = @floatFromInt(random.uintLessThan(u32, @intCast(@max(0, current_width - 90)))),
                .y = @floatFromInt(random.uintLessThan(u32, @intCast(@max(0, current_height - 90)))),
            },
            .gravity_const = @as(f32, @floatFromInt(random.uintLessThan(u32, 90))) / 100.0,
            .range = 50.0 + @as(f32, @floatFromInt(random.uintLessThan(u32, 100))),
        });
    }
}

fn friction(velocities: []c.Vector2) void {
    for (velocities) |*velocity| {
        velocity.x *= 0.999;
        velocity.y *= 0.999;
    }
}

fn applyVelocity(circles: []c.Vector2, velocities: []const c.Vector2) void {
    for (circles, velocities) |*circle, velocity| {
        circle.x += velocity.x;
        circle.y += velocity.y;
    }
}

fn drawConnected(circles: []const c.Vector2) void {
    var i: usize = 0;
    while (i < circles.len) : (i += 1) {
        var j: usize = i;
        while (j < circles.len) : (j += 1) {
            c.DrawLineV(circles[i], circles[j], c.BLUE);
        }
    }
}
const Choose = struct {
    app_state: *AppState,
    const Self = @This();

    pub fn init(app_state: *AppState) Self {
        return Self{
            .app_state = app_state,
        };
    }

    pub fn tick(self: *Self) void {
        if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_LEFT)) {
            const app_states = @typeInfo(AppState).@"enum".fields;
            const current_height = c.GetScreenHeight();
            const segment_height: i32 = @divTrunc(current_height, @as(c_int, @intCast(app_states.len)));
            const mouse_y = c.GetMouseY();

            inline for (app_states, 0..) |app_state, multiplier| {
                const top: i32 = @as(i32, @intCast(multiplier)) * segment_height;
                const bottom: i32 = @as(i32, @intCast(multiplier + 1)) * segment_height;

                if (mouse_y > top and mouse_y < bottom) {
                    self.app_state.* = @enumFromInt(app_state.value);
                    break;
                }
            }
        }
    }
    pub fn draw() void {
        const app_states = @typeInfo(AppState).@"enum".fields;
        const current_width = c.GetScreenWidth();
        const current_height = c.GetScreenHeight();
        var color_cycle_index: usize = 0;
        const colors = [5]c.Color{ c.RED, c.BLUE, c.GREEN, c.MAGENTA, c.PURPLE };

        const segment_height: i32 = @divTrunc(current_height, @as(c_int, @intCast(app_states.len)));
        inline for (app_states, 0..) |app_state, multiplier| {
            const y = @as(i32, @intCast(multiplier)) * segment_height;
            const position = c.Vector2{
                .x = 0.0,
                .y = @floatFromInt(y),
            };
            const size = c.Vector2{
                .x = @floatFromInt(current_width),
                .y = @floatFromInt(segment_height),
            };
            c.DrawRectangleV(position, size, colors[color_cycle_index]);
            c.DrawText(app_state.name, 10, y + 5, 10, c.WHITE);
            color_cycle_index = (color_cycle_index + 1) % colors.len;
        }
    }
};

const Demo = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    circles: std.ArrayList(c.Vector2),
    velocities: std.ArrayList(c.Vector2),
    planets: std.ArrayList(Planet),

    const Self = @This();
    pub fn init(gpa: std.mem.Allocator, io: std.Io) !Self {
        const circles = try std.ArrayList(c.Vector2).initCapacity(gpa, 16);
        const velocities = try std.ArrayList(c.Vector2).initCapacity(gpa, 16);
        var planets = try std.ArrayList(Planet).initCapacity(gpa, 5);

        try addRandomPlanets(gpa, &planets, (std.Random.IoSource{ .io = io }).interface());
        return Self{
            .gpa = gpa,
            .io = io,
            .circles = circles,
            .velocities = velocities,
            .planets = planets,
        };
    }

    pub fn tick(self: *Self) !void {
        try onClick(self.gpa, &self.circles, &self.velocities, &(std.Random.IoSource{ .io = self.io }).interface());
        friction(self.velocities.items);
        applyGravity(self.circles.items, self.velocities.items, self.planets.items);
        detectCollision(self.circles.items, self.velocities.items);
        applyVelocity(self.circles.items, self.velocities.items);
    }

    pub fn draw(self: Self) void {
        c.ClearBackground(c.RAYWHITE);
        drawCircles(self.circles.items, circle_color);
        drawPlanets(self.planets.items, planet_color);
        drawConnected(self.circles.items);
    }

    pub fn deinit(self: *Self) void {
        self.circles.deinit(self.gpa);
        self.velocities.deinit(self.gpa);
        self.planets.deinit(self.gpa);
    }
};

pub const App = struct {
    gpa: std.mem.Allocator,
    demo: Demo,
    choose: Choose,
    level_one: LevelOne,
    app_state: *AppState,

    const Self = @This();

    pub fn init(gpa: std.mem.Allocator, io: std.Io) !Self {
        const app_state = try gpa.create(AppState);
        app_state.* = .choose;
        const demo = try Demo.init(gpa, io);
        const choose = Choose.init(app_state);
        const level_one = LevelOne.init(gpa, app_state, width, height);
        return Self{
            .gpa = gpa,
            .demo = demo,
            .choose = choose,
            .app_state = app_state,
            .level_one = level_one,
        };
    }

    pub fn tick(self: *Self) !void {
        switch (self.app_state.*) {
            .choose => self.choose.tick(),
            .demo => try self.demo.tick(),
            .level_one => self.level_one.tick(),
        }
    }

    pub fn draw(self: *Self) void {
        switch (self.app_state.*) {
            .choose => Choose.draw(),
            .demo => self.demo.draw(),
            .level_one => self.level_one.draw(),
        }
    }

    pub fn loop(self: *Self) !void {
        c.InitWindow(width, height, "Application");

        // optional safety: force maximize again

        // c.SetWindowState(c.FLAG_WINDOW_RESIZABLE);
        defer c.CloseWindow();
        c.SetTargetFPS(60);

        while (!c.WindowShouldClose()) {
            try self.tick();
            c.BeginDrawing();
            self.draw();
            c.EndDrawing();
        }
    }

    pub fn deinit(self: *Self) void {
        self.demo.deinit();
        self.gpa.destroy(self.app_state);
    }
};
