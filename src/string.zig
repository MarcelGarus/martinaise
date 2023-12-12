const std = @import("std");
const ArrayList = std.ArrayList;

pub const String = ArrayList(u8);
pub const Str = []const u8;

pub fn starts_with(buf: Str, prefix: Str) bool {
    return buf.len >= prefix.len and std.mem.eql(u8, buf[0..prefix.len], prefix);
}

pub fn eql(a: Str, b: Str) bool {
    return std.mem.eql(u8, a, b);
}
pub fn cmp(context: void, a: Str, b: Str) bool {
    _ = context;
    return switch (std.mem.order(u8, a, b)) {
        .lt => return true,
        else => return false,
    };
}

// Formats to a newly allocated string, leaking the memory.
pub fn formata(alloc: std.mem.Allocator, comptime s: Str, args: anytype) Str {
    var out = String.init(alloc);
    std.fmt.format(out.writer(), s, args) catch @panic("couldn't format");
    return out.items;
}
