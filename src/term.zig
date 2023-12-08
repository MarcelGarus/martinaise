const std = @import("std");

pub fn print_on_same_line(comptime s: []const u8, args: anytype) void {
    std.debug.print("\x1b[1A\x1b[K", .{});
    std.debug.print(s, args);
    // std.time.sleep(20000000);
}
