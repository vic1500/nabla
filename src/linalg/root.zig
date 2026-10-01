const std = @import("std");
pub const matmul = @import("matmul.zig").matmul;
test {
    std.testing.refAllDecls(@This());
}
