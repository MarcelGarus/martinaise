const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const ast = @import("ast.zig");
const Name = ast.Name;
const mono = @import("mono.zig");

pub fn monomorphize(alloc: std.mem.Allocator, program: ast.Program) !void {
    var types = mono.Types {
        .types = StringHashMap(mono.Type).init(alloc),
    };
    try types.put("U8", .builtin_type);

    const mains = try lookup(alloc, program, "main", 0);
    if (mains.items.len == 0) {
        return error.NoMainFunction;
    } else if (mains.items.len > 1) {
        std.debug.print("Mains:\n", .{});
        for (mains.items) |main| {
            ast.print_declaration(main);
        }
        return error.MultipleMainFunctions;
    }
    const main = switch (mains.items[0]) {
        .fun => |f| f,
        else => return error.MainIsNotAFunction,
    };

    try monomorphize_function(alloc, &types, program, main, ArrayList(Name).init(alloc));
}

fn lookup(
    alloc: std.mem.Allocator,
    program: ast.Program,
    name: Name,
    type_args: usize,
) !ArrayList(ast.Declaration) {
    var matching = ArrayList(ast.Declaration).init(alloc);
    for (program.declarations.items) |decl| {
        const matches = switch (decl) {
            .builtin_type => |b| strcmp(name, b.name) and type_args == 0,
            .struct_ => |s| strcmp(name, s.name) and type_args == s.type_args.items.len,
            .enum_ => |e| strcmp(name, e.name) and type_args == e.type_args.items.len,
            .fun => |f| strcmp(name, f.name) and type_args == f.type_args.items.len,
        };
        if (matches) {
            try matching.append(decl);
        }
    }
    return matching;
}
fn strcmp(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn monomorphize_function(
    alloc: std.mem.Allocator,
    types: *mono.Types,
    program: ast.Program,
    fun: ast.Fun,
    type_args: ArrayList(Name),
) !void {
    // Make sure all type args are just simple names.
    var fun_type_args = ArrayList(Name).init(alloc);
    for (fun.type_args.items) |arg| {
        if (arg.args.items.len > 0) {
            return error.FunctionTypeArgsCannotHaveTypeArgs;
        }
        try fun_type_args.append(arg.name);
    }
    // TODO: Make sure all type arg names are different.

    // Maps types arguments to the concrete types.
    var type_env = StringHashMap(Name).init(alloc);
    for (fun_type_args.items, type_args.items) |expected, given| {
        try type_env.putNoClobber(expected, given);
    }
    // Maps variables that are in scope to their concrete types.
    var value_env = StringHashMap(Name).init(alloc);
    for (fun.args.items) |arg| {
        try value_env.put(
            arg.name,
            try monomorphize_type(alloc, types, program, arg.type_, type_env)
        );
    }

    var body = ArrayList(mono.Expression).init(alloc);
    for (fun.body.items) |expr| {
        _ = try compile_expression(alloc, program, &body, expr);
    }
}
fn compile_expression(
    alloc: std.mem.Allocator,
    program: ast.Program,
    body: *ArrayList(mono.Expression),
    expression: ast.Expression
) !mono.ExpressionIndex {
    std.debug.print("compiling {any}\n", .{expression});
    switch (expression) {
        .number => |n| try body.append(.{ .number = n }),
        .call => |call| {
            switch (call.callee.*) {
                .reference => |name| {
                    const matches = try lookup(alloc, program, name, 0);
                    if (matches.items.len == 0) {
                        return error.FunctionNotFound;
                    }
                    if (matches.items.len > 1) {
                        std.debug.print("Multiple functions match:\n", .{});
                        for (matches.items) |fun| {
                            ast.print_declaration(fun);
                        }
                        return error.MultipleFunctionsMatch;
                    }
                },
                .member => |member| {
                    const extra_arg = try compile_expression(alloc, program, body, member.callee.*);
                    _ = extra_arg;

                    const matches = try lookup(alloc, program, member.member, 0);
                    if (matches.items.len == 0) {
                        return error.FunctionNotFound;
                    }
                    if (matches.items.len > 1) {
                        std.debug.print("Multiple functions match:\n", .{});
                        for (matches.items) |fun| {
                            ast.print_declaration(fun);
                        }
                        return error.MultipleFunctionsMatch;
                    }
                },
                else => return error.InvalidExpressionCalled,
            }

            var args = ArrayList(mono.ExpressionIndex).init(alloc);
            for (call.args.items) |arg| {
                try args.append(try compile_expression(alloc, program, body, arg));
            }
            try body.append(.{ .call = .{ .callee = "", .args = args } });
        },
        else => {
            @panic("expression not handled");
        }
    }
    const len: isize = @intCast(body.items.len);
    return len - 1;
}

fn monomorphize_types(
    alloc: std.mem.Allocator,
    types: *mono.Types,
    program: ast.Program,
    tys: ArrayList(ast.Type),
    type_env: StringHashMap(Name),
) error{
    OutOfMemory, TypeArgumentCalledWithGenerics, MultipleTypesMatch,
    NoTypesMatch, StructTypeArgsCannotHaveTypeArgs, EnumTypeArgsCannotHaveTypeArgs,
}!ArrayList(Name) {
    var args = ArrayList(Name).init(alloc);
    for (tys.items) |arg| {
        try args.append(try monomorphize_type(alloc, types, program, arg, type_env));
    }
    return args;
}

// Specializes a type such as `Maybe[T]` using a type environment such as
// `{T: U8}` (resulting in `Maybe[U8]`). Also creates the needed specialized
// types in the `mono.Types`.
fn monomorphize_type(
    alloc: std.mem.Allocator,
    types: *mono.Types,
    program: ast.Program,
    ty: ast.Type,
    type_env: StringHashMap(Name),
) !Name {
    var args = try monomorphize_types(alloc, types, program, ty.args, type_env);

    if (type_env.get(ty.name)) |name| {
        if (args.items.len > 0) {
            return error.TypeArgumentCalledWithGenerics;
        }
        return name;
    }

    const matching = try lookup(alloc, program, ty.name, args.items.len);
    if (matching.items.len > 1) {
        return error.MultipleTypesMatch;
    }
    if (matching.items.len == 0) {
        return error.NoTypesMatch;
    }

    var name_buf = ArrayList(u8).init(alloc);
    try name_buf.appendSlice(ty.name);
    if (args.items.len > 0) {
        try name_buf.append('[');
        for (args.items, 0..) |arg, i| {
            if (i > 0) {
                try name_buf.appendSlice(", ");
            }
            try name_buf.appendSlice(arg);
        }
        try name_buf.append(']');
    }
    const name = name_buf.items;

    var decl = matching.items[0];
    switch (decl) {
        .builtin_type => |_| {
            try types.put(name, .builtin_type);
        },
        .struct_ => |s| {
            // Make sure all type args are just simple names.
            var struct_type_args = ArrayList(Name).init(alloc);
            for (s.type_args.items) |arg| {
                if (arg.args.items.len > 0) {
                    return error.StructTypeArgsCannotHaveTypeArgs;
                }
                try struct_type_args.append(arg.name);
            }
            
            var inner_type_env = StringHashMap(Name).init(alloc);
            for (struct_type_args.items, args.items) |from, to| {
                try inner_type_env.put(from, to);
            }

            var fields = ArrayList(mono.Field).init(alloc);
            for (s.fields.items) |field| {
                const field_type = try monomorphize_type(alloc, types, program, field.type_, inner_type_env);
                try fields.append(.{
                    .name = name,
                    .type_ = field_type,
                });
            }
            try types.put(name, .{ .struct_ = .{ .fields = fields } });
        },
        .enum_ => |e| {
            // Make sure all type args are just simple names.
            var enum_type_args = ArrayList(Name).init(alloc);
            for (e.type_args.items) |arg| {
                if (arg.args.items.len > 0) {
                    return error.EnumTypeArgsCannotHaveTypeArgs;
                }
                try enum_type_args.append(arg.name);
            }
            
            var inner_type_env = StringHashMap(Name).init(alloc);
            for (enum_type_args.items, args.items) |from, to| {
                try inner_type_env.put(from, to);
            }

            var variants = ArrayList(mono.Field).init(alloc);
            for (e.variants.items) |variant| {
                const variant_type = b: {
                    if (variant.type_) |type_| {
                        break :b try monomorphize_type(alloc, types, program, type_, inner_type_env);
                    } else {
                        break :b "Nothing";
                    }
                };
                try variants.append(.{
                    .name = name,
                    .type_ = variant_type,
                });
            }
        },
        .fun => {
            unreachable;
        },
    }

    return name;
}
