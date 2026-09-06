const std = @import("std");
const Span = @import("span.zig").Span;
const Allocator = std.mem.Allocator;

const GridError = error {
    IndexOutOfBound,
    DataDimensionMisMatch
}; // Will implement this later


pub fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();
        
        data: []T,
        dim: [2]usize,
        strides: [2]usize,
        allocator: Allocator,

        pub fn construct(allocator: Allocator, data: []const T, dim: [2]usize) !Self {
            std.debug.assert(data.len == (dim[0] * dim[1]));

            const owned_data = try allocator.dupe(T, data);

            return .{
                .allocator = allocator,
                .data = owned_data,
                .dim = dim,
                .strides = [2]usize {dim[1], 1},
            };
        }   
        
        pub inline fn at(self: Self, row: usize, col: usize) T {
            std.debug.assert((row < self.dim[0]) and (col < self.dim[1]));
            
            const index = (row * self.strides[0]) + (col * self.strides[1]);

            return self.data[index];
        }

        pub inline fn mut(self: Self, row: usize, col: usize) *T {
            std.debug.assert((row < self.dim[0]) and (col < self.dim[1]));

            const index = (row * self.strides[0]) + (col * self.strides[1]);

            return &self.data[index];
        }

        pub inline fn size(self: Self) usize {
            return self.dim[0] * self.dim[1];
        }

        pub fn RowView(self: Self, idx_row: usize) Span(T) {
            std.debug.assert(idx_row < self.dim[0]);
            const offset = idx_row * self.strides[0];

            return .{
                .data = self.data[offset..],
                .len = self.dim[1],
                .stride = self.strides[1],
                .dim = .{0},
            };
        }

        pub fn ColView(self: Self, idx_col: usize) Span(T) {
            std.debug.assert(idx_col < self.dim[1]);
            const offset = idx_col * self.strides[1];

            return .{
                .data = self.data[offset..],
                .len = self.dim[0],
                .stride = self.strides[0],
                .dim = .{1},
            };
        }

        pub fn deconstruct(self: Self) void {
            self.allocator.free(self.data);
        }

    };

}

test "Test Basic Grid" {
    const allocator = std.testing.allocator;

    const mat1 = try Grid(i32).construct(allocator, &.{1, 2, 3, 4, 5, 6}, .{2, 3});
    defer mat1.deconstruct();

    try std.testing.expect(mat1.size() == 6);
    try std.testing.expect(mat1.at(0, 1) == 2);
    try std.testing.expect(mat1.at(1, 2) == 6);

    mat1.mut(1, 2).* = 12;
    try std.testing.expect(mat1.at(1, 2) == 12);

}

test "Test RowView and ColumnView" {
    const allocator = std.testing.allocator;

    const mat1 = try Grid(i32).construct(allocator, &.{1, 2, 3, 4, 5, 6}, .{2, 3});
    defer mat1.deconstruct();

    const row_0 = mat1.RowView(0);

    try std.testing.expectEqual(3, row_0.len);
    try std.testing.expectEqual(1, row_0.at(0));
    try std.testing.expectEqual(2, row_0.at(1));
    try std.testing.expectEqual(3, row_0.at(2));

    const row_1 = mat1.RowView(1);

    try std.testing.expectEqual(3, row_1.len);
    try std.testing.expectEqual(4, row_1.at(0));
    try std.testing.expectEqual(5, row_1.at(1));
    try std.testing.expectEqual(6, row_1.at(2));

    const col_0 = mat1.ColView(0);
    try std.testing.expectEqual(2, col_0.len);
    try std.testing.expectEqual(1, col_0.at(0));
    try std.testing.expectEqual(4, col_0.at(1));

    const col_1 = mat1.ColView(1);
    try std.testing.expectEqual(2, col_1.len);
    try std.testing.expectEqual(2, col_1.at(0));
    try std.testing.expectEqual(5, col_1.at(1));

    const col_2 = mat1.ColView(2);
    try std.testing.expectEqual(2, col_2.len);
    try std.testing.expectEqual(3, col_2.at(0));
    try std.testing.expectEqual(6, col_2.at(1));

    col_2.mut(1).* = 2;

    const arr = [3]i32 {4, 5, 2};

    try std.testing.expectEqual(2, col_2.at(1));
    try std.testing.expectEqualSlices(i32,&arr, mat1.data[3..]);

}
