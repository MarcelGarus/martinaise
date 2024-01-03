const std = @import("std");
const parse = @import("parse.zig").parse;
const format = std.fmt.format;
const os = std.os;
const Allocator = std.mem.Allocator;
const ast = @import("ast.zig");
const monomorphize = @import("monomorphize.zig").monomorphize;
const mono = @import("mono.zig");
const compile_to_c = @import("backend_c.zig").compile_to_c;
const print_on_same_line = @import("term.zig").print_on_same_line;
const clear_terminal = @import("term.zig").clear_terminal;
const string = @import("string.zig");
const Str = string.Str;
const String = string.String;
const Result = @import("result.zig").Result;
const Watcher = if (is_linux) @import("watcher.zig").Watcher else struct {};

const is_linux = @import("builtin").os.tag == .linux;

const Command = enum { ast, mono, compile, run, watch };

pub fn main() !u8 {
    std.debug.print("Welcome to Martinaise.\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var args = std.process.args();
    _ = args.skip();
    const command_str = args.next() orelse {
        print_usage_info();
        return 1;
    };
    const file_path = args.next() orelse {
        print_usage_info();
        return 1;
    };

    const command: Command = find_command: {
        const all_commands = switch (@typeInfo(Command)) {
            .Enum => |e| e.fields,
            else => unreachable,
        };
        inline for (all_commands) |c|
            if (string.eql(command_str, c.name))
                break :find_command @enumFromInt(c.value);
        print_usage_info();
        return 1;
    };

    if (is_linux and command == .watch) {
        const watcher = try Watcher.init(file_path);
        defer watcher.deinit();

        while (true) {
            try clear_terminal(alloc);

            std.debug.print("Recompiling\n", .{});
            _ = try run_pipeline(alloc, command, file_path);

            try watcher.wait_for_change();
        }
    } else return if (try run_pipeline(alloc, command, file_path)) 0 else 1;
}

fn print_usage_info() void {
    std.debug.print("Usage: martinaise <command> <file>\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("Commands:\n", .{});
    std.debug.print("  ast      shows the abstract syntax tree\n", .{});
    std.debug.print("  mono     shows the monomorphized code\n", .{});
    std.debug.print("  compile  compiles to output.c\n", .{});
    std.debug.print("  run      compiles and runs\n", .{});
    if (is_linux)
        std.debug.print("  watch    watches, compiles, and runs\n", .{});
}

// Runs the pipeline that matches the command. Errors are handled internally
// (stuff is printed to stdout). Returns whether it ran through successfully.
fn run_pipeline(original_alloc: Allocator, command: Command, file_path: Str) !bool {
    var arena = std.heap.ArenaAllocator.init(original_alloc);
    defer arena.deinit();
    const alloc = arena.allocator();

    var stdlib_size: usize = 0;
    const input = read_input: {
        print_on_same_line("Reading {s}\n", .{file_path});

        var stdlib = try std.fs.cwd().openFile("stdlib.mar", .{});
        defer stdlib.close();
        stdlib_size = (try stdlib.stat()).size;

        var file = std.fs.cwd().openFile(file_path, .{}) catch |e| {
            std.debug.print("Couldn't open file {}", .{e});
            return false;
        };
        defer file.close();
        const file_len = (try file.stat()).size;

        const total_len = stdlib_size + file_len + 2;
        var in = try alloc.alloc(u8, total_len);
        _ = try stdlib.read(in);
        in[stdlib_size] = '\n';
        _ = try file.read(in[stdlib_size + 1 ..]);
        in[total_len - 1] = '\n';

        break :read_input in;
    };

    const the_ast = parse_ast: {
        print_on_same_line("Parsing {s}\n", .{file_path});
        switch (try parse(alloc, input, stdlib_size)) {
            .ok => |the_ast| break :parse_ast the_ast,
            .err => |err| {
                std.debug.print("{s}\n", .{err});
                return false;
            },
        }
    };
    if (command == .ast) {
        try ast.print(std.io.getStdOut().writer(), the_ast);
        return true;
    }

    const the_mono = compile_mono: {
        print_on_same_line("Compiling {s}\n", .{file_path});
        switch (try monomorphize(alloc, the_ast)) {
            .ok => |the_mono| break :compile_mono the_mono,
            .err => |err| {
                print_on_same_line("{s}", .{err});
                return false;
            },
        }
    };
    if (command == .mono) {
        try mono.print(std.io.getStdOut().writer(), the_mono);
        return true;
    }

    { // Compile to C
        print_on_same_line("Compiling {s} to C\n", .{file_path});
        const c_code = try compile_to_c(alloc, the_mono);
        var output_file = try std.fs.cwd().createFile("output.c", .{});
        defer output_file.close();
        try std.fmt.format(output_file.writer(), "{s}\n", .{c_code.items});
    }
    if (command == .compile) {
        std.debug.print("Compiled to output.c. Enjoy!\n", .{});
        return true;
    }

    { // Compile C
        print_on_same_line("Compiling C using GCC\n", .{});
        var gcc = std.ChildProcess.init(&[_]Str{ "gcc", "output.c" }, alloc);
        gcc.stdout = std.io.getStdOut();
        gcc.stderr = std.io.getStdErr();
        const worked = switch (try gcc.spawnAndWait()) {
            .Exited => |code| code == 0,
            else => false,
        };
        if (!worked) {
            std.debug.print("Compiling C using GCC failed.\n", .{});
            return false;
        }
    }

    { // Run it
        print_on_same_line("Running {s}\n", .{file_path});
        var program = std.ChildProcess.init(&[_]Str{"./a.out"}, alloc);
        program.stdout = std.io.getStdOut();
        program.stderr = std.io.getStdErr();
        const start = std.time.nanoTimestamp();
        const wait_result = try program.spawnAndWait();
        const end = std.time.nanoTimestamp();
        const runtime: usize = @intCast(end - start);
        std.debug.print("\n", .{});
        switch (wait_result) {
            .Exited => |code| {
                std.debug.print("Program exited with {d} after {d} ms.\n", .{
                    code,
                    @divTrunc(runtime, 1000000),
                });
            },
            .Signal => |signal| {
                std.debug.print("Program was signalled {d}.\n", .{signal});
                return error.ProgramSignaled;
            },
            .Stopped => |val| {
                std.debug.print("Program stopped because of {d}.\n", .{val});
                return error.Todo;
            },
            .Unknown => |val| {
                std.debug.print("Waiting for program completed with unknown wait result {d}.\n", .{val});
                return error.Todo;
            },
        }
    }

    return true;
}

test "run all days" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    for (1..5) |day| {
        for ([_]Str{
            try string.formata(alloc, "advent/day{}.mar", .{day}),
            try string.formata(alloc, "advent/day{}-2.mar", .{day}),
        }) |file| {
            std.debug.print("File: {s}\n", .{file});
            if (!try run_pipeline(alloc, .run, file))
                return error.PipelineFailed;
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
