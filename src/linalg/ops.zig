//! Common operations such as addition, subtraction, element-wise multiplication, matrix multiplication are implemented here

const std = @import("std");
const Allocator = std.mem.Allocator;
const Grid = @import("../core/grid.zig").Grid;
const Span = @import("../core/span.zig").Span;
const kernel = @import("ops_kernel.zig");

pub fn add(comptime T: type, allocator: Allocator, a: anytype, b: anytype) !@TypeOf(a) {
    comptime {
        if ((@TypeOf(a) != Grid(T)) and (@TypeOf(a) != Span(T))) {
            @compileError(@typeName(@TypeOf(a)) ++ " type not supported. Only Grid or Span");
        } else if ((@TypeOf(b) != Grid(T)) and (@TypeOf(b) != Span(T))) {
            @compileError(@typeName(@TypeOf(b)) ++ " type not supported. Only Grid or Span");
        }
    }

    if (comptime (@TypeOf(a) == Grid(T) and @TypeOf(b) == Grid(T))) {
        std.debug.assert(a.size() == b.size());
        const out = try allocator.alloc(T, a.size());
        kernel.addKernel(T, out, a.asFlat(), b.asFlat());
        return .{ .allocator = allocator, .data = out, .strides = a.strides, .dim = a.dim };
    } else if (comptime (@TypeOf(a) == Span(T) and @TypeOf(b) == Span(T))) {
        std.debug.assert(a.inner.len == b.inner.len);
        const out = try allocator.alloc(T, a.inner.len);
        kernel.addKernel(T, out, a.asFlat(), b.asFlat());
        return .{
            .allocator = allocator,
            .inner = .{ .data = out, .len = a.inner.len, .stride = 1, .orient = a.inner.orient },
        };
    } else {
        @compileError("Operation between " ++ @typeName(@TypeOf(a)) ++ " and " ++ @typeName(@TypeOf(b)) ++ " is not supported");
    }
}


pub fn sub(comptime T: type, allocator: Allocator, a: anytype, b: anytype) !@TypeOf(a) {
    comptime {
        if ((@TypeOf(a) != Grid(T)) and (@TypeOf(a) != Span(T))) {
            @compileError(@typeName(@TypeOf(a)) ++ " type not supported. Only Grid or Span");
        } else if ((@TypeOf(b) != Grid(T)) and (@TypeOf(b) != Span(T))) {
            @compileError(@typeName(@TypeOf(b)) ++ " type not supported. Only Grid or Span");
        }
    }

    if (comptime (@TypeOf(a) == Grid(T) and @TypeOf(b) == Grid(T))) {
        std.debug.assert(a.size() == b.size());
        const out = try allocator.alloc(T, a.size());
        kernel.subKernel(T, out, a.asFlat(), b.asFlat());
        return .{ .allocator = allocator, .data = out, .strides = a.strides, .dim = a.dim };
    } else if (comptime (@TypeOf(a) == Span(T) and @TypeOf(b) == Span(T))) {
        std.debug.assert(a.inner.len == b.inner.len);
        const out = try allocator.alloc(T, a.inner.len);
        kernel.subKernel(T, out, a.asFlat(), b.asFlat());
        return .{
            .allocator = allocator,
            .inner = .{ .data = out, .len = a.inner.len, .stride = 1, .orient = a.inner.orient },
        };
    } else {
        @compileError("Operation between " ++ @typeName(@TypeOf(a)) ++ " and " ++ @typeName(@TypeOf(b)) ++ " is not supported");
    }
}

pub fn mul(comptime T: type, allocator: Allocator, a: anytype, b: anytype) !@TypeOf(a) {
    comptime {
        if ((@TypeOf(a) != Grid(T)) and (@TypeOf(a) != Span(T))) {
            @compileError(@typeName(@TypeOf(a)) ++ " type not supported. Only Grid or Span");
        } else if ((@TypeOf(b) != Grid(T)) and (@TypeOf(b) != Span(T))) {
            @compileError(@typeName(@TypeOf(b)) ++ " type not supported. Only Grid or Span");
        }
    }

    if (comptime (@TypeOf(a) == Grid(T) and @TypeOf(b) == Grid(T))) {
        std.debug.assert(a.size() == b.size());
        const out = try allocator.alloc(T, a.size());
        kernel.mulKernel(T, out, a.asFlat(), b.asFlat());
        return .{ .allocator = allocator, .data = out, .strides = a.strides, .dim = a.dim };
    } else if (comptime (@TypeOf(a) == Span(T) and @TypeOf(b) == Span(T))) {
        std.debug.assert(a.inner.len == b.inner.len);
        const out = try allocator.alloc(T, a.inner.len);
        kernel.mulKernel(T, out, a.asFlat(), b.asFlat());
        return .{
            .allocator = allocator,
            .inner = .{ .data = out, .len = a.inner.len, .stride = 1, .orient = a.inner.orient },
        };
    } else {
        @compileError("Operation between " ++ @typeName(@TypeOf(a)) ++ " and " ++ @typeName(@TypeOf(b)) ++ " is not supported");
    }
}


pub fn div(comptime T: type, allocator: Allocator, a: anytype, b: anytype) !@TypeOf(a) {
    comptime {
        if (@typeInfo(T) != .float) @compileError("Parameter T must be of type float to use the div operator");
        
        if ((@TypeOf(a) != Grid(T)) and (@TypeOf(a) != Span(T))) {
            @compileError(@typeName(@TypeOf(a)) ++ " type not supported. Only Grid or Span");
        } else if ((@TypeOf(b) != Grid(T)) and (@TypeOf(b) != Span(T))) {
            @compileError(@typeName(@TypeOf(b)) ++ " type not supported. Only Grid or Span");
        }
    }

    if (comptime (@TypeOf(a) == Grid(T) and @TypeOf(b) == Grid(T))) {
        std.debug.assert(a.size() == b.size());
        const out = try allocator.alloc(T, a.size());
        kernel.divKernel(T, out, a.asFlat(), b.asFlat());
        return .{ .allocator = allocator, .data = out, .strides = a.strides, .dim = a.dim };
    } else if (comptime (@TypeOf(a) == Span(T) and @TypeOf(b) == Span(T))) {
        std.debug.assert(a.inner.len == b.inner.len);
        const out = try allocator.alloc(T, a.inner.len);
        kernel.divKernel(T, out, a.asFlat(), b.asFlat());
        return .{
            .allocator = allocator,
            .inner = .{ .data = out, .len = a.inner.len, .stride = 1, .orient = a.inner.orient },
        };
    } else {
        @compileError("Operation between " ++ @typeName(@TypeOf(a)) ++ " and " ++ @typeName(@TypeOf(b)) ++ " is not supported");
    }
}
