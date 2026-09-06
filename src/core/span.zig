const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn Span(comptime T: type) type {
    return struct {
        const Self = @This();

        data: []T,
        len: usize,
        stride: usize,
        dim: [1]usize,
        allocator: ?Allocator = null,

        pub fn create(allocator: Allocator, data: []const T, dim: [1]usize) !Self {
            const owned_data = try allocator.dupe(T, data);
            return .{
                .data = owned_data,
                .dim = dim,
                .len = data.len,
                .stride = 1,
                .allocator = allocator,
            };
        }

        pub inline fn at(self: Self, idx: usize) T {
            std.debug.assert(idx < self.len);
            const index = idx * self.stride;

            return self.data[index];
        }

        pub inline fn mut(self: Self, idx: usize) *T {
            std.debug.assert(idx < self.len);
            const index = idx * self.stride;

            return &self.data[index];
        }

        pub fn destroy(self: Self) void {
            if (self.allocator) |alloc| alloc.free(self.data);
        }
    };
}

test "Test Span creation and destruction" {
    const allocator = std.testing.allocator;

    const span_row = try Span(i32).create(allocator, &.{1, 2, 3, 4, 5, 6}, .{0});
    defer span_row.destroy();

    try std.testing.expect(span_row.len == 6);
    try std.testing.expect(span_row.at(2) == 3);
    try std.testing.expectEqualSlices(usize, &span_row.dim, &.{0});
    try std.testing.expect(span_row.stride == 1);

    span_row.mut(2).* = 7;
    try std.testing.expect(span_row.at(2) == 7);


    const span_col = try Span(i32).create(allocator, &.{1, 2, 3, 4, 5, 6}, .{1});
    defer span_col.destroy();

    try std.testing.expect(span_col.len == 6);
    try std.testing.expect(span_col.at(2) == 3);
    try std.testing.expectEqualSlices(usize, &span_col.dim, &.{1});
    try std.testing.expect(span_col.stride == 1);

    span_col.mut(2).* = 7;
    try std.testing.expect(span_col.at(2) == 7);
}