const std = @import("std");
const Span = @import("core").Span;

pub fn dot(comptime T: type, a: Span(T), b:Span(T)) T {
    std.debug.assert(a.inner.len == b.inner.len);

    var c = @as(T, 0);

    for (a.inner.data, b.inner.data) |av, bv| {
        c += av * bv;
    }

    return c;
}

test "Test Dot Product" {
    const allocator = std.testing.allocator;

    const span_1 = try Span(i16).create(allocator, &.{1, 2, 3, 4, 5, 6}, .row);
    const span_2 = try Span(i16).create(allocator, &.{7, 8, 9, 10, 11, 12}, .col);

    defer span_1.destroy();
    defer span_2.destroy();

    const dot_value = dot(i16, span_1, span_2);

    try std.testing.expect(dot_value == @as(i16, 217));
}
