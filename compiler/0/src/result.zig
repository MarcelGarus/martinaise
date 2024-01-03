const Str = @import("string.zig").Str;

pub fn Result(comptime T: type) type {
    return union(enum) { ok: T, err: Str };
}
