const std = @import("std");
const Grid = @import("core").Grid;
const Span = @import("core").Span;
const ops = @import("linalg").ops;

pub fn gridTest(allocator: std.mem.Allocator) !void {
    
    const grid_1 = try Grid(i16).construct(allocator, &.{1, 2, 3, 4, 5, 6}, .{2, 3});
    const grid_2 = try Grid(i16).construct(allocator, &.{1, 20, 23, 41, 52, 61}, .{2, 3});

    const grid_3 = try ops.add(i16, allocator, grid_1, grid_2);
    const grid_4 = try ops.mul(i16, allocator, grid_3, grid_2);
    const grid_5 = try grid_4.as(f16);
    const grid_6 = try grid_3.as(f16);
    const grid_7 = try ops.div(f16, allocator, grid_6, grid_5);
    const grid_8 = try ops.div(f16, allocator, try grid_3.as(f16), try grid_2.as(f16));

    const grid_9 = try Grid(f32).xoshiroGen(allocator, 34, 2000, .{400, 5});
    const grid_10 = try grid_9.as(i32);

    try grid_3.show();
    try grid_4.show();
    try grid_7.show();
    try grid_8.show();

    try grid_9.show();
    try grid_10.show();

}

pub fn spanTest(allocator: std.mem.Allocator) !void {
    const span_1 = try Span(i8).xoshiroGen(allocator, 23, 100, .row);
    const span_2 = try Span(i8).xoshiroGen(allocator, 21, 100, .col);

    try span_1.show();
    try span_2.show();

    const span_3 = try ops.add(i16, allocator, try span_1.as(i16), try span_2.as(i16));

    try span_3.show();

    const span_4 = try span_3.as(f32);
    const span_5 = try Span(f32).xoshiroGen(allocator, 45, 100, .col);

    try span_4.show();
    try span_5.show();

    const span_6 = try ops.div(f32, allocator, span_4, span_5);
    const span_7 = try ops.mul(f32, allocator, span_4, span_5);
    const span_8 = try ops.sub(f32, allocator, span_7, span_5);

    try span_6.show();
    try span_7.show();
    try span_8.show();
    
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const allocator = arena.allocator();
    try gridTest(allocator); 
    try spanTest(allocator);
}

