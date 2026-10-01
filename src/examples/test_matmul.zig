const std = @import("std");
const Grid = @import("core").Grid;
const matmul = @import("linalg").matmul;

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();

    const allocator = arena.allocator();

    const grid_1 = try Grid(i16).xoshiroGen(allocator, 42, 20, .{4, 5});
    const grid_2 = try Grid(i16).xoshiroGen(allocator, 42, 20, .{5, 4});

    const grid_3 = try matmul(i32, allocator, try grid_1.as(i32), try grid_2.as(i32));

    try grid_3.show();
}
