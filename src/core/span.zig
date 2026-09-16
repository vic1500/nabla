const std = @import("std");
const Allocator = std.mem.Allocator;
const FlatView = @import("flatview.zig").FlatView;
const ops = @import("../linalg/ops.zig");

const Orient = enum {
    row,
    col,
};

pub fn SpanView(comptime T: type) type {
    return struct {
        const Self = @This();

        data: []T,
        len: usize,
        stride: usize,
        orient: Orient,

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

        pub inline fn asFlat(self: Self) FlatView(T) {
            return .{
                .data = self.data,
                .len = self.len,
                .stride = self.stride,
            };
        }

    };
}

pub fn Span(comptime T: type) type {
    return struct {
        const Self = @This();

        inner: SpanView(T),
        allocator: Allocator,

        pub fn create(allocator: Allocator, data: []const T, orient: Orient) !Self {
            const owned_data = try allocator.dupe(T, data);
            return .{
                .inner = .{
                    .data = owned_data,
                    .orient = orient,
                    .len = data.len,
                    .stride = 1,
                },
                .allocator = allocator,
            };
        }

        pub inline fn at(self: Self, idx: usize) T {
            return self.inner.at(idx);
        }

        pub inline fn mut(self: Self, idx: usize) *T {
            return self.inner.mut(idx);
        }

        pub inline fn asFlat(self: Self) FlatView(T) {
            return self.inner.asFlat();
        }


        pub inline fn as(self: Self, comptime as_type: type) !Span(as_type) {
            const out = try self.allocator.alloc(as_type, self.inner.data.len);
            defer self.allocator.free(out);

            switch (@typeInfo(T)) {
                .int => {
                    switch (@typeInfo(as_type)) {
                        .int => {
                            for (0..self.inner.data.len) |i| {
                                out[i] = @intCast(self.inner.data[i]);
                            }
                        },
                        .float => {
                            for (0..self.inner.data.len) |i| {
                                out[i] = @floatFromInt(self.inner.data[i]);
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
                            for (0..self.inner.data.len) |i| {
                                out[i] = @intFromFloat(self.inner.data[i]);
                            }
                        },
                        .float => {
                            for (0..self.inner.data.len) |i| {
                                out[i] = @floatCast(self.inner.data[i]);
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
            return Span(as_type).create(self.allocator, out, .row);
        }

        pub fn destroy(self: Self) void {
            self.allocator.free(self.inner.data);
        }
    };
}

test "Test Span creation and destruction" {
    const allocator = std.testing.allocator;

    const span_row = try Span(i32).create(allocator, &.{1, 2, 3, 4, 5, 6}, .row);
    defer span_row.destroy();

    try std.testing.expect(span_row.inner.len == 6);
    try std.testing.expect(span_row.at(2) == 3);
    try std.testing.expect(span_row.inner.orient == .row);
    try std.testing.expect(span_row.inner.stride == 1);

    span_row.mut(2).* = 7;
    try std.testing.expect(span_row.at(2) == 7);


    const span_col = try Span(i32).create(allocator, &.{1, 2, 3, 4, 5, 6}, .col);
    defer span_col.destroy();

    try std.testing.expect(span_col.inner.len == 6);
    try std.testing.expect(span_col.at(2) == 3);
    try std.testing.expect(span_col.inner.orient == .col);
    try std.testing.expect(span_col.inner.stride == 1);

    span_col.mut(2).* = 7;
    try std.testing.expect(span_col.at(2) == 7);
}

test "Test Span Addition" {
    const allocator = std.testing.allocator;

    const a = try Span(i32).create(allocator, &.{1, 2, 3, 4, 5, 6}, .row);
    defer a.destroy();

    const b = try Span(i32).create(allocator, &.{7, 8, 9, 10, 11, 12}, .row);
    defer b.destroy();

    const c = try ops.add(i32, allocator, a, b);
    defer c.destroy();

    try std.testing.expectEqualSlices(i32, &.{8, 10, 12, 14, 16, 18}, c.inner.data[0..]);
}

test "Test Span Subtraction" {
    const allocator = std.testing.allocator;

    const a = try Span(i32).create(allocator, &.{1, 2, 3, 4, 5, 6}, .row);
    defer a.destroy();

    const b = try Span(i32).create(allocator, &.{7, 8, 9, 10, 11, 12}, .row);
    defer b.destroy();

    const c = try ops.sub(i32, allocator, a, b);
    defer c.destroy();

    try std.testing.expectEqualSlices(i32, &.{-6, -6, -6, -6, -6, -6}, c.inner.data[0..]);
}

test "Test Span Multiplication" {
    const allocator = std.testing.allocator;

    const a = try Span(i32).create(allocator, &.{1, 2, 3, 4, 5, 6}, .row);
    defer a.destroy();

    const b = try Span(i32).create(allocator, &.{7, 8, 9, 10, 11, 12}, .row);
    defer b.destroy();

    const c = try ops.mul(i32, allocator, a, b);
    defer c.destroy();

    try std.testing.expectEqualSlices(i32, &.{7, 16, 27, 40, 55, 72}, c.inner.data[0..]);
}

test "Test Span Division" {
    const allocator = std.testing.allocator;

    const a = try Span(i32).create(allocator, &.{14, 24, 36, 40, 55, 60}, .row);
    defer a.destroy();

    const b = try Span(i32).create(allocator, &.{7, 8, 9, 10, 11, 12}, .row);
    defer b.destroy();

    const a_float = try a.as(f32);
    defer a_float.destroy();
    const b_float = try b.as(f32);
    defer b_float.destroy();

    const c = try ops.div(f32, allocator, a_float, b_float);
    defer c.destroy();

    try std.testing.expectEqualSlices(f32, &.{2.0, 3.0, 4.0, 4.0, 5.0, 5.0}, c.inner.data[0..]);
}

test "Test casting" {
    const allocator = std.testing.allocator;

    const a = try Span(i16).create(allocator, &.{1, 2, 3, 4, 5, 6}, .row);
    defer a.destroy();
    const b = try Span(i16).create(allocator, &.{7, 8, 9, 10, 11, 12}, .row);
    defer b.destroy();

    const a_i32 = try a.as(i32);
    defer a_i32.destroy();
    const b_u16 = try b.as(u16);
    defer b_u16.destroy();

    const a_f16 = try a.as(f16);
    defer a_f16.destroy();
    const b_f64 = try b.as(f64);
    defer b_f64.destroy();

    try std.testing.expect(@TypeOf(a_i32.inner.data) == []i32);
    try std.testing.expect(@TypeOf(b_u16.inner.data) == []u16);
    try std.testing.expect(@TypeOf(a_f16.inner.data) == []f16);
    try std.testing.expect(@TypeOf(b_f64.inner.data) == []f64);

}

test "Test using arena allocator to see if I don't need to defer each Span" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const arena_allocator = arena.allocator();

    const a = try Span(i32).create(arena_allocator, &.{1, 2, 3, 4, 5, 6}, .row);
    const b = try Span(i32).create(arena_allocator, &.{1, 2, 3, 4, 5, 6}, .row);
    
    const c = try ops.add(i32, arena_allocator, a, b);

    try std.testing.expectEqualSlices(i32, &.{2, 4, 6, 8, 10, 12}, c.inner.data[0..]);
    
}

