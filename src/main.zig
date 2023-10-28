const std = @import("std");
const ast = @import("ast.zig");
const parse = @import("parse.zig").parse;

pub fn main() !void {
    std.debug.print("Welcome to Martinaise.\n", .{});

    var my_file = try std.fs.cwd().openFile("example.mar", .{});
    defer my_file.close();

    var buf: [1024]u8 = undefined;
    _ = try my_file.read(&buf);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    const the_ast = parse(alloc, &buf);
    // _ = the_ast;
    std.debug.print("Parsed:\n", .{});
    if (the_ast) |a| {
        ast.print(a);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
