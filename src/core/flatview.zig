
pub fn FlatView(comptime T: type) type {
    return struct {
        data: []T,
        len: usize,
        stride: usize,
    };
}