const std = @import("std");
const Allocator = std.mem.Allocator;

const FlatView = @import("flatview.zig").FlatView;

const OpsError = error {
    DivisionByZero
};

pub fn addKernel(comptime T: type, out: []T, a: FlatView(T), b: FlatView(T)) void {
    var i: usize = 0;

    while (i < a.len) : (i += 1) {
        out[i] = a.data[i * a.stride] + b.data[i * b.stride];
    }
}

pub fn subKernel(comptime T: type, out: []T, a: FlatView(T), b:FlatView(T)) void {
    var i: usize = 0;

    while (i < a.len) : (i += 1) {
        out[i] = a.data[i * a.stride] - b.data[i * b.stride];
    }
}


pub fn mulKernel(comptime T: type, out: []T, a: FlatView(T), b:FlatView(T)) void {
    var i: usize = 0;

    while (i < a.len) : (i += 1) {
        out[i] = a.data[i * a.stride] * b.data[i * b.stride];
    }
}


pub fn divKernel(comptime T: type, out: []T, a: FlatView(T), b:FlatView(T)) OpsError!void {
    var i: usize = 0;

    while (i < a.len) : (i += 1) {
        if (b.data[i * b.stride] == 0) return error.DivisionByZero;
        out[i] = a.data[i * a.stride] / b.data[i * b.stride];
    }
}
