const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const ast = @import("ast.zig");
const Name = ast.Name;
const mono = @import("mono.zig");

pub fn monomorphize(alloc: std.mem.Allocator, program: ast.Program) !mono.Mono {
    var monomorphizer = Monomorphizer {
        .alloc = alloc,
        .program = program,
        .context = ArrayList([]const u8).init(alloc),
        .types = StringHashMap(mono.Type).init(alloc),
        .funs = StringHashMap(mono.Fun).init(alloc),
    };
    try monomorphizer.types.put("Never", .builtin_type);
    try monomorphizer.types.put("Nothing", .builtin_type);
    try monomorphizer.types.put("Int", .builtin_type);

    const main = try monomorphizer.lookup("main", ArrayList(Name).init(alloc), ArrayList(Name).init(alloc));
    const main_fun = switch (main) {
        .fun => |f| f,
        else => return error.MainIsNotAFunction,
    };

    _ = monomorphizer.compile_function(main_fun, Monomorphizer.TypeEnv.init(alloc)) catch |err| {
        std.debug.print("{any}\n\nContext:\n", .{err});
        for (monomorphizer.context.items) |context| {
            std.debug.print("- {s}\n", .{context});
        }
        return err;
    };

    return mono.Mono {
        .types = monomorphizer.types,
        .funs = monomorphizer.funs,
    };
}

