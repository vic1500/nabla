// src/root.zig
const std = @import("std");

pub const core = @import("core/root.zig");
pub const linalg = @import("linalg/root.zig");

test {
    std.testing.refAllDecls(@This());
}