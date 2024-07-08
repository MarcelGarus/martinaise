const std = @import("std");
const Str = @import("string.zig").Str;

pub fn clear_terminal(alloc: std.mem.Allocator) !void {
    var clear = std.process.Child.init(&[_]Str{"clear"}, alloc);
    clear.stdout = std.io.getStdOut();
    clear.stderr = std.io.getStdErr();
    _ = try clear.spawnAndWait();
}

pub fn print_on_same_line(comptime s: []const u8, args: anytype) void {
    std.debug.print("\x1b[1A\x1b[K", .{});
    std.debug.print(s, args);

    // std.time.sleep(20000000);
}
