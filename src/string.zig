const std = @import("std");
const ArrayList = std.ArrayList;

pub const String = ArrayList(u8);
pub const Str = []const u8;

pub fn starts_with(buf: Str, prefix: Str) bool {
    return buf.len >= prefix.len and std.mem.eql(u8, buf[0..prefix.len], prefix);
}

pub fn cmp(context: void, a: Str, b: Str) bool {
    _ = context;
    switch (std.mem.order(u8, a, b)) {
        .lt => return true,
        else => return false,
    }
}
