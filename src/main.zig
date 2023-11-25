const std = @import("std");
const parse = @import("parse.zig").parse;
const ast = @import("ast.zig");
const monomorphize = @import("compile.zig").monomorphize;
const mono = @import("mono.zig");
const compile_to_c = @import("backend_c.zig").compile_to_c;
const compile_to_wasm = @import("backend_wasm.zig").compile_to_wasm;

pub fn main() !void {
    std.debug.print("Welcome to Martinaise.\n", .{});

    var my_file = try std.fs.cwd().openFile("example.mar", .{});
    defer my_file.close();

    var buf: [1024]u8 = undefined;
    const len = try my_file.read(&buf);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    const the_ast = parse(alloc, buf[0..len]) orelse return error.ParseError;
    std.debug.print("Parsed:\n", .{});
    ast.print(the_ast);
    std.debug.print("\n", .{});

    const the_mono = try monomorphize(alloc, the_ast);
    mono.print(the_mono);
    std.debug.print("\n", .{});

    const c_code = try compile_to_c(alloc, the_mono);
    // std.debug.print("C code:\n{s}\n", .{c_code.items});

    var output = try std.fs.cwd().createFile("output.c", .{});
    defer output.close();
    try std.fmt.format(output.writer(), "{s}\n", .{c_code.items});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
