const std = @import("std");
const ArrayList = std.ArrayList;
const HashMap = std.HashMap;
const StringHashMap = std.StringHashMap;
const format = std.fmt.format;
const ast = @import("ast.zig");
const string = @import("string.zig");
const String = string.String;
const Str = string.Str;
const formata = string.formata;
const mono = @import("mono.zig");
const numbers = @import("numbers.zig");
const Ty = @import("ty.zig").Ty;
const TyHashMap = @import("ty.zig").TyHashMap;

pub fn compile_to_c(alloc: std.mem.Allocator, the_mono: mono.Mono) !String {
    var out_buffer = String.init(alloc);
    const out = out_buffer.writer();

    try format(out,
        \\// This file is a compiler target.
        \\#include <unistd.h>
        \\#include <stdint.h>
        \\#include <stdlib.h>
        \\#include <fcntl.h>
        \\
        \\
    , .{});

    var builtin_tys = TyHashMap(Str).init(alloc);
    var builtin_funs = StringHashMap(Str).init(alloc);
    { // Generate code for builtins

        // libc_malloc(size: U64): U64
        try builtin_funs.put("libc_malloc(U64)",
            \\  mar_U64 address;
            \\  address.value = (uint64_t) malloc(arg0.value);
            \\  return address;
        );

        // libc_exit(status: U8): Never
        try builtin_funs.put("libc_exit(U8)",
            \\  exit(arg0.value);
            \\  mar_Nothing nothing;
            \\  return nothing;
        );

        // libc_open(filename: U64, flags: U64, mode: U64): U64
        try builtin_funs.put("libc_open(U64, U64, U64)",
            \\  mar_U64 fd;
            \\  fd.value = (uint64_t) open((char*) arg0.value, arg1.value, arg2.value);
            \\  return fd;
        );

        // libc_read(file: U64, buf: U64, len: U64): U8
        try builtin_funs.put("libc_read(U64, U64, U64)",
            \\  mar_U64 result;
            \\  result.value = read(arg0.value, (void*) arg1.value, arg2.value);
            \\  return result;
        );

        // libc_write(file: U64, buf: U64, len: U64): U8
        try builtin_funs.put("libc_write(U64, U64, U64)",
            \\  mar_U64 result;
            \\  result.value = write(arg0.value, (void*) arg1.value, arg2.value);
            \\  return result;
        );

        // libc_close(file: U64): U8
        try builtin_funs.put("libc_close(U64)",
            \\  mar_U8 result;
            \\  result.value = close(arg0.value);
            \\  return result;
        );

        for (numbers.all_int_configs()) |config| {
            const ty = try numbers.int_ty(alloc, config);

            // Type
            try builtin_tys.put(ty, try formata(alloc,
                \\struct {s} {{
                \\  {s}int{}_t value;
                \\}};
            , .{
                try mangle_ty(alloc, ty),
                switch (config.signedness) {
                    .signed => "",
                    .unsigned => "u",
                },
                config.bits,
            }));

            // add(Int, Int): Int
            try builtin_funs.put(
                try formata(alloc, "add({s}, {s})", .{ ty, ty }),
                try formata(alloc,
                    \\  mar_{s} i;
                    \\  i.value = arg0.value + arg1.value;
                    \\  return i;
                , .{ty}),
            );

            // subtract(Int, Int): Int
            try builtin_funs.put(
                try formata(alloc, "subtract({s}, {s})", .{ ty, ty }),
                try formata(alloc,
                    \\  mar_{s} i;
                    \\  i.value = arg0.value - arg1.value;
                    \\  return i;
                , .{ty}),
            );

            // multiply(Int, Int): Int
            try builtin_funs.put(
                try formata(alloc, "multiply({s}, {s})", .{ ty, ty }),
                try formata(alloc,
                    \\  mar_{s} i;
                    \\  i.value = arg0.value * arg1.value;
                    \\  return i;
                , .{ty}),
            );

            // divide(Int, Int): Int
            try builtin_funs.put(
                try formata(alloc, "divide({s}, {s})", .{ ty, ty }),
                try formata(alloc,
                    \\  mar_{s} i;
                    \\  i.value = arg0.value / arg1.value;
                    \\  return i;
                , .{ty}),
            );

            // modulo(Int, Int): Int
            try builtin_funs.put(
                try formata(alloc, "modulo({s}, {s})", .{ ty, ty }),
                try formata(alloc,
                    \\  mar_{s} i;
                    \\  i.value = arg0.value % arg1.value;
                    \\  return i;
                , .{ty}),
            );

            // and(Int, Int): Int
            try builtin_funs.put(
                try formata(alloc, "and({s}, {s})", .{ ty, ty }),
                try formata(alloc,
                    \\  mar_{s} i;
                    \\  i.value = arg0.value & arg1.value;
                    \\  return i;
                , .{ty}),
            );

            // or(Int, Int): Int
            try builtin_funs.put(
                try formata(alloc, "or({s}, {s})", .{ ty, ty }),
                try formata(alloc,
                    \\  mar_{s} i;
                    \\  i.value = arg0.value | arg1.value;
                    \\  return i;
                , .{ty}),
            );

            // xor(Int, Int): Int
            try builtin_funs.put(
                try formata(alloc, "xor({s}, {s})", .{ ty, ty }),
                try formata(alloc,
                    \\  mar_{s} i;
                    \\  i.value = arg0.value ^ arg1.value;
                    \\  return i;
                , .{ty}),
            );

            // compare_to(Int, Int): Ordering
            try builtin_funs.put(
                try formata(alloc, "compare_to({s}, {s})", .{ ty, ty }),
                try formata(alloc,
                    \\  mar_Ordering ordering;
                    \\  ordering.variant = (arg0.value == arg1.value) ?
                    \\    mar_Ordering_dot_mar_equal : (arg0.value > arg1.value) ?
                    \\      mar_Ordering_dot_mar_greater : mar_Ordering_dot_mar_less;
                    \\  mar_Nothing nothing;
                    \\  ordering.as.mar_equal = nothing;
                    \\  return ordering;
                , .{}),
            );

            // Conversion functions
            for (numbers.all_int_configs()) |target_config| {
                if (config.signedness == target_config.signedness and config.bits == target_config.bits)
                    continue;

                const target_ty = (try numbers.int_ty(alloc, target_config)).name;
                try builtin_funs.put(
                    try formata(alloc, "to_{s}({s})", .{ target_ty, ty }),
                    try formata(alloc,
                        \\  mar_{s} i;
                        \\  i.value = arg0.value;
                        \\  return i;
                    , .{target_ty}),
                );
            }
        }
    }

    { // Types
        try format(out, "/// Types\n", .{});

        var sorted = ArrayList(Ty).init(alloc);
        var reached = TyHashMap(void).init(alloc);
        var iter = the_mono.ty_defs.iterator();
        while (iter.next()) |def| {
            try sort_tys(&sorted, &reached, def.key_ptr.*, the_mono.ty_defs);
        }

        for (sorted.items) |ty| {
            try format(out, "typedef struct {s} {s};\n", .{
                try mangle_ty(alloc, ty),
                try mangle_ty(alloc, ty),
            });
        }

        for (sorted.items) |ty| {
            const def = the_mono.ty_defs.get(ty).?;
            try format(out, "\n// {s}\n", .{ty});
            switch (def) {
                .builtin_ty => if (builtin_tys.get(ty)) |impl|
                    try format(out, "{s}\n", .{impl})
                else {
                    std.debug.print("Type is {s}.\n", .{ty});
                    @panic("Unknown builtin type");
                },
                .struct_ => |s| {
                    try format(out, "struct {s} {{\n", .{
                        try mangle_ty(alloc, ty),
                    });
                    for (s.fields) |f|
                        if (string.eql(f.name, "*"))
                            try format(out, "  {s}* pointer;\n", .{
                                try mangle_ty(alloc, f.ty),
                            })
                        else
                            try format(out, "  {s} {s};\n", .{
                                try mangle_ty(alloc, f.ty),
                                try mangle(alloc, f.name),
                            });
                    try format(out, "}};\n", .{});
                },
                .enum_ => |e| {
                    try format(out, "struct {s} {{\n", .{
                        try mangle_ty(alloc, ty),
                    });
                    if (e.variants.len > 0) {
                        try format(out, "  enum {{\n", .{});
                        for (e.variants) |variant|
                            try format(out, "    {s}_dot_{s},\n", .{
                                try mangle_ty(alloc, ty),
                                try mangle(alloc, variant.name),
                            });
                        try format(out, "  }} variant;\n", .{});
                        try format(out, "  union {{\n", .{});
                        for (e.variants) |variant|
                            try format(out, "    {s} {s};\n", .{
                                try mangle_ty(alloc, variant.ty),
                                try mangle(alloc, variant.name),
                            });
                        try format(out, "  }} as;\n", .{});
                    }
                    try format(out, "}};\n", .{});
                },
                .fun => try format(out, "// TODO: compile fun types\n", .{}),
            }
        }
    }

    { // Functions
        var ordered_funs_ = ArrayList(Str).init(alloc);
        var key_iter = the_mono.funs.keyIterator();
        while (key_iter.next()) |fun| try ordered_funs_.append(fun.*);
        const ordered_funs = try ordered_funs_.toOwnedSlice();
        std.mem.sort(Str, ordered_funs, {}, string.cmp);
        var funs_to_index = StringHashMap(usize).init(alloc);
        for (ordered_funs, 0..) |fun_name, index|
            try funs_to_index.put(fun_name, index);

        // Declarations
        try format(out, "\n/// Function declarations\n\n", .{});
        for (ordered_funs) |fun_name| {
            const fun = the_mono.funs.get(fun_name) orelse unreachable;
            try format(out, "/* {s} */ {s} {s}(", .{
                fun_name,
                try mangle_ty(alloc, fun.return_ty),
                try mangle(alloc, fun_name),
            });
            for (fun.arg_tys, 0..) |arg_ty, i| {
                if (i > 0) try format(out, ", ", .{});
                try format(out, "{s} arg{}", .{ try mangle_ty(alloc, arg_ty), i });
            }
            try format(out, ");\n", .{});
        }

        // Defintions
        try format(out, "\n/// Function definitions\n", .{});
        for (ordered_funs) |fun_name| {
            const fun = the_mono.funs.get(fun_name) orelse unreachable;

            try format(out, "\n// {s}\n", .{fun_name});
            try format(out, "{s} {s}(", .{
                try mangle_ty(alloc, fun.return_ty),
                try mangle(alloc, fun_name),
            });
            for (fun.arg_tys, 0..) |arg_ty, i| {
                if (i > 0) try format(out, ", ", .{});
                try format(out, "{s} arg{}", .{ try mangle_ty(alloc, arg_ty), i });
            }
            try format(out, ") {{\n", .{});

            fun_body: {
                if (fun.is_builtin) {
                    if (builtin_funs.get(fun_name)) |body|
                        try format(out, "{s}", .{body})
                    else if (string.starts_with(fun_name, "to_address"))
                        try format(out,
                            \\  mar_U64 address;
                            \\  address.value = (uint64_t) arg0.pointer;
                            \\  return address;
                        , .{})
                    else if (string.starts_with(fun_name, "to_reference"))
                        try format(out,
                            \\  {s} ref;
                            \\  ref.pointer = ({s}*) arg0.value;
                            \\  return ref;
                        , .{
                            try mangle_ty(alloc, fun.return_ty),
                            try mangle_ty(alloc, fun.ty_args[0]),
                        })
                    else if (string.starts_with(fun_name, "size_of_type"))
                        try format(out,
                            \\  mar_U64 size;
                            \\  size.value = (uint64_t) sizeof({s});
                            \\  return size;
                        , .{try mangle_ty(alloc, fun.ty_args[0])})
                    else {
                        std.debug.print("Fun is {s}.\n", .{fun_name});
                        @panic("Unknown builtin fun");
                    }
                    break :fun_body;
                }

                for (fun.body.items, fun.tys.items, 0..) |statement, ty, i| {
                    try format(out, "  statement_{}: ", .{i});
                    switch (statement) {
                        .arg => try format(out, "{s} _{} = arg{};\n", .{ try mangle_ty(alloc, ty), i, i }),
                        .expression => |expr| try format_expr(alloc, out, expr),
                        .uninitialized => try format(out, "{s} _{};\n", .{ try mangle_ty(alloc, ty), i }),
                        .int => |int| try format(out, "{s} _{}; _{}.value = {}{s};\n", .{
                            try mangle_ty(alloc, ty),
                            i,
                            i,
                            int.value,
                            if (int.signedness == .unsigned) "ULL" else "LL",
                        }),
                        .string => |str| {
                            try format(out, "mar_Slice_of_U8_end_ _{}; _{}.mar_data.pointer = (mar_U8*) \"", .{ i, i });
                            for (str) |c|
                                try format(out, "\\x{x}", .{c});
                            try format(out, "\"; _{}.mar_len.value = {};\n", .{ i, str.len });
                        },
                        .call => |call| {
                            try format(
                                out,
                                "{s} _{} = {s}(",
                                .{ try mangle_ty(alloc, ty), i, try mangle(alloc, call.fun) },
                            );
                            for (call.args, 0..) |arg, j| {
                                if (j > 0) try format(out, ", ", .{});
                                try format_expr(alloc, out, arg);
                            }
                            try format(out, ");\n", .{});
                        },
                        .variant_creation => |vc| {
                            try format(out, "{s} _{}; _{}.variant = {s}_dot_{s}; _{}.as.{s} = ", .{
                                try mangle_ty(alloc, vc.enum_ty),
                                i,
                                i,
                                try mangle_ty(alloc, vc.enum_ty),
                                try mangle(alloc, vc.variant),
                                i,
                                try mangle(alloc, vc.variant),
                            });
                            try format_expr(alloc, out, vc.value.*);
                            try format(out, ";\n", .{});
                        },
                        .struct_creation => |sc| {
                            try format(out, "{s} _{};", .{ try mangle_ty(alloc, sc.struct_ty), i });
                            var iter = sc.fields.iterator();
                            while (iter.next()) |f| {
                                try format(out, " _{}.{s} = ", .{ i, try mangle(alloc, f.key_ptr.*) });
                                try format_expr(alloc, out, f.value_ptr.*);
                                try format(out, ";", .{});
                            }
                            try format(out, "\n", .{});
                        },
                        .assign => |assign| {
                            try format_expr(alloc, out, assign.to);
                            try format(out, " = ", .{});
                            try format_expr(alloc, out, assign.value);
                            try format(out, "; mar_Nothing _{};\n", .{i});
                        },
                        .jump => |jump| try format(out, "goto statement_{}; mar_Never _{};\n", .{ jump.target, i }),
                        .jump_if_variant => |jump| {
                            try format(out, "if ((", .{});
                            try format_expr(alloc, out, jump.condition);
                            try format(out, ").variant == {s}_dot_{s}) goto statement_{}; mar_Never _{};\n", .{
                                try mangle_ty(alloc, jump.condition.ty),
                                try mangle(alloc, jump.variant),
                                jump.target,
                                i,
                            });
                        },
                        .get_enum_value => |gev| {
                            try format(out, "{s} _{} = (", .{ try mangle_ty(alloc, gev.ty), i });
                            try format_expr(alloc, out, gev.of);
                            try format(out, ").as.{s};\n", .{try mangle(alloc, gev.variant)});
                        },
                        .return_ => |expr| {
                            // If a Never is returned, the return is not reached anyway. If we emit
                            // it, C complains that Never doesn't match the function's return type.
                            if (!expr.ty.eql(Ty.named("Never"))) {
                                try format(out, "return ", .{});
                                try format_expr(alloc, out, expr);
                                try format(out, "; ", .{});
                            }
                            try format(out, "mar_Never _{};\n", .{i});
                        },
                        .ref => |expr| {
                            try format(out, "{s} _{}; _{}.pointer = &(", .{ try mangle_ty(alloc, ty), i, i });
                            try format_expr(alloc, out, expr);
                            try format(out, ");\n", .{});
                        },
                    }
                }
                try format(out, "  statement_{}: // end\n", .{fun.body.items.len});
                const last_expr_index = fun.body.items.len - 1;
                if (!fun.tys.items[last_expr_index].eql(Ty.named("Never"))) {
                    try format(out, "  return _{};\n", .{last_expr_index});
                }
            }

            try format(out, "}}\n", .{});
        }

        try format(out,
            \\// actual main function
            \\int main(int argc, char** argv) {{
            \\   mar_Slice_of_U8_end_ args_data[argc];
            \\   for (int i = 0; i < argc; i++) {{
            \\       args_data[i].mar_data.pointer = (mar_U8*) argv[i];
            \\       int len = 0;
            \\       while (argv[i][len] != '\0') len++;
            \\       args_data[i].mar_len.value = len;
            \\   }}
            \\   mar_Slice_of_Slice_of_U8_end__end_ args;
            \\   args.mar_data.pointer = args_data;
            \\   args.mar_len.value = argc;
            \\   mar_main_withargs_Slice_of_Slice_of_U8_end__end__end_(args);
            \\ }}
        , .{});
    }

    return out_buffer;
}

