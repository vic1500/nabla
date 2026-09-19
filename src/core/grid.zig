const std = @import("std");
const Allocator = std.mem.Allocator;

const SpanView = @import("span.zig").SpanView;
const ops = @import("linalg").ops;
const FlatView = @import("flatview.zig").FlatView;
const random = @import("random.zig");

const GridError = error{ IndexOutOfBound, DataDimensionMisMatch, OutOfMemory }; // Will implement the Index stuff later

pub fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();

        data: []T,
        dim: [2]usize,
        strides: [2]usize,
        allocator: Allocator,

        pub fn construct(allocator: Allocator, data: []const T, dim: [2]usize) GridError!Self {
            if (!(data.len == (dim[0] * dim[1]))) return error.DataDimensionMisMatch;

            const owned_data = try allocator.dupe(T, data);

            return .{
                .allocator = allocator,
                .data = owned_data,
                .dim = dim,
                .strides = [2]usize{ dim[1], 1 },
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

        pub inline fn asFlat(self: Self) FlatView(T) {
            return .{
                .data = self.data,
                .len = self.size(),
                .stride = 1,
            };
        }

        pub inline fn as(self: Self, comptime as_type: type) !Grid(as_type) {
            const out = try self.allocator.alloc(as_type, self.data.len);
            defer self.allocator.free(out);

            switch (@typeInfo(T)) {
                .int => {
                    switch (@typeInfo(as_type)) {
                        .int => {
                            for (0..self.data.len) |i| {
                                out[i] = @intCast(self.data[i]);
                            }
                        },
                        .float => {
                            for (0..self.data.len) |i| {
                                out[i] = @floatFromInt(self.data[i]);
                            }
                        },
                        else => {
                            @compileError("Cannot cast type of " ++ @typeName(@TypeOf(T)) ++ "to type of " ++ @typeName(@TypeOf(as_type)));
                        },
                    }
                },

                .float => {
                    switch (@typeInfo(as_type)) {
                        .int => {
                            for (0..self.data.len) |i| {
                                out[i] = @intFromFloat(self.data[i]);
                            }
                        },
                        .float => {
                            for (0..self.data.len) |i| {
                                out[i] = @floatCast(self.data[i]);
                            }
                        },
                        else => {
                            @compileError("Cannot cast type of " ++ @typeName(@TypeOf(T)) ++ "to type of " ++ @typeName(@TypeOf(as_type)));
                        },
                    }
                },

                else => {
                    @compileError("Casting type of " ++ @typeName(@TypeOf(as_type)) ++ " is not supported.");
                },
            }
            return Grid(as_type).construct(self.allocator, out, self.dim);
        }
        pub fn RowView(self: Self, idx_row: usize) SpanView(T) {
            std.debug.assert(idx_row < self.dim[0]);
            const offset = idx_row * self.strides[0];

            return .{
                .data = self.data[offset..],
                .len = self.dim[1],
                .stride = self.strides[1],
                .orient = .row,
            };
        }

        pub fn ColView(self: Self, idx_col: usize) SpanView(T) {
            std.debug.assert(idx_col < self.dim[1]);
            const offset = idx_col * self.strides[1];

            return .{
                .data = self.data[offset..],
                .len = self.dim[0],
                .stride = self.strides[0],
                .orient = .col,
            };
        }

        pub inline fn show(self: Self) !void {
            var string = std.ArrayList(u8).empty;
            defer string.deinit(self.allocator);

            try string.appendSlice(self.allocator, "Grid([\n");

            for (0..self.dim[0]) |i| {
                try string.appendSlice(self.allocator, "  [");

                for (0..self.dim[1]) |j| {
                    if (j != (self.dim[1] - 1)) {
                        const string_of_value = try std.fmt.allocPrint(self.allocator, "{d}, ", .{self.at(i, j)});
                        defer self.allocator.free(string_of_value);
                        try string.appendSlice(self.allocator, string_of_value);
                    } else {
                        const string_of_value = try std.fmt.allocPrint(self.allocator, "{d}", .{self.at(i, j)});
                        defer self.allocator.free(string_of_value);
                        try string.appendSlice(self.allocator, string_of_value);
                    }
                }
                try string.appendSlice(self.allocator, "]\n");
            }
            try string.appendSlice(self.allocator, "])\ntype: ");
            try string.appendSlice(self.allocator, @typeName(@TypeOf(self.data[0])) ++ "\n");

            std.debug.print("{s}", .{string.items});
        }

        pub inline fn xoshiroGen(allocator: Allocator, seed: usize, len: usize, dim: [2]usize) !Self {
            if ((len != (dim[0] * dim[1]))) return error.DataDimensionMisMatch;

            var prng = std.Random.DefaultPrng.init(seed);
            const rand_gen = prng.random();

            const data = try allocator.alloc(T, len);

            const rand_grid = Self {
                .allocator = allocator,
                .data = data,
                .dim = dim,
                .strides = [2]usize{ dim[1], 1 },
            };

            random.randomNumberGen(T, rand_grid.data, rand_gen);

            return rand_grid;

        }

        pub fn destruct(self: Self) void {
            self.allocator.free(self.data);
        }
    };

}

