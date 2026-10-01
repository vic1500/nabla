const std = @import("std");
const Allocator = std.mem.Allocator;
const Grid = @import("core").Grid;


pub fn matmul(comptime T: type, allocator: Allocator, a: Grid(T), b: Grid(T)) !Grid(T) {
    std.debug.assert(a.dim[1] == b.dim[0]);

    const c = try allocator.alloc(T, (a.dim[0] * b.dim[1]));
    @memset(c[0..], 0);
    for (0..a.dim[0]) |i| {
        const c_row = c[(i * b.dim[1])..][0..b.dim[1]];
        for (0..b.dim[0]) |k| {
            const a_ik = a.data[(i * a.dim[1]) + k];
            const b_row = b.data[(k * b.dim[1])..][0..b.dim[1]];
            for (c_row, b_row) |*cv, bv| {
                cv.* += bv * a_ik;
            }
        }
    }

    return .{
        .data = c,
        .dim = .{a.dim[0], b.dim[1]},
        .strides = .{b.dim[1], 1},
        .allocator = allocator,
    };
}

test "Test matrix multiplication" {
    const allocator = std.testing.allocator;

    const a = try Grid(i32).construct(allocator, &.{ 1, 2, 3, 4, 5, 6 }, .{ 2, 3 });
    defer a.destruct();
    const b = try Grid(i32).construct(allocator, &.{ 7, 8, 9, 10, 11, 12 }, .{ 3, 2 });
    defer b.destruct();

    const c = try matmul(i32, allocator, a, b);
    defer c.destruct();

    try std.testing.expectEqualSlices(i32, &.{ 58, 64, 139, 154 }, c.data[0..]);
    try std.testing.expectEqual(.{ 2, 2 }, c.dim);
    try std.testing.expectEqual(139, c.at(1, 0));
}

