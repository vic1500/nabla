pub const ops = @import("ops.zig");
pub const ops_kernel = @import("ops_kernel.zig");

const std = @import("std");

test {
    std.testing.refAllDecls(@This());
}