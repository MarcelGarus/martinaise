const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const ast = @import("ast.zig");
const Name = ast.Name;
const mono = @import("mono.zig");

pub fn compile_to_wasm(alloc: std.mem.Allocator, the_mono: mono.Mono) !ArrayList(u8) {
    var out = ArrayList(u8).init(alloc);

    try out.appendSlice("(module");

    { // Types
        var iter = the_mono.types.keyIterator();
        while (iter.next()) |ty| {
            _ = ty;
        }
    }
    var type_index: usize = 0;

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
            try out.appendSlice("\n  (type (func (param");
            for (0..fun.num_args) |_| {
                try out.appendSlice(" u32");
            }
            try out.appendSlice(")))");

            try out.appendSlice("\n  (func ");
            try out.appendSlice((try mangle(alloc, fun_name)).items);
            try out.appendSlice(" (* ");
            try out.appendSlice(fun_name);
            try out.appendSlice(" *) (type ");
            try std.fmt.format(out.writer(), "{}", .{type_index});
            type_index += 1;
            try out.appendSlice(")");
            try out.appendSlice("\n    (local");
            for (fun.types.items) |ty| {
                try compile_type(&out, the_mono, ty);
            }
            try out.appendSlice(")");
            for (fun.expressions.items, fun.types.items) |expr, ty| {
                switch (expr) {
                    .arg => {},
                    .number => |n| {
                        try out.appendSlice("\n    i32.const ");
                        try std.fmt.format(out.writer(), "{}", .{n});
                    },
                    .call => |call| {
                        try out.appendSlice("\n    call ");
                        const fun_index = funs_to_index.get(call.fun) orelse unreachable;
                        try std.fmt.format(out.writer(), "{}", .{fun_index});
                    },
                    .member => |member| {
                        _ = member;
                    },
                    .return_ => |index| {
                        _ = index;
                    },
                }
                _ = ty;
            }
            try out.appendSlice(")");
        }
    }

    try out.appendSlice(")");

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
            ',' | ' ' => try mangled.append('.'),
            // 'a'...'z' || 'A'...'Z' | '0'...'9' => try mangled.append(c),
            else => try mangled.append(c),
        }
    }
    return mangled;
}

fn compile_type(out: *ArrayList(u8), the_mono: mono.Mono, name: Name) !void {
    std.debug.print("Type is {s}.\n", .{name});
    const ty = the_mono.types.get(name) orelse unreachable;
    try out.appendSlice(" (* ");
    try out.appendSlice(name);
    try out.appendSlice(" *)");
    switch (ty) {
        .builtin_type => {
            if (std.mem.eql(u8, name, "Nothing")) {
                // only one instance, so nothing to save
            } else if (std.mem.eql(u8, name, "Never")) {
                // no instance, so nothing to save
            } else if (std.mem.eql(u8, name, "U8")) {
                try out.appendSlice(" U8");
            } else {
                std.debug.print("Type is {s}.\n", .{name});
                @panic("Unknown builtin type");
            }
        },
        .struct_ => |s| {
            for (s.fields.items) |field| {
                try compile_type(out, the_mono, field.type_);
            }
        },
        .enum_ => |e| {
            // TODO: compile
            _ = e;
        },
        .fun => |f| {
            // TODO: compile
            _ = f;
        },
    }
}
