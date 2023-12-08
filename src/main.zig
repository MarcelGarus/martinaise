const std = @import("std");
const parse = @import("parse.zig").parse;
const ast = @import("ast.zig");
const monomorphize = @import("monomorphize.zig").monomorphize;
const mono = @import("mono.zig");
const compile_to_c = @import("backend_c.zig").compile_to_c;
const print_on_same_line = @import("term.zig").print_on_same_line;

pub fn main() !void {
    std.debug.print("Welcome to Martinaise.\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    var args = std.process.args();
    _ = args.skip();
    const file_path = args.next() orelse {
        std.debug.print("You should provide the file to run.\n", .{});
        return error.NoFileProvided;
    };
    print_on_same_line("Reading {s}\n", .{file_path});

    var stdlib = try std.fs.cwd().openFile("stdlib.mar", .{});
    defer stdlib.close();
    var stdlib_len = (try stdlib.stat()).size;

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    var file_len = (try file.stat()).size;

    var total_len = stdlib_len + file_len + 2;
    var buf = try alloc.alloc(u8, total_len);
    _ = try stdlib.read(buf);
    buf[stdlib_len] = '\n';
    _ = try file.read(buf[stdlib_len + 1 ..]);
    buf[total_len - 1] = '\n';

    print_on_same_line("Parsing {s}\n", .{file_path});
    const the_ast = try parse(alloc, buf) orelse return error.ParseError;
    // std.debug.print("Parsed:\n", .{});
    // try ast.print(std.io.getStdOut().writer(), the_ast);
    // std.debug.print("\n", .{});

    print_on_same_line("Compiling {s}\n", .{file_path});
    const the_mono = try monomorphize(alloc, the_ast);
    // try mono.print(std.io.getStdOut().writer(), the_mono);
    // std.debug.print("\n", .{});

    print_on_same_line("Lowering {s}\n", .{file_path});
    const c_code = try compile_to_c(alloc, the_mono);
    // std.debug.print("C code:\n{s}\n", .{c_code.items});

    var output = try std.fs.cwd().createFile("output.c", .{});
    defer output.close();
    try std.fmt.format(output.writer(), "{s}\n", .{c_code.items});
    print_on_same_line("Compiled {s}. Enjoy!\n", .{file_path});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
