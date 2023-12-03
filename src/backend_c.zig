const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const format = std.fmt.format;
const ast = @import("ast.zig");
const string_mod = @import("string.zig");
const String = string_mod.String;
const Str = string_mod.Str;
const mono = @import("mono.zig");
const numbers = @import("numbers.zig");

pub fn compile_to_c(alloc: std.mem.Allocator, the_mono: mono.Mono) !String {
    var out_buffer = String.init(alloc);
    var out = out_buffer.writer();

    try format(out, "// This file is a compiler target.\n", .{});
    try format(out, "#include <stdio.h>\n\n", .{});
    try format(out, "#include <stdint.h>\n\n", .{});
    try format(out, "#include <stdlib.h>\n\n", .{});

    var builtin_tys = StringHashMap(Str).init(alloc);
    var builtin_funs = StringHashMap(Str).init(alloc);
    { // Generate code for builtins
        try builtin_tys.put("Nothing", "struct {}");
        try builtin_tys.put("Never", "struct {\n  // TODO: Is this needed?\n}");

        { // malloc(U64)
            var signature = String.init(alloc);
            try format(signature.writer(), "malloc(U64)", .{});
            var body = String.init(alloc);
            try format(body.writer(), "  mar_U64 address;\n", .{});
            try format(body.writer(), "  address.value = (uint64_t) malloc(arg0.value);\n", .{});
            try format(body.writer(), "  if (!address.value) {{\n", .{});
            try format(body.writer(), "    printf(\"OOM\");\n", .{});
            try format(body.writer(), "    exit(-1);\n", .{});
            try format(body.writer(), "  }}\n", .{});
            try format(body.writer(), "  return address;\n", .{});
            try builtin_funs.put(signature.items, body.items);
        }

        for (numbers.all_int_configs()) |config| {
            const ty = try numbers.int_ty_name(alloc, config);

            { // Generate type
                var impl = String.init(alloc);
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
                var signature = String.init(alloc);
                try format(signature.writer(), "add({s}, {s})", .{ ty, ty });
                var body = String.init(alloc);
                try format(body.writer(), "  mar_{s} i;\n", .{ty});
                try format(body.writer(), "  i.value = arg0.value + arg1.value;\n", .{});
                try format(body.writer(), "  return i;\n", .{});
                try builtin_funs.put(signature.items, body.items);
            }

            { // subtract(Int, Int)
                var signature = String.init(alloc);
                try format(signature.writer(), "subtract({s}, {s})", .{ ty, ty });
                var body = String.init(alloc);
                try format(body.writer(), "  mar_{s} i;\n", .{ty});
                try format(body.writer(), "  i.value = arg0.value - arg1.value;\n", .{});
                try format(body.writer(), "  return i;\n", .{});
                try builtin_funs.put(signature.items, body.items);
            }

            { // multiply(Int, Int)
                var signature = String.init(alloc);
                try format(signature.writer(), "multiply({s}, {s})", .{ ty, ty });
                var body = String.init(alloc);
                try format(body.writer(), "  mar_{s} i;\n", .{ty});
                try format(body.writer(), "  i.value = arg0.value * arg1.value;\n", .{});
                try format(body.writer(), "  return i;\n", .{});
                try builtin_funs.put(signature.items, body.items);
            }

            { // divide(Int, Int)
                var signature = String.init(alloc);
                try format(signature.writer(), "divide({s}, {s})", .{ ty, ty });
                var body = String.init(alloc);
                try format(body.writer(), "  mar_{s} i;\n", .{ty});
                try format(body.writer(), "  i.value = arg0.value / arg1.value;\n", .{});
                try format(body.writer(), "  return i;\n", .{});
                try builtin_funs.put(signature.items, body.items);
            }

            { // modulo(Int, Int)
                var signature = String.init(alloc);
                try format(signature.writer(), "modulo({s}, {s})", .{ ty, ty });
                var body = String.init(alloc);
                try format(body.writer(), "  mar_{s} i;\n", .{ty});
                try format(body.writer(), "  i.value = arg0.value % arg1.value;\n", .{});
                try format(body.writer(), "  return i;\n", .{});
                try builtin_funs.put(signature.items, body.items);
            }

            { // compare_to(Int, Int)
                var signature = String.init(alloc);
                try format(signature.writer(), "compare_to({s}, {s})", .{ ty, ty });
                var body = String.init(alloc);
                try format(body.writer(), "  mar_Ordering ordering;\n", .{});
                try format(body.writer(), "  ordering.variant = (arg0.value == arg1.value) ? mar_Ordering_dot_mar_equal : (arg0.value > arg1.value) ? mar_Ordering_dot_mar_greater : mar_Ordering_dot_mar_less;\n", .{});
                try format(body.writer(), "  mar_Nothing nothing;\n", .{});
                try format(body.writer(), "  ordering.as.mar_equal = nothing;\n", .{});
                try format(body.writer(), "  return ordering;\n", .{});
                try builtin_funs.put(signature.items, body.items);
            }

            // Conversion functions
            for (numbers.all_int_configs()) |target_config| {
                if (config.signedness == target_config.signedness and config.bits == target_config.bits) {
                    continue;
                }

                const target_ty = try numbers.int_ty_name(alloc, target_config);
                var signature = String.init(alloc);
                try format(signature.writer(), "to_{s}({s})", .{ target_ty, ty });
                var body = String.init(alloc);
                try format(body.writer(), "  mar_{s} i;\n", .{target_ty});
                try format(body.writer(), "  i.value = arg0.value;\n", .{});
                try format(body.writer(), "  return i;\n", .{});
                try builtin_funs.put(signature.items, body.items);
            }
        }

        { // print_to_stdout(U8): Nothing
            var body = String.init(alloc);
            // TODO: Check the return value of putc
            try format(body.writer(), "  putc(arg0.value, stdout);\n", .{});
            try format(body.writer(), "  mar_Nothing n;\n", .{});
            try format(body.writer(), "  return n;\n", .{});
            try builtin_funs.put("print_to_stdout(U8)", body.items);
        }

        { // read_file(Str): Str
            var body = String.init(alloc);
            try format(body.writer(), "  char* path = (char*)arg0.mar_bytes.mar_data.pointer;\n", .{});
            try format(body.writer(), "  FILE* file = fopen(path, \"r\");\n", .{});
            try format(body.writer(), "  if (!file) {{\n", .{});
            try format(body.writer(), "    printf(\"Not able to open %s.\\n\", path);\n", .{});
            try format(body.writer(), "    exit(-1);\n", .{});
            try format(body.writer(), "  }}\n", .{});
            try format(body.writer(), "  int capacity = 32, len = 0;\n", .{});
            try format(body.writer(), "  char* content = malloc(capacity);\n", .{});
            try format(body.writer(), "  char c;\n", .{});
            try format(body.writer(), "  do {{\n", .{});
            try format(body.writer(), "    c = fgetc(file);\n", .{});
            try format(body.writer(), "    if (len == capacity) {{\n", .{});
            try format(body.writer(), "      capacity *= 2;\n", .{});
            try format(body.writer(), "      content = realloc(content, capacity);\n", .{});
            try format(body.writer(), "    }}\n", .{});
            try format(body.writer(), "    content[len] = c;\n", .{});
            try format(body.writer(), "    len++;\n", .{});
            try format(body.writer(), "  }} while (c != EOF);\n", .{});
            try format(body.writer(), "  fclose(file);\n", .{});
            try format(body.writer(), "\n", .{});
            try format(body.writer(), "  mar_Str content_str;\n", .{});
            try format(body.writer(), "  content_str.mar_bytes.mar_data.pointer = (mar_U8*) content;\n", .{});
            try format(body.writer(), "  content_str.mar_bytes.mar_len.value = len;\n", .{});
            try format(body.writer(), "  return content_str;\n", .{});
            try builtin_funs.put("read_file(Str)", body.items);
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
                        if (std.mem.eql(u8, f.name, "*")) {
                            // This is the field in the & struct.
                            try format(out, "  {s}* pointer;\n", .{try mangle(alloc, f.ty)});
                            continue;
                        }
                        try format(out, "  {s} {s};\n", .{ try mangle(alloc, f.ty), try mangle(alloc, f.name) });
                    }
                    try format(out, "}}", .{});
                },
                .enum_ => |e| {
                    try format(out, "struct {{\n", .{});
                    try format(out, "  enum {{\n", .{});
                    for (e.variants.items) |variant| {
                        try format(out, "    {s}_dot_{s},\n", .{
                            try mangle(alloc, name),
                            try mangle(alloc, variant.name),
                        });
                    }
                    try format(out, "  }} variant;\n", .{});
                    try format(out, "  union {{\n", .{});
                    for (e.variants.items) |variant| {
                        try format(out, "    {s} {s};\n", .{ try mangle(alloc, variant.ty), try mangle(alloc, variant.name) });
                    }
                    try format(out, "  }} as;\n", .{});
                    try format(out, "}}", .{});
                },
                .fun => {
                    try format(out, "// TODO: compile fun types\n", .{});
                },
            }
            try format(out, " {s};\n", .{try mangle(alloc, name)});
        }
    }

    { // Functions
        var ordered_funs_ = ArrayList(Str).init(alloc);
        var key_iter = the_mono.funs.keyIterator();
        while (key_iter.next()) |fun| {
            try ordered_funs_.append(fun.*);
        }
        var ordered_funs = try ordered_funs_.toOwnedSlice();
        std.mem.sort(Str, ordered_funs, {}, string_mod.cmp);
        var funs_to_index = StringHashMap(usize).init(alloc);
        for (ordered_funs, 0..) |fun_name, index| {
            try funs_to_index.put(fun_name, index);
        }

        // Declarations
        try format(out, "\n/// Function declarations\n\n", .{});
        for (ordered_funs) |fun_name| {
            const fun = the_mono.funs.get(fun_name) orelse unreachable;
            try format(out, "/* {s} */ {s} {s}(", .{ fun_name, try mangle(alloc, fun.return_ty), try mangle(alloc, fun_name) });
            for (fun.arg_tys.items, 0..) |arg_ty, i| {
                if (i > 0) {
                    try format(out, ", ", .{});
                }
                try format(out, "{s} arg{}", .{ try mangle(alloc, arg_ty), i });
            }
            try format(out, ");\n", .{});
        }

        // Defintions
        try format(out, "\n/// Function definitions\n", .{});
        for (ordered_funs) |fun_name| {
            const fun = the_mono.funs.get(fun_name) orelse unreachable;

            try format(out, "\n// {s}\n", .{fun_name});
            try format(out, "{s} {s}(", .{ try mangle(alloc, fun.return_ty), try mangle(alloc, fun_name) });
            for (fun.arg_tys.items, 0..) |arg_ty, i| {
                if (i > 0) {
                    try format(out, ", ", .{});
                }
                try format(out, "{s} arg{}", .{ try mangle(alloc, arg_ty), i });
            }
            try format(out, ") {{\n", .{});

            fun_body: {
                if (fun.is_builtin) {
                    if (builtin_funs.get(fun_name)) |body| {
                        try format(out, "{s}", .{body});
                    } else if (string_mod.starts_with(fun_name, "to_address")) {
                        try format(out, "  mar_U64 address;\n", .{});
                        try format(out, "  address.value = (uint64_t)arg0.pointer;\n", .{});
                        try format(out, "  return address;\n", .{});
                    } else if (string_mod.starts_with(fun_name, "to_reference")) {
                        try format(out, "  {s} ref;\n", .{try mangle(alloc, fun.return_ty)});
                        try format(out, "  ref.pointer = ({s}*) arg0.value;\n", .{
                            try mangle(alloc, fun.ty_args.items[0]),
                        });
                        try format(out, "  return ref;\n", .{});
                    } else if (string_mod.starts_with(fun_name, "size_of_type")) {
                        try format(out, "  mar_U64 size;\n", .{});
                        try format(out, "  size.value = (uint64_t)sizeof({s});\n", .{
                            try mangle(alloc, fun.ty_args.items[0]),
                        });
                        try format(out, "  return size;\n", .{});
                    } else {
                        std.debug.print("Fun is {s}.\n", .{fun_name});
                        @panic("Unknown builtin fun");
                    }
                    break :fun_body;
                }

                for (fun.body.items, fun.tys.items, 0..) |expr, ty, i| {
                    try format(out, "  expr_{}: ", .{i});
                    switch (expr) {
                        .arg => try format(out, "{s} _{} = arg{};\n", .{ try mangle(alloc, ty), i, i }),
                        .uninitialized => try format(out, "{s} _{};\n", .{ try mangle(alloc, ty), i }),
                        .int => |int| try format(out, "{s} _{}; _{}.value = {}{s};\n", .{ try mangle(alloc, ty), i, i, int.value, suffix: {
                            if (int.signedness == .unsigned) {
                                break :suffix "ULL";
                            } else {
                                break :suffix "LL";
                            }
                        } }),
                        .string => |str| {
                            try format(out, "mar_Str _{}; _{}.mar_bytes.mar_data.pointer = (mar_U8*) \"", .{ i, i });
                            for (str) |c| {
                                try format(out, "\\x{x}", .{c});
                            }
                            try format(out, "\"; _{}.mar_bytes.mar_len.value = {};", .{ i, str.len });
                        },
                        .call => |call| {
                            try format(out, "{s} _{} = {s}(", .{ try mangle(alloc, ty), i, try mangle(alloc, call.fun) });
                            for (call.args.items, 0..) |arg, j| {
                                if (j > 0) {
                                    try format(out, ", ", .{});
                                }
                                try format(out, "_{}", .{arg});
                            }
                            try format(out, ");\n", .{});
                        },
                        .copy => |copied| {
                            try format(out, "{s} _{} = _{};", .{ try mangle(alloc, ty), i, copied });
                        },
                        .variant_creation => |vc| try format(out, "{s} _{}; _{}.variant = {s}_dot_{s}; _{}.as.{s} = _{};\n", .{
                            try mangle(alloc, vc.enum_ty),
                            i,
                            i,
                            try mangle(alloc, vc.enum_ty),
                            try mangle(alloc, vc.variant),
                            i,
                            try mangle(alloc, vc.variant),
                            vc.value,
                        }),
                        .struct_creation => |sc| {
                            try format(out, "{s} _{};", .{ try mangle(alloc, sc.struct_ty), i });
                            var iter = sc.fields.iterator();
                            while (iter.next()) |f| {
                                try format(out, " _{}.{s} = _{};", .{ i, try mangle(alloc, f.key_ptr.*), f.value_ptr.* });
                            }
                            try format(out, "\n", .{});
                        },
                        .member => |member| {
                            if (std.mem.eql(u8, member.name, "*")) {
                                try format(out, "{s} _{} = *_{}.pointer;\n", .{ try mangle(alloc, ty), i, member.of });
                            } else {
                                try format(out, "{s} _{} = _{}.{s};\n", .{
                                    try mangle(alloc, ty), i, member.of, try mangle(alloc, member.name),
                                });
                            }
                        },
                        .assign => |assign| {
                            try format_left_expr(alloc, out, assign.to);
                            try format(out, " = _{}; mar_Nothing _{};\n", .{ assign.value, i });
                        },
                        .jump => |jump| try format(out, "goto expr_{}; mar_Never _{};\n", .{ jump.target, i }),
                        .jump_if_variant => |jump| try format(out, "if (_{}.variant == {s}_dot_{s}) goto expr_{}; mar_Never _{};\n", .{
                            jump.condition,
                            try mangle(alloc, fun.tys.items[jump.condition]),
                            try mangle(alloc, jump.variant),
                            jump.target,
                            i,
                        }),
                        .get_enum_value => |gev| try format(out, "{s} _{} = _{}.as.{s};\n", .{
                            try mangle(alloc, gev.ty),
                            i,
                            gev.of,
                            try mangle(alloc, gev.variant),
                        }),
                        .return_ => |index| {
                            // If a Never is returned, the return is not reached anyway. If we emit
                            // it, C complains that Never doesn't match the function's return type.
                            if (!std.mem.eql(u8, fun.tys.items[@intCast(index)], "Never")) {
                                try format(out, "return _{}; ", .{index});
                            }
                            try format(out, "mar_Never _{};\n", .{i});
                        },
                        .take_ref => |index| try format(out, "{s} _{}; _{}.pointer = &_{};\n", .{ try mangle(alloc, ty), i, i, index }),
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
        try format(out, "  return {s}().value;\n", .{try mangle(alloc, "main()")});
        try format(out, "}}", .{});
    }

    return out_buffer;
}

fn format_left_expr(alloc: std.mem.Allocator, out: anytype, expr: mono.LeftExpr) !void {
    switch (expr.kind) {
        .ref => |index| try format(out, "_{}", .{index}),
        .member => |member| {
            if (std.mem.eql(u8, member.name, "*")) {
                try format(out, "(*(({s}*) ", .{try mangle(alloc, expr.ty)});
                try format_left_expr(alloc, out, member.of.*);
                try format(out, ".pointer))", .{});
            } else {
                try format_left_expr(alloc, out, member.of.*);
                try format(out, ".{s}", .{try mangle(alloc, member.name)});
            }
        },
        .deref => |_| {},
    }
}

fn mangle(alloc: std.mem.Allocator, name: Str) !Str {
    var mangled = String.init(alloc);
    try mangled.appendSlice("mar_");
    for (name) |c| {
        switch (c) {
            '_' => try mangled.appendSlice("__"),
            '[' => try mangled.appendSlice("_of_"),
            ']' => try mangled.appendSlice("_end_"),
            '(' => try mangled.appendSlice("_withargs_"),
            ')' => try mangled.appendSlice("_end_"),
            ',' => try mangled.appendSlice("_and_"),
            '&' => try mangled.appendSlice("_amp_"),
            '*' => try mangled.appendSlice("_star_"),
            ' ' => {},
            else => try mangled.append(c),
        }
    }
    return mangled.items;
}
