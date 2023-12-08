const std = @import("std");
const parse = @import("parse.zig").parse;
const os = std.os;
const Allocator = std.mem.Allocator;
const ast = @import("ast.zig");
const monomorphize = @import("monomorphize.zig").monomorphize;
const mono = @import("mono.zig");
const compile_to_c = @import("backend_c.zig").compile_to_c;
const print_on_same_line = @import("term.zig").print_on_same_line;
const string = @import("string.zig");
const Str = string.Str;

const Command = enum { ast, mono, compile, run, watch };

pub fn main() !u8 {
    std.debug.print("Welcome to Martinaise.\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

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
        inline for (all_commands) |c| {
            if (string.eql(command_str, c.name)) {
                break :find_command @enumFromInt(c.value);
            }
        }
        print_usage_info();
        return 1;
    };

    if (command == .watch) {
        if (@import("builtin").os.tag != .linux) {
            return error.NotSupported;
        }
        const watcher = try Watcher.init(file_path);
        defer watcher.deinit();

        while (true) {
            var clear = std.ChildProcess.init(&[_]Str{"clear"}, alloc);
            clear.stdout = std.io.getStdOut();
            clear.stderr = std.io.getStdErr();
            _ = try clear.spawnAndWait();

            std.debug.print("Recompiling\n", .{});
            _ = run_pipeline(alloc, command, file_path) catch {};

            try watcher.wait_for_change();
        }
        return 0;
    } else {
        return try run_pipeline(alloc, command, file_path);
    }
}

// The high-level file watching API doesn't work on the self-hosted Zig compiler
// yet because it requires async/await. Hence, we have to make our own syscalls.
// Followed the tutorial from https://www.linuxjournal.com/article/8478
const Watcher = struct {
    inotify_fd: i32,
    watch: usize,
    buf: [buf_len]u8,

    const libc = if (@import("builtin").os.tag == .linux)
        os.linux
    else
        @compileError("Not supported");
    const event_size_without_name = @sizeOf(libc.inotify_event);
    const buf_len = (1024 * event_size_without_name) + 16;
    var buf = [_]u8{0} ** buf_len;

    const Self = @This();
    fn init(file_path: [*:0]const u8) !Self {
        const inotify_fd: i32 = @intCast(libc.inotify_init1(0));
        if (inotify_fd <= 0) return error.Todo;

        const watch = libc.inotify_add_watch(
            inotify_fd,
            file_path,
            libc.IN.MODIFY | libc.IN.CREATE | libc.IN.DELETE,
        );

        return .{
            .inotify_fd = inotify_fd,
            .watch = watch,
            .buf = [_]u8{0} ** buf_len,
        };
    }
    fn deinit(self: Self) void {
        _ = libc.close(self.inotify_fd);
    }
    // Blocking
    fn wait_for_change(self: Self) !void {
        while (true) {
            const len = libc.read(self.inotify_fd, (&buf).ptr, buf_len);
            if (len == 0) return error.Todo;
            var i: usize = 0;
            while (i < len) {
                var event: *libc.inotify_event = @alignCast(@ptrCast(&buf[i]));
                // std.debug.print("Event: {}\n", .{event});
                i += event_size_without_name + event.len;
                if (event.wd == self.watch) return;
            }
        }
    }
};

fn print_usage_info() void {
    std.debug.print("Usage: martinaise <command> <file>\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("Commands:\n", .{});
    std.debug.print("  ast      shows the abstract syntax tree\n", .{});
    std.debug.print("  mono     shows the monomorphized code\n", .{});
    std.debug.print("  compile  compiles to output.c\n", .{});
    std.debug.print("  run      compiles and runs\n", .{});
    std.debug.print("  watch    watches, compiles, and runs\n", .{});
}

fn run_pipeline(alloc: Allocator, command: Command, file_path: Str) !u8 {
    print_on_same_line("Reading {s}\n", .{file_path});

    var stdlib = try std.fs.cwd().openFile("stdlib.mar", .{});
    defer stdlib.close();
    var stdlib_len = (try stdlib.stat()).size;

    var file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
        std.debug.print("Couldn't open file: {}", .{err});
        return 1;
    };
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
    if (command == .ast) {
        print_on_same_line("Parsed {s}\n", .{file_path});
        try ast.print(std.io.getStdOut().writer(), the_ast);
        std.debug.print("\n", .{});
        return 0;
    }

    print_on_same_line("Compiling {s}\n", .{file_path});
    const the_mono = try monomorphize(alloc, the_ast);
    if (command == .mono) {
        print_on_same_line("Compiled {s}\n", .{file_path});
        try mono.print(std.io.getStdOut().writer(), the_mono);
        std.debug.print("\n", .{});
        return 0;
    }

    print_on_same_line("Compiling {s} to C\n", .{file_path});
    const c_code = try compile_to_c(alloc, the_mono);
    var c_output = try std.fs.cwd().createFile("output.c", .{});
    defer c_output.close();
    try std.fmt.format(c_output.writer(), "{s}\n", .{c_code.items});
    if (command == .compile) {
        print_on_same_line("Compiled {s} to output.c. Enjoy!\n", .{file_path});
        return 0;
    }

    print_on_same_line("Compiling C using GCC\n", .{});
    var gcc = std.ChildProcess.init(&[_]Str{ "gcc", "output.c" }, alloc);
    gcc.stdout = std.io.getStdOut();
    gcc.stderr = std.io.getStdErr();
    switch (try gcc.spawnAndWait()) {
        .Exited => |code| {
            if (code != 0) {
                return error.GccFailed;
            }
        },
        else => return error.GccFailed,
    }

    print_on_same_line("Running {s}\n", .{file_path});
    var program = std.ChildProcess.init(&[_]Str{"./a.out"}, alloc);
    program.stdout = std.io.getStdOut();
    program.stderr = std.io.getStdErr();
    const wait_result = try program.spawnAndWait();
    std.debug.print("\n", .{});
    switch (wait_result) {
        .Exited => |code| {
            std.debug.print("Program exited with {d}.\n", .{code});
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

    return 0;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