fn sort_tys(out: *ArrayList(Ty), reached: *TyHashMap(void), ty: Ty, defs: mono.TyDefs) !void {
    if (reached.contains(ty)) return;
    if (string.eql(ty.name, "&")) {
        try out.append(ty);
        try reached.put(ty, {});
        return;
    }
    switch (defs.get(ty).?) {
        .builtin_ty => {
            try out.append(ty);
            try reached.put(ty, {});
        },
        .struct_ => |s| {
            for (s.fields) |field|
                try sort_tys(out, reached, field.ty, defs);
            try out.append(ty);
            try reached.put(ty, {});
        },
        .enum_ => |e| {
            for (e.variants) |variant|
                try sort_tys(out, reached, variant.ty, defs);
            try out.append(ty);
            try reached.put(ty, {});
        },
        .fun => @panic("fun type used"),
    }
}

fn format_expr(alloc: std.mem.Allocator, out: anytype, expr: mono.Expr) !void {
    switch (expr.kind) {
        .statement => |index| try format(out, "_{}", .{index}),
        .member => |member| {
            if (string.eql(member.name, "*")) {
                try format(out, "(*(", .{});
                try format_expr(alloc, out, member.of.*);
                try format(out, ".pointer))", .{});
            } else {
                try format_expr(alloc, out, member.of.*);
                try format(out, ".{s}", .{try mangle(alloc, member.name)});
            }
        },
    }
}

fn mangle(alloc: std.mem.Allocator, name: Str) !Str {
    var mangled = String.init(alloc);
    try mangled.appendSlice("mar_");
    for (name) |c| switch (c) {
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
    };
    return mangled.items;
}
fn mangle_ty(alloc: std.mem.Allocator, ty: Ty) !Str {
    var formatted = ArrayList(u8).init(alloc);
    try format(formatted.writer(), "{}", .{ty});
    return mangle(alloc, formatted.items);
}
