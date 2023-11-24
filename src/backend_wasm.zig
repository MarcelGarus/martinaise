const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const ast = @import("ast.zig");
const Name = ast.Name;
const mono = @import("mono.zig");
const format = std.fmt.format;

pub fn compile_to_wasm(alloc: std.mem.Allocator, the_mono: mono.Mono) !ArrayList(u8) {
    var out = ArrayList(u8).init(alloc);
    var writer = out.writer();

    try format(writer, "(module", .{});

    { // Functions
        var ordered_funs = ArrayList(Name).init(alloc);
        var key_iter = the_mono.funs.keyIterator();
        while (key_iter.next()) |fun| {
            try ordered_funs.append(fun.*);
        }
        var funs_to_index = StringHashMap(usize).init(alloc);
        for (ordered_funs.items, 0..) |fun_name, index| {
            try funs_to_index.put(fun_name, index);
        }
        for (ordered_funs.items) |fun_name| {
            const fun = the_mono.funs.get(fun_name) orelse unreachable;

            try format(writer, "\n  ;; {s}", .{fun_name});
            try format(writer, "\n  (func {s} (export \"{s}\")", .{(try mangle(alloc, fun_name)).items, fun_name});
            for (fun.arg_types.items, 0..) |arg_ty, i| {
                _ = arg_ty;
                try format(writer, "\n    (param $arg{} i32)", .{i});
            }
            try format(writer, "\n    (result", .{});
            for (0..type_size(the_mono, fun.return_type)) |_| {
                try format(writer, " i32", .{});
            }
            try format(writer, ")", .{});

            fun_body: {
                if (fun.is_builtin) {
                    if (std.mem.eql(u8, fun_name, "add(Int, Int)")) {
                        try format(writer, "\n    local.get $arg0", .{});
                        try format(writer, "\n    local.get $arg1", .{});
                        try format(writer, "\n    i32.add", .{});
                        break :fun_body;
                    }
                    std.debug.print("Compiling builtin {s}\n", .{fun_name});
                    @panic("Unknown builtin function");
                }

                for (0..fun.expressions.items.len) |i| {
                    try format(writer, "\n    (local ${} i32)", .{i});
                }

                for (fun.expressions.items, fun.types.items, 0..) |expr, ty, i| {
                    switch (expr) {
                        .arg => {
                            try format(writer, "\n    local.get $arg{}", .{i});
                        },
                        .number => |n| {
                            try format(writer, "\n    i32.const {}", .{n});
                        },
                        .call => |call| {
                            for (call.args.items) |arg| {
                                try format(writer, "\n    local.get ${}", .{arg});
                            }
                            try format(writer, "\n    call {s}", .{(try mangle(alloc, call.fun)).items});
                        },
                        .member => |member| {
                            _ = member;
                        },
                        .return_ => |index| {
                            _ = index;
                        },
                    }
                    _ = ty;
                    try format(writer, "\n    local.set ${}", .{i});
                }
                try format(writer, "\n    local.get ${}", .{fun.expressions.items.len - 1});
            }

            try format(writer, ")", .{});
        }

        try format(writer, "\n  ;; entry point into wasm", .{});
        try format(writer, "\n  (func $_start (export \"_start\")", .{});
        try format(writer, "\n    (result i32)", .{});
        try format(writer, "\n    call $main<>", .{});
        try format(writer, ")", .{});
    }

    try format(writer, ")", .{});

    return out;
}

// fn compile_fun(alloc: std.mem.Allocator, out: *ArrayList(u8), fun: mono.Fun) {}

fn mangle(alloc: std.mem.Allocator, name: Name) !ArrayList(u8) {
    var mangled = ArrayList(u8).init(alloc);
    try mangled.appendSlice("$");
    for (name) |c| {
        switch (c) {
            '[' => try mangled.appendSlice("<"),
            ']' => try mangled.appendSlice(">"),
            '(' => try mangled.appendSlice("<"),
            ')' => try mangled.appendSlice(">"),
            ',' => try mangled.append('.'),
            ' ' => {},
            // 'a'...'z' || 'A'...'Z' | '0'...'9' => try mangled.append(c),
            else => try mangled.append(c),
        }
    }
    return mangled;
}

// in i32, sadly
fn type_size(the_mono: mono.Mono, name: Name) usize {
    const ty = the_mono.types.get(name) orelse unreachable;
    switch (ty) {
        .builtin_type => {
            if (std.mem.eql(u8, name, "Nothing")) {
                return 0;
            } else if (std.mem.eql(u8, name, "Never")) {
                return 0;
            } else if (std.mem.eql(u8, name, "Int")) {
                return 1;
            } else {
                std.debug.print("Type is {s}.\n", .{name});
                @panic("Unknown builtin type");
            }
        },
        .struct_ => |s| {
            var total: usize = 0;
            for (s.fields.items) |field| {
                total += type_size(the_mono, field.type_);
            }
            return total;
        },
        .enum_ => |e| {
            // TODO: compile
            _ = e;
            unreachable;
        },
        .fun => |f| {
            // TODO: compile
            _ = f;
            unreachable;
        },
    }
}

// fn compile_type(out: std.io.Writer(u8), the_mono: mono.Mono, name: Name) !void {
//     std.debug.print("Type is {s}.\n", .{name});
//     const ty = the_mono.types.get(name) orelse unreachable;
//     try format(out, " (* {}");
//     try format(out, name);
//     try format(out, " *)");
//     switch (ty) {
//         .builtin_type => {
//             if (std.mem.eql(u8, name, "Nothing")) {
//                 // only one instance, so nothing to save
//             } else if (std.mem.eql(u8, name, "Never")) {
//                 // no instance, so nothing to save
//             } else if (std.mem.eql(u8, name, "U8")) {
//                 try format(out, " U8");
//             } else {
//                 std.debug.print("Type is {s}.\n", .{name});
//                 @panic("Unknown builtin type");
//             }
//         },
//         .struct_ => |s| {
//             for (s.fields.items) |field| {
//                 try compile_type(out, the_mono, field.type_);
//             }
//         },
//         .enum_ => |e| {
//             // TODO: compile
//             _ = e;
//         },
//         .fun => |f| {
//             // TODO: compile
//             _ = f;
//         },
//     }
// }