const Monomorphizer = struct {
    alloc: std.mem.Allocator,
    program: ast.Program,
    context: ArrayList([]const u8),
    // The keys are strings of monomorphized types such as "Maybe[Int]".
    types: StringHashMap(mono.Type),
    // The keys are strings of monomorphized function signatures such as "foo(Int)".
    funs: StringHashMap(mono.Fun),

    const Self = @This();

    // Maps type parameter names to fully monomorphized types.
    const TypeEnv = StringHashMap(Name);

    // Maps variable names to their expression index.
    const VarEnv = StringHashMap(VarInfo);
    const VarInfo = struct {
        expr_index: usize,
        ty: Name,
    };

    // Looks up the given name with the given number of type args and the args
    // of the given types.
    fn lookup(self: *Self, name: Name, type_args: ?ArrayList(Name), args: ?ArrayList(Name)) !ast.Declaration {
        var name_matches = ArrayList(ast.Declaration).init(self.alloc);
        for (self.program.declarations.items) |decl| {
            const matches = switch (decl) {
                .builtin_type => |b| strcmp(name, b.name),
                .struct_ => |s| strcmp(name, s.name),
                .enum_ => |e| strcmp(name, e.name),
                .fun => |f| strcmp(name, f.name),
            };
            if (matches) {
                try name_matches.append(decl);
            }
        }

        var type_args_matches = ArrayList(ast.Declaration).init(self.alloc);
        if (type_args) |ty_args| {
            const num_args = ty_args.items.len;
            for (name_matches.items) |decl| {
                const matches = switch (decl) {
                    .builtin_type => |_| num_args == 0,
                    .struct_ => |s| num_args == s.type_args.items.len,
                    .enum_ => |e| num_args == e.type_args.items.len,
                    .fun => |f| num_args == f.type_args.items.len,
                };
                if (matches) {
                    try type_args_matches.append(decl);
                }
            }
        } else {
            try type_args_matches.appendSlice(name_matches.items);
        }

        var everything_matches = ArrayList(ast.Declaration).init(self.alloc);
        if (args) |args_| {
            const num_args = args_.items.len;
            for (type_args_matches.items) |decl| {
                const matches = switch (decl) {
                    .builtin_type => |_| num_args == 0,
                    .struct_ => |_| num_args == 0,
                    .enum_ => |_| num_args == 0,
                    .fun => |f| num_args == f.args.items.len,
                };
                if (matches) {
                    try everything_matches.append(decl);
                }
            }
        } else {
            try everything_matches.appendSlice(type_args_matches.items);
        }

        if (everything_matches.items.len != 1) {
            std.debug.print("Looked for a definition that matches `{s}", .{name});
            if (type_args) |ty_args| {
                if (ty_args.items.len > 0) {
                    std.debug.print("[", .{});
                    for (ty_args.items, 0..) |arg, i| {
                        if (i > 0) {
                            std.debug.print(", ", .{});
                        }
                        std.debug.print("{s}", .{arg});
                    }
                    std.debug.print("]", .{});
                } 
            }
            if (args) |args_| {
                std.debug.print("(", .{});
                for (args_.items, 0..) |arg, i| {
                    if (i > 0) {
                        std.debug.print(", ", .{});
                    }
                    std.debug.print("{s}", .{arg});
                }
                std.debug.print(")", .{});
            }
            std.debug.print("`.\n", .{});
        }

        if (everything_matches.items.len > 1) {
            std.debug.print("Multiple definitions match:\n", .{});
            for (everything_matches.items) |match| {
                std.debug.print("- ", .{});
                ast.print_signature(match);
                std.debug.print("\n", .{});
            }
            return error.MultipleMatches;
        }

        if (everything_matches.items.len == 0) {
            std.debug.print("No definition matches.\n", .{});
            if (name_matches.items.len > 0) {
                std.debug.print("These definitions have the same name, but arguments don't match:\n", .{});
                for (name_matches.items) |match| {
                    std.debug.print("- ", .{});
                    ast.print_signature(match);
                    std.debug.print("\n", .{});
                }
            }
            return error.NoMatch;
        }

        return everything_matches.items[0];
    }

    fn strcmp(a: []const u8, b: []const u8) bool {
        return std.mem.eql(u8, a, b);
    }

    fn compile_function(self: *Self, fun: ast.Fun, type_env: TypeEnv) !Name {
        var signature = ArrayList(u8).init(self.alloc);
        var arg_types = ArrayList(Name).init(self.alloc);
        var var_env = VarEnv.init(self.alloc);

        try signature.appendSlice(fun.name);
        if (fun.type_args.items.len > 0) {
            try signature.appendSlice("[");
            for (fun.type_args.items, 0..) |arg, i| {
                if (i > 0) {
                    try signature.appendSlice(", ");
                }
                const arg_ty: Name = type_env.get(arg.name) orelse @panic("required type arg doesn't exist in type env");
                try signature.appendSlice(arg_ty);
            }
            try signature.appendSlice("]");
        }
        try signature.append('(');
        for (fun.args.items, 0..) |arg, i| {
            if (i > 0) {
                try signature.appendSlice(", ");
            }
            const arg_type = try self.compile_type(arg.type_, type_env);
            try arg_types.append(arg_type);
            try signature.appendSlice(arg_type);
            try var_env.put(arg.name, .{ .expr_index = i, .ty = arg_type });
        }
        try signature.append(')');
        try self.context.append(signature.items);

        const return_type = ret: {
            if (fun.return_type) |ty| {
                break :ret try self.compile_type(ty, type_env);
            } else {
                break :ret "Nothing";
            }
        };
        
        var mono_fun = mono.Fun {
            .arg_types = arg_types,
            .return_type = return_type,
            .is_builtin = fun.is_builtin,
            .expressions = ArrayList(mono.Expression).init(self.alloc),
            .types = ArrayList(Name).init(self.alloc),
        };
        for (arg_types.items) |ty| {
            try mono_fun.put(.{ .arg = {} }, ty);
        }
        for (fun.body.items) |expr| {
            _ = try self.compile_expression(&mono_fun, type_env, &var_env, expr);
        }

        try self.funs.put(signature.items, mono_fun);

        _ = self.context.pop();

        return signature.items;
    }

    fn compile_expression(
        self: *Self,
        fun: *mono.Fun,
        type_env: TypeEnv,
        var_env: *VarEnv,
        expression: ast.Expression
    ) error{
        OutOfMemory, MultipleMatches, NoMatch, TypeArgumentCalledWithGenerics,
        MultipleTypesMatch, NoTypesMatch, StructTypeArgsCannotHaveTypeArgs,
        EnumTypeArgsCannotHaveTypeArgs, InvalidExpressionCalled,
        CalledNonFunction, FunctionTypeArgsCannotHaveTypeArgs,
        ExpressionNotHandled, VariableNotInScope
    }!mono.ExpressionIndex {
        switch (expression) {
            .number => |n| try fun.put(.{ .number = n }, "Int"),
            .reference => |name| {
                if (var_env.get(name)) |var_info| {
                    return var_info.expr_index;
                }

                // TODO: Try to lookup type.
                std.debug.print("Tried to find `{s}`.\n", .{name});
                return error.VariableNotInScope;
            },
            .call => |call| {
                var args = ArrayList(mono.ExpressionIndex).init(self.alloc);
                switch (call.callee.*) {
                    // Calls of the form `something.name()` cause `something` to
                    // be treated like an extra argument.
                    .member => |member| {
                        try args.append(try self.compile_expression(fun, type_env, var_env, member.on.*));
                    },
                    else => {},
                }
                for (call.args.items) |arg| {
                    try args.append(try self.compile_expression(fun, type_env, var_env, arg));
                }

                var arg_types = ArrayList(Name).init(self.alloc);
                for (args.items) |arg| {
                    try arg_types.append(fun.types.items[@intCast(arg)]);
                }

                var type_args: ?ArrayList(Name) = null;
                if (call.type_args) |ty_args| {
                    type_args = try self.compile_types(ty_args, type_env);
                }

                const called_declaration = switch (call.callee.*) {
                    .reference => |name| try self.lookup(name, type_args, arg_types),
                    .member => |member| try self.lookup(member.member, type_args, arg_types),
                    else => return error.InvalidExpressionCalled,
                };
                const called_fun = switch (called_declaration) {
                    .fun => |f| f,
                    else => return error.CalledNonFunction,
                };
                var called_fun_type_args = ArrayList(Name).init(self.alloc);
                for (called_fun.type_args.items) |ty_arg| {
                    if (ty_arg.args.items.len > 0) {
                        return error.FunctionTypeArgsCannotHaveTypeArgs;
                    }
                    try called_fun_type_args.append(ty_arg.name);
                }

                // TODO: Unify fun signature with the argument types
                // TODO: Make sure all type args are just simple names.
                // var fun_type_args = ArrayList(Name).init(self.alloc);
                // for (fun.type_args.items) |arg| {
                //     try fun_type_args.append(arg.name);
                //     if (arg.args.items.len > 0) {
                //         return error.FunctionTypeArgsCannotHaveTypeArgs;
                //     }
                // }
                // TODO: Make sure all type args are different.
                var unified_type_args = ArrayList(Name).init(self.alloc);
                if (type_args) |ty_args| {
                    try unified_type_args.appendSlice(ty_args.items);
                }

                var fun_type_env = TypeEnv.init(self.alloc);
                for (called_fun_type_args.items, unified_type_args.items) |from, to| {
                    try fun_type_env.put(from, to);
                }
                const fun_name = try self.compile_function(called_fun, fun_type_env);
                const return_type = ret: {
                    if (called_fun.return_type) |ty| {
                        break :ret try self.compile_type(ty, fun_type_env);
                    } else {
                        break :ret "Nothing";
                    }
                };

                try fun.put(.{ .call = .{ .fun = fun_name, .args = args } }, return_type);
            },
            .member => |m| {
                const on = try self.compile_expression(fun, type_env, var_env, m.on.*);
                std.debug.print("Member on {s}\n", .{fun.types.items[on]});
            },
            .var_ => |v| {
                const value = try self.compile_expression(fun, type_env, var_env, v.value.*);
                if (v.type_) |_| {
                    // TODO: assert the value has the correct type
                }
                try var_env.put(v.name, .{
                    .expr_index = value,
                    .ty = fun.types.items[@intCast(value)]
                });
            },
            .return_ => |returned| {
                const index = try self.compile_expression(fun, type_env, var_env, returned.*);
                try fun.put(.{ .return_ = index }, "Never");
            },
            else => {
                std.debug.print("compiling {any}\n", .{expression});
                return error.ExpressionNotHandled;
            }
        }
        return fun.expressions.items.len - 1;
    }

    fn compile_types(self: *Self, tys: ArrayList(ast.Type), type_env: TypeEnv) error{
        OutOfMemory, TypeArgumentCalledWithGenerics, MultipleTypesMatch,
        NoTypesMatch, StructTypeArgsCannotHaveTypeArgs, EnumTypeArgsCannotHaveTypeArgs,
        MultipleMatches, NoMatch,
    }!ArrayList(Name) {
        var args = ArrayList(Name).init(self.alloc);
        for (tys.items) |arg| {
            try args.append(try self.compile_type(arg, type_env));
        }
        return args;
    }

    // Specializes a type such as `Maybe[T]` using a type environment such as
    // `{T: Int}` (resulting in `Maybe[Int]`). Also creates the needed specialized
    // types in the `mono.Types`.
    fn compile_type(self: *Self, ty: ast.Type, type_env: TypeEnv) !Name {
        var args = try self.compile_types(ty.args, type_env);

        if (type_env.get(ty.name)) |name| {
            if (args.items.len > 0) {
                return error.TypeArgumentCalledWithGenerics;
            }
            return name;
        }

        var name_buf = ArrayList(u8).init(self.alloc);
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

        switch (try self.lookup(ty.name, args, null)) {
            .builtin_type => |_| {
                try self.types.put(name, .builtin_type);
            },
            .struct_ => |s| {
                // Make sure all type args are just simple names.
                var struct_type_args = ArrayList(Name).init(self.alloc);
                for (s.type_args.items) |arg| {
                    if (arg.args.items.len > 0) {
                        return error.StructTypeArgsCannotHaveTypeArgs;
                    }
                    try struct_type_args.append(arg.name);
                }
                
                var inner_type_env = TypeEnv.init(self.alloc);
                for (struct_type_args.items, args.items) |from, to| {
                    try inner_type_env.put(from, to);
                }

                var fields = ArrayList(mono.Field).init(self.alloc);
                for (s.fields.items) |field| {
                    const field_type = try self.compile_type(field.type_, inner_type_env);
                    try fields.append(.{
                        .name = name,
                        .type_ = field_type,
                    });
                }
                try self.types.put(name, .{ .struct_ = .{ .fields = fields } });
            },
            .enum_ => |e| {
                // Make sure all type args are just simple names.
                var enum_type_args = ArrayList(Name).init(self.alloc);
                for (e.type_args.items) |arg| {
                    if (arg.args.items.len > 0) {
                        return error.EnumTypeArgsCannotHaveTypeArgs;
                    }
                    try enum_type_args.append(arg.name);
                }
                
                var inner_type_env = TypeEnv.init(self.alloc);
                for (enum_type_args.items, args.items) |from, to| {
                    try inner_type_env.put(from, to);
                }

                var variants = ArrayList(mono.Field).init(self.alloc);
                for (e.variants.items) |variant| {
                    const variant_type = b: {
                        if (variant.type_) |type_| {
                            break :b try self.compile_type(type_, inner_type_env);
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
};
