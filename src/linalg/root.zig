const std = @import("std");
pub const matmul = @import("matmul.zig").matmul;
pub const dot = @import("dotprod.zig").dot;

test {
    std.testing.refAllDecls(@This());
}