test "Test Basic Grid" {
    const allocator = std.testing.allocator;

    const mat1 = try Grid(i32).construct(allocator, &.{ 1, 2, 3, 4, 5, 6 }, .{ 2, 3 });
    defer mat1.destruct();

    try std.testing.expect(mat1.size() == 6);
    try std.testing.expect(mat1.at(0, 1) == 2);
    try std.testing.expect(mat1.at(1, 2) == 6);

    mat1.mut(1, 2).* = 12;
    try std.testing.expect(mat1.at(1, 2) == 12);
}

test "Test RowView and ColumnView" {
    const allocator = std.testing.allocator;

    const mat1 = try Grid(i32).construct(allocator, &.{ 1, 2, 3, 4, 5, 6 }, .{ 2, 3 });
    defer mat1.destruct();

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

    const arr = [3]i32{ 4, 5, 2 };

    try std.testing.expectEqual(2, col_2.at(1));
    try std.testing.expectEqualSlices(i32, &arr, mat1.data[3..]);
}

test "Test addition ops" {
    const allocator = std.testing.allocator;

    const a = try Grid(i32).construct(allocator, &.{ 1, 2, 3, 4, 5, 6 }, .{ 2, 3 });
    defer a.destruct();
    const b = try Grid(i32).construct(allocator, &.{ 7, 8, 9, 10, 11, 12 }, .{ 2, 3 });
    defer b.destruct();

    const c = try ops.add(i32, allocator, a, b);
    defer c.destruct();

    try std.testing.expectEqualSlices(i32, &.{ 8, 10, 12, 14, 16, 18 }, c.data[0..]);
}

test "Test subtraction ops" {
    const allocator = std.testing.allocator;

    const a = try Grid(i32).construct(allocator, &.{ 1, 2, 3, 4, 5, 6 }, .{ 2, 3 });
    defer a.destruct();
    const b = try Grid(i32).construct(allocator, &.{ 7, 8, 9, 10, 11, 12 }, .{ 2, 3 });
    defer b.destruct();

    const c = try ops.sub(i32, allocator, a, b);
    defer c.destruct();

    try std.testing.expectEqualSlices(i32, &.{ -6, -6, -6, -6, -6, -6 }, c.data[0..]);
}

test "Test multiplication ops" {
    const allocator = std.testing.allocator;

    const a = try Grid(i32).construct(allocator, &.{ 1, 2, 3, 4, 5, 6 }, .{ 2, 3 });
    defer a.destruct();
    const b = try Grid(i32).construct(allocator, &.{ 7, 8, 9, 10, 11, 12 }, .{ 2, 3 });
    defer b.destruct();

    const c = try ops.mul(i32, allocator, a, b);
    defer c.destruct();

    try std.testing.expectEqualSlices(i32, &.{ 7, 16, 27, 40, 55, 72 }, c.data[0..]);
}

test "Test division ops" {
    const allocator = std.testing.allocator;

    const a = try Grid(i32).construct(allocator, &.{ 12, 14, 18, 20, 24, 26 }, .{ 2, 3 });
    defer a.destruct();
    const b = try Grid(i32).construct(allocator, &.{ 6, 7, 9, 10, 4, 2 }, .{ 2, 3 });
    defer b.destruct();

    const a_float = try a.as(f32);
    defer a_float.destruct();
    const b_float = try b.as(f32);
    defer b_float.destruct();

    const c = try ops.div(f32, allocator, a_float, b_float);
    defer c.destruct();

    try std.testing.expectEqualSlices(f32, &.{ 2.0, 2.0, 2.0, 2.0, 6.0, 13.0 }, c.data[0..]);
}

test "Test casting" {
    const allocator = std.testing.allocator;

    const a = try Grid(i16).construct(allocator, &.{ 1, 2, 3, 4, 5, 6 }, .{ 3, 2 });
    defer a.destruct();
    const b = try Grid(i16).construct(allocator, &.{ 7, 8, 9, 10, 11, 12 }, .{ 3, 2 });
    defer b.destruct();

    const a_i32 = try a.as(i32);
    defer a_i32.destruct();
    const b_u16 = try b.as(u16);
    defer b_u16.destruct();

    const a_f16 = try a.as(f16);
    defer a_f16.destruct();
    const b_f64 = try b.as(f64);
    defer b_f64.destruct();

    try std.testing.expect(@TypeOf(a_i32.data) == []i32);
    try std.testing.expect(@TypeOf(b_u16.data) == []u16);
    try std.testing.expect(@TypeOf(a_f16.data) == []f16);
    try std.testing.expect(@TypeOf(b_f64.data) == []f64);
}

test "Test using arena allocator to see if I don't need to defer each Grid" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const arena_allocator = arena.allocator();

    const a = try Grid(i32).construct(arena_allocator, &.{ 1, 2, 3, 4, 5, 6 }, .{ 2, 3 });
    const b = try Grid(i32).construct(arena_allocator, &.{ 1, 2, 3, 4, 5, 6 }, .{ 2, 3 });

    const c = try ops.add(i32, arena_allocator, a, b);

    try std.testing.expectEqualSlices(i32, &.{ 2, 4, 6, 8, 10, 12 }, c.data[0..]);
}
