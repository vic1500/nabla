const std = @import("std");

pub fn randomNumberGen(comptime T: type, data: []T, rng: std.Random) void {
    for (data) |*value| {
        value.* = switch (@typeInfo(T)) {
            .float => rng.float(T),
            .int => rng.int(T),
            else => @compileError("Invalid data type for random number generator"),
        };
    } 

}
