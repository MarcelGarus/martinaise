const std = @import("std");
const ast = @import("ast.zig");

pub fn parse(alloc: std.mem.Allocator, code: []u8) ?Parsed(ast.Program) {
    // std.debug.print("Compiling code:\n{s}\n", .{code});
    // return ast.Program.builtin_type("hi");
    // unreachable;
    // return .{
    //     .name = code[0..10],
    //     .arguments = std.ArrayList(ast.Type).init(alloc)
    // };
    return parse_program(alloc, code);
}

fn Parsed(comptime T: type) type {
    return struct {
        code: []u8,
        parsed: T,
    };
}

fn parse_whitespace(code_: []u8) ?Parsed(void) {
    var code = code_;

    var parsed_something = false;
    loop: while (code.len > 0) {
        switch (code[0]) {
            ' ', '\t', '\n' => {
                parsed_something = true;
                code = code[1..];
            },
            else => break :loop,
        }
    }

    if (parsed_something) {
        return .{
            .code = code,
            .parsed = {}
        };
    } else {
        return null;
    }
}

fn parse_prefix(code: []u8, prefix: []const u8) ?Parsed(void) {
    if (code.len < prefix.len) {
        return null;
    }
    for (prefix, code[0..prefix.len]) |a, b| {
        if (a != b) {
            return null;
        }
    }
    return .{
        .code = code[prefix.len..],
        .parsed = {}
    };
}

fn parse_program(alloc: std.mem.Allocator, code_: []u8) ?Parsed(ast.Program) {
    var code = code_;
    var declarations = std.ArrayList(ast.Declaration).init(alloc);
    
    var len = code.len;
    while (true) {
        if (parse_whitespace(code)) |w| {
            code = w.code;
        }

        if (parse_builtin_type(code)) |bt| {
            code = bt.code;
            declarations.append(.{ .builtin_type = bt.parsed }) catch { unreachable; };
        }

        const newlen = code.len;
        if (newlen == len) {
            break; // Nothing more got parsed.
        } else {
            len = newlen;
        }
    }

    return .{
        .code = code,
        .parsed = .{ .declarations = declarations }
    };
}

fn parse_builtin_type(code_: []u8) ?Parsed(ast.Name) {
    var code = code_;

    code = (parse_prefix(code, "builtinType") orelse return null).code;
    if (parse_whitespace(code)) |w| {
        code = w.code;
    } else {
        return null;
    }

    return parse_name(code);
}

fn parse_name(code: []u8) ?Parsed(ast.Name) {
    var i: usize = 0;
    loop: while (true) {
        switch (code[i]) {
            'A'...'Z', 'a'...'z' => i += 1,
            '0'...'9' => if (i == 0) {
                break :loop;
            } else {
                i += 1;
            },
            else => break :loop,
        }
    }
    if (i == 0) {
        return null;
    } else {
        return .{
            .code = code[i..],
            .parsed = code[0..i]
        };
    }
}

fn parse_type(alloc: std.mem.Allocator, code_: []u8) ?Parsed(ast.Type) {
    var code = code_;
    
    // Parse the name of the type.
    const a = parse_name(code) orelse return null;
    const name = a.parsed;
    code = a.code;

    if (parse_whitespace(code)) |b| {
        code = b.code;
    }

    // Parse type arguments.
    var type_arguments = std.ArrayList(ast.Type).init(alloc);
    if (parse_prefix(code, "[")) |b| {
        code = b.code;

        if (parse_whitespace(code)) |c| {
            code = c.code;
        }

        while (true) {
            if (parse_type(alloc, code)) |c| {
                type_arguments.append(c.parsed) catch {
                    unreachable;
                };
                code = c.code;
            } else {
                // TODO: do stuff
                unreachable;
            }
            if (parse_whitespace(code)) |c| {
                code = c.code;
            }
            if (parse_prefix(code, ",")) |c| {
                code = c.code;
            }
            if (parse_whitespace(code)) |c| {
                code = c.code;
            }
            if (parse_prefix(code, "]")) |c| {
                code = c.code;
                break;
            }
        }
    }

    // _ = name;

    // std.debug.print("Compiling code:\n{s}\n", .{code});
    // return ast.Program.builtin_type("hi");
    return .{
        .code = code,
        .parsed = .{
            .name = name,
            .arguments = type_arguments
        }
    };
}





