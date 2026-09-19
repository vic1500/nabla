const std = @import("std");
const Grid = @import("core").Grid;
const Span = @import("core").Span;

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const allocator = arena.allocator();

    const a = try Grid(i32).construct(allocator, &.{1, 2, 3, 4, 5, 6}, .{3, 2});
    const b = try Span(i32).create(allocator, &.{1, 2, 3, 4, 5, 6}, .row);

    const c = try Grid(u16).construct(allocator, &.{7, 8, 9, 10, 11, 12}, .{6, 1});
    const d = try Span(f32).create(allocator, &.{0.64677, 5.0, 0.4, 0.3, 0.2, 0.1}, .col);

    try a.show();
    std.debug.print("\n\n", .{});
    try b.show();
    std.debug.print("\n\n", .{});
    try c.show();
    std.debug.print("\n\n", .{});
    try d.show();
}
