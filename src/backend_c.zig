const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const ast = @import("ast.zig");
const Name = ast.Name;
const mono = @import("mono.zig");
const format = std.fmt.format;

pub fn compile_to_c(alloc: std.mem.Allocator, the_mono: mono.Mono) !ArrayList(u8) {
    var out_buffer = ArrayList(u8).init(alloc);
    var out = out_buffer.writer();

    try format(out, "// This file is a compiler target.\n", .{});
    try format(out, "#include <stdio.h>\n\n", .{});

    { // Types
        try format(out, "/// Types\n", .{});
    
        var iter = the_mono.types.iterator();
        while (iter.next()) |item| {
            const name = item.key_ptr.*;
            const ty = item.value_ptr.*;
            try format(out, "\n// {s}\n", .{name});
            try format(out, "typedef ", .{});
            switch (ty) {
                .builtin_type => {
                    if (std.mem.eql(u8, name, "Nothing")) {
                        try format(out, "struct {{}}", .{});
                    } else if (std.mem.eql(u8, name, "Never")) {
                        try format(out, "struct {{\n", .{});
                        try format(out, "  // TODO: Is this needed?\n", .{});
                        try format(out, "}}", .{});
                    } else if (std.mem.eql(u8, name, "Int")) {
                        try format(out, "struct {{\n", .{});
                        try format(out, "  int value;\n", .{});
                        try format(out, "}}", .{});
                    } else {
                        std.debug.print("Type is {s}.\n", .{name});
                        @panic("Unknown builtin type");
                    }
                },
                .struct_ => |s| {
                    try format(out, "struct {{\n", .{});
                    for (s.fields.items) |f| {
                        try format(out, "  {s} {s};\n", .{f.type_, f.name});
                    }
                    try format(out, "}}\n", .{});
                },
                .enum_ => |_| {
                    try format(out, "enum {{\n", .{});
                    try format(out, "  // TODO\n", .{});
                    try format(out, "}}\n", .{});
                },
                .fun => {
                    try format(out, "// TODO: compile fun types\n", .{});
                },
            }
            try format(out, " {s};\n", .{(try mangle(alloc, name)).items,});
        }
    }

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

        // Declarations
        try format(out, "\n/// Function declarations\n\n", .{});
        for (ordered_funs.items) |fun_name| {
            const fun = the_mono.funs.get(fun_name) orelse unreachable;
            try format(out, "// {s}\n", .{fun_name});
            try format(out, "{s} {s}(", .{
                (try mangle(alloc, fun.return_type)).items,
                (try mangle(alloc, fun_name)).items
            });
            for (fun.arg_types.items, 0..) |arg_ty, i| {
                if (i > 0) {
                    try format(out, ", ", .{});
                }
                try format(out, "{s} arg{}", .{(try mangle(alloc, arg_ty)).items, i});
            }
            try format(out, ");\n", .{});
        }

        // Defintions
        try format(out, "\n/// Function definitions\n", .{});
        for (ordered_funs.items) |fun_name| {
            const fun = the_mono.funs.get(fun_name) orelse unreachable;

            try format(out, "\n// {s}\n", .{fun_name});
            try format(out, "{s} {s}(", .{
                (try mangle(alloc, fun.return_type)).items,
                (try mangle(alloc, fun_name)).items
            });
            for (fun.arg_types.items, 0..) |arg_ty, i| {
                if (i > 0) {
                    try format(out, ", ", .{});
                }
                try format(out, "{s} arg{}", .{(try mangle(alloc, arg_ty)).items, i});
            }
            try format(out, ") {{\n", .{});

            fun_body: {
                if (fun.is_builtin) {
                    if (std.mem.eql(u8, fun_name, "add(Int, Int)")) {
                        try format(out, "  mar_Int i;\n", .{});
                        try format(out, "  i.value = arg0.value + arg1.value;\n", .{});
                        try format(out, "  return i;\n", .{});
                        break :fun_body;
                    }
                    std.debug.print("Compiling builtin {s}\n", .{fun_name});
                    @panic("Unknown builtin function");
                }

                for (fun.expressions.items, fun.types.items, 0..) |expr, ty, i| {
                    switch (expr) {
                        .arg => try format(out, "  {s} _{} = arg{};\n", .{(try mangle(alloc, ty)).items, i, i}),
                        .number => |n| {
                            try format(out, "  {s} _{};\n", .{(try mangle(alloc, ty)).items, i});
                            try format(out, "  _{}.value = {};\n", .{i, n});
                        },
                        .call => |call| {
                            try format(out, "  {s} _{} = {s}(", .{
                                (try mangle(alloc, ty)).items,
                                i,
                                (try mangle(alloc, call.fun)).items
                            });
                            for (call.args.items, 0..) |arg, j| {
                                if (j > 0) {
                                    try format(out, ", ", .{});
                                }
                                try format(out, "_{}", .{arg});
                            }
                            try format(out, ");\n", .{});
                        },
                        .member => |member| {
                            _ = member;
                        },
                        .return_ => |index| {
                            // If a Never is returned, the return is not reached
                            // anyway. If we emit it, C complains that Never
                            // doesn't match the function's return type.
                            if (!std.mem.eql(u8, fun.types.items[@intCast(index)], "Never")) {
                                try format(out, "  return _{};\n", .{index});
                            }
                            try format(out, "  mar_Never _{};\n", .{i});
                        },
                    }
                }
                const last_expr_index = fun.expressions.items.len - 1;
                if (!std.mem.eql(u8, fun.types.items[last_expr_index], "Never")) {
                    try format(out, "  return _{};\n", .{last_expr_index});
                }
            }

            try format(out, "}}\n", .{});
        }

        try format(out, "// actual main function\n", .{});
        try format(out, "int main() {{\n", .{});
        try format(out, "  return mar_main_po__pc_().value;\n", .{});
        try format(out, "}}", .{});
    }

    return out_buffer;
}

// fn compile_fun(alloc: std.mem.Allocator, out: *ArrayList(u8), fun: mono.Fun) {}

fn mangle(alloc: std.mem.Allocator, name: Name) !ArrayList(u8) {
    var mangled = ArrayList(u8).init(alloc);
    try mangled.appendSlice("mar_");
    for (name) |c| {
        switch (c) {
            '_' => try mangled.appendSlice("__"),
            '[' => try mangled.appendSlice("_bo_"),
            ']' => try mangled.appendSlice("_bc_"),
            '(' => try mangled.appendSlice("_po_"),
            ')' => try mangled.appendSlice("_pc_"),
            ',' => try mangled.appendSlice("_c_"),
            ' ' => {},
            // 'a'...'z' || 'A'...'Z' | '0'...'9' => try mangled.append(c),
            else => try mangled.append(c),
        }
    }
    return mangled;
}
