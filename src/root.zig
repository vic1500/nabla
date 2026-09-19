// src/root.zig
const std = @import("std");

pub const core = @import("core");
pub const linalg = @import("linalg");

test {
    std.testing.refAllDecls(@This());
}
