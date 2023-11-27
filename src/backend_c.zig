const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const ast = @import("ast.zig");
const Name = @import("ty.zig").Name;
const mono = @import("mono.zig");
const format = std.fmt.format;

pub fn compile_to_c(alloc: std.mem.Allocator, the_mono: mono.Mono) !ArrayList(u8) {
    var out_buffer = ArrayList(u8).init(alloc);
    var out = out_buffer.writer();

    try format(out, "// This file is a compiler target.\n", .{});
    try format(out, "#include <stdio.h>\n\n", .{});
    try format(out, "#include <stdint.h>\n\n", .{});

    var builtin_tys = StringHashMap([] const u8).init(alloc);
    var builtin_funs = StringHashMap([]const u8).init(alloc);
    { // Generate code for builtins
        try builtin_tys.put("Nothing", "struct {}");
        try builtin_tys.put("Never", "struct {\n  // TODO: Is this needed?\n}");

        for ("IU") |signedness| {
            for ([_]u8{8, 16, 32, 64}) |bits| {
                var name_buf = ArrayList(u8).init(alloc);
                try std.fmt.format(name_buf.writer(), "{c}{}", .{signedness, bits});
                const ty = name_buf.items;

                { // Generate type
                    var impl = ArrayList(u8).init(alloc);
                    try format(impl.writer(), "struct {{\n", .{});
                    try format(impl.writer(), "  {s}int{}_t value;\n", .{
                        switch (signedness) {
                            'U' => "u",
                            else => "",
                        },
                        bits,
                    });
                    try format(impl.writer(), "}}", .{});
                    try builtin_tys.put(ty, impl.items);
                }

                { // add(Int, Int)
                    var signature = ArrayList(u8).init(alloc);
                    try format(signature.writer(), "add({s}, {s})", .{ty, ty});
                    var body = ArrayList(u8).init(alloc);
                    try format(body.writer(), "  mar_{s} i;\n", .{ty});
                    try format(body.writer(), "  i.value = arg0.value + arg1.value;\n", .{});
                    try format(body.writer(), "  return i;\n", .{});
                    try builtin_funs.put(signature.items, body.items);
                }
            }
        }
    }

    { // Types
        try format(out, "/// Types\n", .{});
    
        var iter = the_mono.ty_defs.iterator();
        while (iter.next()) |def| {
            const name = def.key_ptr.*;
            const ty = def.value_ptr.*;
            try format(out, "\n// {s}\n", .{name});
            try format(out, "typedef ", .{});
            switch (ty) {
                .builtin_ty => {
                    if (builtin_tys.get(name)) |impl| {
                        try format(out, "{s}", .{impl});
                    } else {
                        std.debug.print("Type is {s}.\n", .{name});
                        @panic("Unknown builtin type");
                    }
                },
                .struct_ => |s| {
                    try format(out, "struct {{\n", .{});
                    for (s.fields.items) |f| {
                        try format(out, "  {s} {s};\n", .{(try mangle(alloc, f.ty)).items, f.name});
                    }
                    try format(out, "}}", .{});
                },
                .enum_ => |e| {
                    try format(out, "struct {{\n", .{});
                    try format(out, "  enum {{\n", .{});
                    for (e.variants.items) |variant| {
                        try format(out, "    mar_{s},\n", .{variant.name});
                    }
                    try format(out, "  }} kind;\n", .{});
                    try format(out, "}}", .{});
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
            try format(out, "/* {s} */ {s} {s}(", .{
                fun_name,
                (try mangle(alloc, fun.return_ty)).items,
                (try mangle(alloc, fun_name)).items
            });
            for (fun.arg_tys.items, 0..) |arg_ty, i| {
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
                (try mangle(alloc, fun.return_ty)).items,
                (try mangle(alloc, fun_name)).items
            });
            for (fun.arg_tys.items, 0..) |arg_ty, i| {
                if (i > 0) {
                    try format(out, ", ", .{});
                }
                try format(out, "{s} arg{}", .{(try mangle(alloc, arg_ty)).items, i});
            }
            try format(out, ") {{\n", .{});

            fun_body: {
                if (fun.is_builtin) {
                    if (builtin_funs.get(fun_name)) |body| {
                        try format(out, "{s}", .{body});
                    } else {
                        std.debug.print("Fun is {s}.\n", .{fun_name});
                        @panic("Unknown builtin fun");
                    }
                    break :fun_body;
                }

                for (fun.body.items, fun.tys.items, 0..) |expr, ty, i| {
                    switch (expr) {
                        .arg => try format(out, "  {s} _{} = arg{};\n", .{(try mangle(alloc, ty)).items, i, i}),
                        .num => |n| {
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
                        .variant_creation => |vc| {
                            try format(out, "  {s} _{};\n", .{
                                (try mangle(alloc, vc.enum_ty)).items,
                                i,
                            });
                            try format(out, "  _{}.kind = mar_{s};\n", .{
                                i,
                                vc.variant,
                            });
                        },
                        .struct_creation => |sc| {
                            try format(out, "  {s} _{};\n", .{
                                (try mangle(alloc, sc.struct_ty)).items,
                                i,
                            });
                            var iter = sc.fields.iterator();
                            while (iter.next()) |f| {
                                try format(out, "  _{}.{s} = _{};\n", .{i, f.key_ptr.*, f.value_ptr.*});
                            }
                        },
                        .member => |member| {
                            try format(out, "  {s} _{} = _{}.{s};\n", .{
                                (try mangle(alloc, ty)).items,
                                i,
                                member.of,
                                member.name,
                            });
                        },
                        .assign => |assign| {
                            try format(out, "  _{} = _{};\n", .{assign.to, assign.value});
                            try format(out, "  mar_Nothing _{};\n", .{i});
                        },
                        .return_ => |index| {
                            // If a Never is returned, the return is not reached anyway. If we emit
                            // it, C complains that Never doesn't match the function's return type.
                            if (!std.mem.eql(u8, fun.tys.items[@intCast(index)], "Never")) {
                                try format(out, "  return _{};\n", .{index});
                            }
                            try format(out, "  mar_Never _{};\n", .{i});
                        },
                    }
                }
                const last_expr_index = fun.body.items.len - 1;
                if (!std.mem.eql(u8, fun.tys.items[last_expr_index], "Never")) {
                    try format(out, "  return _{};\n", .{last_expr_index});
                }
            }

            try format(out, "}}\n", .{});
        }

        try format(out, "\n// actual main function\n", .{});
        try format(out, "int main() {{\n", .{});
        try format(out, "  return mar_main_po__pc_().value;\n", .{});
        try format(out, "}}", .{});
    }

    return out_buffer;
}

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
