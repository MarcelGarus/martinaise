const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const format = std.fmt.format;
const ast = @import("ast.zig");
const Name = @import("ty.zig").Name;
const mono = @import("mono.zig");
const utils = @import("utils.zig");

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

        for (utils.all_int_configs()) |config| {
            const ty = try utils.int_ty_name(alloc, config);

            { // Generate type
                var impl = ArrayList(u8).init(alloc);
                try format(impl.writer(), "struct {{\n", .{});
                try format(impl.writer(), "  {s}int{}_t value;\n", .{
                    switch (config.signedness) {
                        .signed => "",
                        .unsigned => "u",
                    },
                    config.bits,
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

            { // subtract(Int, Int)
                var signature = ArrayList(u8).init(alloc);
                try format(signature.writer(), "subtract({s}, {s})", .{ty, ty});
                var body = ArrayList(u8).init(alloc);
                try format(body.writer(), "  mar_{s} i;\n", .{ty});
                try format(body.writer(), "  i.value = arg0.value - arg1.value;\n", .{});
                try format(body.writer(), "  return i;\n", .{});
                try builtin_funs.put(signature.items, body.items);
            }

            { // multiply(Int, Int)
                var signature = ArrayList(u8).init(alloc);
                try format(signature.writer(), "multiply({s}, {s})", .{ty, ty});
                var body = ArrayList(u8).init(alloc);
                try format(body.writer(), "  mar_{s} i;\n", .{ty});
                try format(body.writer(), "  i.value = arg0.value * arg1.value;\n", .{});
                try format(body.writer(), "  return i;\n", .{});
                try builtin_funs.put(signature.items, body.items);
            }

            { // divide(Int, Int)
                var signature = ArrayList(u8).init(alloc);
                try format(signature.writer(), "divide({s}, {s})", .{ty, ty});
                var body = ArrayList(u8).init(alloc);
                try format(body.writer(), "  mar_{s} i;\n", .{ty});
                try format(body.writer(), "  i.value = arg0.value / arg1.value;\n", .{});
                try format(body.writer(), "  return i;\n", .{});
                try builtin_funs.put(signature.items, body.items);
            }

            { // modulo(Int, Int)
                var signature = ArrayList(u8).init(alloc);
                try format(signature.writer(), "modulo({s}, {s})", .{ty, ty});
                var body = ArrayList(u8).init(alloc);
                try format(body.writer(), "  mar_{s} i;\n", .{ty});
                try format(body.writer(), "  i.value = arg0.value % arg1.value;\n", .{});
                try format(body.writer(), "  return i;\n", .{});
                try builtin_funs.put(signature.items, body.items);
            }

            // Conversion functions
            for (utils.all_int_configs()) |target_config| {
                if (config.signedness == target_config.signedness and config.bits == target_config.bits) {
                    continue;
                }

                const target_ty = try utils.int_ty_name(alloc, target_config);
                var signature = ArrayList(u8).init(alloc);
                try format(signature.writer(), "to_{s}({s})", .{target_ty, ty});
                var body = ArrayList(u8).init(alloc);
                try format(body.writer(), "  mar_{s} i;\n", .{target_ty});
                try format(body.writer(), "  i.value = arg0.value;\n", .{});
                try format(body.writer(), "  return i;\n", .{});
                try builtin_funs.put(signature.items, body.items);
            }
        }

        { // print_to_stdout(U8)
            var body = ArrayList(u8).init(alloc);
            // TODO: Check the return value of putc
            try format(body.writer(), "  putc(arg0.value, stdout);\n", .{});
            try format(body.writer(), "  mar_Nothing n;\n", .{});
            try format(body.writer(), "  return n;\n", .{});
            try builtin_funs.put("print_to_stdout(U8)", body.items);
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
                    try format(out, "  }} variant;\n", .{});
                    try format(out, "  union {{\n", .{});
                    for (e.variants.items) |variant| {
                        try format(out, "    {s} mar_{s};\n", .{(try mangle(alloc, variant.ty)).items, variant.name});
                    }
                    try format(out, "  }} as;\n", .{});
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
        var ordered_funs_ = ArrayList(Name).init(alloc);
        var key_iter = the_mono.funs.keyIterator();
        while (key_iter.next()) |fun| {
            try ordered_funs_.append(fun.*);
        }
        var ordered_funs = try ordered_funs_.toOwnedSlice();
        std.mem.sort(Name, ordered_funs, {}, utils.cmpNames);
        var funs_to_index = StringHashMap(usize).init(alloc);
        for (ordered_funs, 0..) |fun_name, index| {
            try funs_to_index.put(fun_name, index);
        }

        // Declarations
        try format(out, "\n/// Function declarations\n\n", .{});
        for (ordered_funs) |fun_name| {
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
        for (ordered_funs) |fun_name| {
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
                    } else if (utils.starts_with(fun_name, "addressOf")) {
                        try format(out, "  mar_U64 address;\n", .{});
                        try format(out, "  address.value = (uint64_t)&arg0;\n", .{});
                        try format(out, "  return address;\n", .{});
                    } else {
                        std.debug.print("Fun is {s}.\n", .{fun_name});
                        @panic("Unknown builtin fun");
                    }
                    break :fun_body;
                }

                for (fun.body.items, fun.tys.items, 0..) |expr, ty, i| {
                    try format(out, "  expr_{}: ", .{i});
                    switch (expr) {
                        .arg => try format(out, "{s} _{} = arg{};\n", .{(try mangle(alloc, ty)).items, i, i}),
                        .num => |n| try format(out, "{s} _{}; _{}.value = {};\n", .{(try mangle(alloc, ty)).items, i, i, n}),
                        .call => |call| {
                            try format(out, "{s} _{} = {s}(", .{
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
                        .variant_creation => |vc| try format(out, "{s} _{}; _{}.variant = mar_{s}; _{}.as.mar_{s} = _{};\n", .{
                            (try mangle(alloc, vc.enum_ty)).items, i, i, vc.variant, i, vc.variant, vc.value
                        }),
                        .struct_creation => |sc| {
                            try format(out, "{s} _{};", .{
                                (try mangle(alloc, sc.struct_ty)).items,
                                i,
                            });
                            var iter = sc.fields.iterator();
                            while (iter.next()) |f| {
                                try format(out, " _{}.{s} = _{};", .{i, f.key_ptr.*, f.value_ptr.*});
                            }
                            try format(out, "\n", .{});
                        },
                        .member => |member| try format(out, "{s} _{} = _{}.{s};\n", .{
                            (try mangle(alloc, ty)).items, i, member.of, member.name,
                        }),
                        .assign => |assign| try format(out, "_{} = _{}; mar_Nothing _{};\n", .{assign.to, assign.value, i}),
                        .jump => |jump| try format(out, "goto expr_{};\n", .{jump.target}),
                        .jump_if => |jump| try format(out, "if (_{}.variant == mar_true) goto expr_{};\n", .{jump.condition, jump.target}),
                        .jump_if_variant => |jump| try format(out, "if (_{}.variant == mar_{s}) goto expr_{};\n", .{
                            jump.condition, jump.variant, jump.target
                        }),
                        .get_enum_value => |gev| try format(out, "{s} _{} = _{}.as.mar_{s};\n", .{
                            (try mangle(alloc, gev.ty)).items, i, gev.of, gev.variant
                        }),
                        .return_ => |index| {
                            // If a Never is returned, the return is not reached anyway. If we emit
                            // it, C complains that Never doesn't match the function's return type.
                            if (!std.mem.eql(u8, fun.tys.items[@intCast(index)], "Never")) {
                                try format(out, "return _{}; ", .{index});
                            }
                            try format(out, "mar_Never _{};\n", .{i});
                        },
                    }
                }
                try format(out, "  expr_{}: // end\n", .{fun.body.items.len});
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
