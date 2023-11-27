const std = @import("std");
const ArrayList = std.ArrayList;
const StringArrayHashMap = std.StringArrayHashMap;
const StringHashMap = std.StringHashMap;
const format = std.fmt.format;
const Ty = @import("ty.zig").Ty;
const Name = @import("ty.zig").Name;
const ast = @import("ast.zig");
const mono = @import("mono.zig");

pub fn monomorphize(alloc: std.mem.Allocator, program: ast.Program) !mono.Mono {
    var monomorphizer = Monomorphizer {
        .alloc = alloc,
        .program = program,
        .context = ArrayList([]const u8).init(alloc),
        .tys = StringHashMap(Ty).init(alloc),
        .ty_defs = StringArrayHashMap(mono.TyDef).init(alloc),
        .funs = StringHashMap(mono.Fun).init(alloc),
    };
    try monomorphizer.put_ty(.{ .name = "Never", .args = ArrayList(Ty).init(alloc) }, .builtin_ty);
    try monomorphizer.put_ty(.{ .name = "Nothing", .args = ArrayList(Ty).init(alloc) }, .builtin_ty);
    for ("IU") |signedness| {
        for ([_]u8{8, 16, 32, 64}) |bits| {
            var name_buf = ArrayList(u8).init(alloc);
            try std.fmt.format(name_buf.writer(), "{c}{}", .{signedness, bits});
            const name = name_buf.items;
            try monomorphizer.put_ty(.{ .name = name, .args = ArrayList(Ty).init(alloc) }, .builtin_ty);
        }
    }

    const main = try monomorphizer.lookup("main", ArrayList(Name).init(alloc), ArrayList(Name).init(alloc));
    const main_fun = switch (main.def) {
        .fun => |f| f,
        else => return error.MainIsNotAFunction,
    };

    _ = monomorphizer.compile_function(main_fun, Monomorphizer.TyEnv.init(alloc)) catch |err| {
        std.debug.print("{any}\n\nContext:\n", .{err});
        for (monomorphizer.context.items) |context| {
            std.debug.print("- {s}\n", .{context});
        }
        return err;
    };

    return mono.Mono {
        .ty_defs = monomorphizer.ty_defs,
        .funs = monomorphizer.funs,
    };
}

const Monomorphizer = struct {
    alloc: std.mem.Allocator,
    program: ast.Program,
    context: ArrayList([]const u8),
    // The keys are strings of monomorphized types such as "Maybe[Int]".
    tys: StringHashMap(Ty),
    ty_defs: StringArrayHashMap(mono.TyDef),
    // The keys are strings of monomorphized function signatures such as "foo(Int)".
    funs: StringHashMap(mono.Fun),

    const Self = @This();

    // Maps type parameter names to fully monomorphized types.
    const TyEnv = StringHashMap(Name);

    // Maps variable names to their expression index.
    const VarEnv = StringHashMap(VarInfo);
    const VarInfo = struct { expr_index: usize, ty: Name };

    fn put_ty(self: *Self, ty: Ty, ty_def: mono.TyDef) !void {
        var name = ArrayList(u8).init(self.alloc);
        try name.writer().print("{}", .{ty});

        try self.tys.put(name.items, ty);
        try self.ty_defs.put(name.items, ty_def);
    }

    // Looks up the given name with the given number of type args and the args
    // of the given types.
    const LookupSolution = struct { def: ast.Def, ty_env: TyEnv };
    fn lookup(self: *Self, name: Name, ty_args: ?ArrayList(Name), args: ?ArrayList(Name)) error{
        OutOfMemory, TypeArgumentCantHaveGenerics, TypeArgumentCalledWithGenerics,
        MultipleTypesMatch, NoTypesMatch, StructTypeArgsCannotHaveTypeArgs,
        EnumTypeArgsCannotHaveTypeArgs, MultipleMatches, NoMatch
    }!LookupSolution {
        var name_matches = ArrayList(ast.Def).init(self.alloc);
        for (self.program.defs.items) |def| {
            const def_name = switch (def) {
                .builtin_ty => |n| n,
                .struct_ => |s| s.name,
                .enum_ => |e| e.name,
                .fun => |f| f.name,
            };
            if (std.mem.eql(u8, name, def_name)) {
                try name_matches.append(def);
            }
        }

        var full_matches = ArrayList(LookupSolution).init(self.alloc);
        defs: for (name_matches.items) |def| {
            if (args) |args_| {
                const fun = switch (def) {
                    .fun => |f| f,
                    else => continue :defs, // Only funs can accept args.
                };
                if (args_.items.len != fun.args.items.len) {
                    continue :defs;
                }

                var solver_ty_vars = StringHashMap(void).init(self.alloc);
                var solver_ty_env = StringHashMap(Ty).init(self.alloc);
                for (fun.ty_args.items) |ta| {
                    // TODO: Make sure type var only exists once
                    try solver_ty_vars.put(ta, {});
                }
                if (ty_args) |ty_args_| {
                    if (fun.ty_args.items.len != ty_args_.items.len) {
                        continue :defs;
                    }
                    for (fun.ty_args.items, ty_args_.items) |from, to| {
                        try solver_ty_env.put(from, self.tys.get(to) orelse unreachable);
                    }
                }
                for (fun.args.items, args_.items) |param, arg_mono_ty| {
                    const arg_ty = self.tys.get(arg_mono_ty) orelse unreachable;
                    if (!try arg_ty.is_assignable_to(solver_ty_vars, &solver_ty_env, param.ty)) {
                        continue :defs;
                    }
                }

                // TODO: Check if there are still unbound type parameters.

                // Compile types from solver ty env into mono ty env.
                var ty_env = StringHashMap(Name).init(self.alloc);
                {
                    var iter = solver_ty_env.iterator();
                    while (iter.next()) |constraint| {
                        try ty_env.put(constraint.key_ptr.*, try self.compile_type(constraint.value_ptr.*, TyEnv.init(self.alloc)));
                    }
                }

                try full_matches.append(.{ .def = .{ .fun = fun }, .ty_env = ty_env });

            } else {
                var ty_env = StringHashMap(Name).init(self.alloc);
                const ty_params = switch (def) {
                    .builtin_ty => |_| ArrayList(Name).init(self.alloc).items,
                    .struct_ => |s| s.ty_args.items,
                    .enum_ => |e| e.ty_args.items,
                    .fun => |f| f.ty_args.items,
                };
                const ty_args_ = (ty_args orelse ArrayList(Name).init(self.alloc)).items;
                if (ty_args_.len != ty_params.len) {
                    continue :defs;
                }
                for (ty_params, ty_args_) |from, to| {
                    try ty_env.put(from, to);
                }
                
                try full_matches.append(.{ .def = def, .ty_env = ty_env });
            }
        }

        if (full_matches.items.len != 1) {
            std.debug.print("Looked for a definition that matches `{s}", .{name});
            Ty.print_args_of_names(std.io.getStdOut().writer(), ty_args) catch @panic("couldn't write to stdout");
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

        if (full_matches.items.len == 0) {
            std.debug.print("No definition matches.\n", .{});
            if (name_matches.items.len > 0) {
                std.debug.print("These definitions have the same name, but arguments don't match:\n", .{});
                for (name_matches.items) |match| {
                    std.debug.print("- ", .{});
                    ast.print_signature(std.io.getStdOut().writer(), match) catch @panic("couldn't write to stdout");
                    std.debug.print("\n", .{});
                }
            }
            return error.NoMatch;
        }

        if (full_matches.items.len > 1) {
            std.debug.print("Multiple definitions match:\n", .{});
            for (full_matches.items) |match| {
                std.debug.print("- ", .{});
                var padded_signature = ArrayList(u8).init(self.alloc);
                ast.print_signature(padded_signature.writer(), match.def) catch @panic("couldn't write to stdout");
                while (padded_signature.items.len < 30) {
                    try padded_signature.append(' ');
                }
                std.debug.print("{s} with ", .{padded_signature.items});
                var iter = match.ty_env.iterator();
                while (iter.next()) |constraint| {
                    std.debug.print("{s} = {s}, ", .{constraint.key_ptr.*, constraint.value_ptr.*});
                }
                std.debug.print("\n", .{});
            }
            return error.MultipleMatches;
        }

        return full_matches.items[0];
    }

    fn compile_function(self: *Self, fun: ast.Fun, ty_env: TyEnv) !Name {
        var signature = ArrayList(u8).init(self.alloc);
        var arg_tys = ArrayList(Name).init(self.alloc);
        var var_env = VarEnv.init(self.alloc);

        try signature.appendSlice(fun.name);
        if (fun.ty_args.items.len > 0) {
            try signature.appendSlice("[");
            for (fun.ty_args.items, 0..) |arg, i| {
                if (i > 0) {
                    try signature.appendSlice(", ");
                }
                const arg_ty: Name = ty_env.get(arg) orelse @panic("required type arg doesn't exist in type env");
                try signature.appendSlice(arg_ty);
            }
            try signature.appendSlice("]");
        }
        try signature.append('(');
        for (fun.args.items, 0..) |arg, i| {
            if (i > 0) {
                try signature.appendSlice(", ");
            }
            const arg_type = try self.compile_type(arg.ty, ty_env);
            try arg_tys.append(arg_type);
            try signature.appendSlice(arg_type);
            try var_env.put(arg.name, .{ .expr_index = i, .ty = arg_type });
        }
        try signature.append(')');
        try self.context.append(signature.items);

        const return_ty = ret: {
            if (fun.returns) |ty| {
                break :ret try self.compile_type(ty, ty_env);
            } else {
                break :ret "Nothing";
            }
        };
        
        var mono_fun = mono.Fun {
            .arg_tys = arg_tys,
            .return_ty = return_ty,
            .is_builtin = fun.is_builtin,
            .body = ArrayList(mono.Expr).init(self.alloc),
            .tys = ArrayList(Name).init(self.alloc),
        };
        for (arg_tys.items) |ty| {
            try mono_fun.put(.{ .arg = {} }, ty);
        }
        for (fun.body.items) |expr| {
            _ = try self.compile_expr(&mono_fun, ty_env, &var_env, expr);
        }

        try self.funs.put(signature.items, mono_fun);

        _ = self.context.pop();

        return signature.items;
    }

    fn compile_expr(self: *Self, fun: *mono.Fun, ty_env: TyEnv, var_env: *VarEnv, expression: ast.Expr) error{
        OutOfMemory, MultipleMatches, NoMatch, TypeArgumentCalledWithGenerics, MultipleTypesMatch,
        NoTypesMatch, StructTypeArgsCannotHaveTypeArgs, EnumTypeArgsCannotHaveTypeArgs,
        InvalidExpressionCalled, CalledNonFunction, FunctionTypeArgsCannotHaveTypeArgs,
        ExpressionNotHandled, VariableNotInScope, CanOnlyAssignToName, YouCanOnlyConstructStructs,
        TypeArgumentCantHaveGenerics, FieldDoesNotExist, AccessedMemberOnNonStruct,
        VariantDoesntExist
    }!mono.ExprIndex {
        expr_switch:  { switch (expression) {
            .num => |n| try fun.put(.{ .num = n }, "I64"),
            .ref => |name| {
                if (var_env.get(name)) |var_info| {
                    return var_info.expr_index;
                }

                // TODO: Try to lookup type.
                std.debug.print("Tried to find `{s}`.\n", .{name});
                return error.VariableNotInScope;
            },
            .call => |call| {
                var callee = call.callee.*;
                var ty_args: ?ArrayList(Name) = null;
                var args = ArrayList(mono.ExprIndex).init(self.alloc);
                var arg_tys = ArrayList(Name).init(self.alloc);

                // This may be an enum variant instantiation such as `Maybe[Int].some(3)`.
                enum_variant: {
                    const member = switch (callee) {
                        .member => |member| member,
                        else => break :enum_variant,
                    };
                    var potential_enum = member.of.*;
                    const enum_ty_args = ty_args: {
                        switch(potential_enum) {
                            .ty_arged => |ta| {
                                potential_enum = ta.arged.*;
                                break :ty_args ta.ty_args;
                            },
                            .ref => break :ty_args ArrayList(Ty).init(self.alloc),
                            else => break :enum_variant,
                        }
                    };
                    const enum_name = switch (potential_enum) {
                        .ref => |ref| ref,
                        else => break :enum_variant,
                    };
                    std.debug.print("Potential enum name: {s}\n", .{enum_name});
                    if (var_env.contains(enum_name)) {
                        break :enum_variant;
                    }
                    std.debug.print("Not shadowed by local\n", .{});
                    var compiled_ty_args = try self.compile_types(enum_ty_args, ty_env);
                    const solution = try self.lookup(enum_name, compiled_ty_args, null);
                    std.debug.print("Solution: {any}\n", .{solution});
                    const enum_def = switch (solution.def) {
                        .enum_ => |e| e,
                        else => break :enum_variant,
                    };
                    const enum_ty = try self.compile_type(.{ .name = enum_name, .args = enum_ty_args }, ty_env);
                    std.debug.print("compiled enum ty: {s}\n", .{enum_ty});
                    
                    find_variant: {
                        for (enum_def.variants.items) |variant| {
                            if (std.mem.eql(u8, variant.name, member.name)) {
                                break :find_variant;
                            }
                        }
                        // Did not find a variant. Restore the sacred timeline.
                        return error.VariantDoesntExist;
                    }
                    try fun.put(.{ .variant_creation = .{ .enum_ty = enum_ty, .variant = member.name, .value = null } }, enum_ty);
                    break :expr_switch;
                }

                switch (callee) {
                    .ty_arged => |ta| {
                        callee = ta.arged.*;
                        ty_args = try self.compile_types(ta.ty_args, ty_env);
                    },
                    else => {},
                }
                const name = find_name: {
                    switch (callee) {
                        // Calls of the form `something.name()` cause `something` to
                        // be treated like an extra argument.
                        .member => |member| {
                            const expr = try self.compile_expr(fun, ty_env, var_env, member.of.*);
                            try args.append(expr);
                            try arg_tys.append(fun.tys.items[@intCast(expr)]);
                            break :find_name member.name;
                        },
                        .ref => |name| break :find_name name,
                        else => return error.InvalidExpressionCalled,
                    }
                };
                for (call.args.items) |arg| {
                    const expr = try self.compile_expr(fun, ty_env, var_env, arg);
                    try args.append(expr);
                    try arg_tys.append(fun.tys.items[@intCast(expr)]);
                }

                // We have lowered the explicit type arguments and the value
                // arguments. Let's look for matching functions!

                const lookup_solution = try self.lookup(name, ty_args, arg_tys);
                const called_fun = switch (lookup_solution.def) {
                    .fun => |f| f,
                    else => unreachable,
                };
                const call_ty_env = lookup_solution.ty_env;

                // TODO: Make sure all type args are different.

                const fun_name = try self.compile_function(called_fun, call_ty_env);
                const return_type = ret: {
                    if (called_fun.returns) |ty| {
                        break :ret try self.compile_type(ty, call_ty_env);
                    } else {
                        break :ret "Nothing";
                    }
                };

                try fun.put(.{ .call = .{ .fun = fun_name, .args = args } }, return_type);
            },
            .member => |m| {
                const of = try self.compile_expr(fun, ty_env, var_env, m.of.*);
                const of_type_def = self.ty_defs.get(fun.tys.items[of]) orelse unreachable;
                std.debug.print("Accessed member of {s}.\n", .{fun.tys.items[of]});
                const field_ty = get_field_ty: {
                    switch (of_type_def) {
                        .struct_ => |s| {
                            for (s.fields.items) |field| {
                                if (std.mem.eql(u8, field.name, m.name)) {
                                    break :get_field_ty field.ty;
                                }
                            }
                            return error.FieldDoesNotExist;
                        },
                        else => return error.AccessedMemberOnNonStruct,
                    }
                };
                try fun.put(.{ .member = .{ .of = of, .name = m.name } }, field_ty);
            },
            .var_ => |v| {
                const value = try self.compile_expr(fun, ty_env, var_env, v.value.*);
                try var_env.put(v.name, .{
                    .expr_index = value,
                    .ty = fun.tys.items[@intCast(value)]
                });
            },
            .assign => |assign| {
                const to = to: {
                    switch (assign.to.*) {
                        .ref => |ref| {
                            if (var_env.get(ref)) |var_info| {
                                break :to var_info.expr_index;
                            }
                            return error.VariableNotInScope;
                        },
                        else => return error.CanOnlyAssignToName,
                    }
                };
                const value = try self.compile_expr(fun, ty_env, var_env, assign.value.*);
                try fun.put(.{ .assign = .{ .to = to, .value = value } }, "Nothing");
            },
            .struct_construction => |sc| {
                var ty = self.expr_to_type(sc.ty.*) orelse return error.YouCanOnlyConstructStructs;
                const struct_type = try self.compile_type(ty, ty_env);

                var fields = StringHashMap(mono.ExprIndex).init(self.alloc);
                for (sc.fields.items) |f| {
                    try fields.put(f.name, try self.compile_expr(fun, ty_env, var_env, f.value));
                }

                try fun.put(.{ .struct_creation = .{
                    .struct_ty = struct_type,
                    .fields = fields,
                } }, struct_type);
            },
            .return_ => |returned| {
                const index = try self.compile_expr(fun, ty_env, var_env, returned.*);
                try fun.put(.{ .return_ = index }, "Never");
            },
            else => {
                std.debug.print("compiling {any}\n", .{expression});
                return error.ExpressionNotHandled;
            }
        } }
        return fun.body.items.len - 1;
    }

    fn expr_to_type(self: *Self, expr: ast.Expr) ?Ty {
        var expression = expr;
        var ty_args = ArrayList(Ty).init(self.alloc);
        switch (expression) {
            .ty_arged => |ta| {
                expression = ta.arged.*;
                ty_args = ta.ty_args;
            },
            else => {},
        }
        switch (expression) {
            .ref => |name| return Ty { .name = name, .args = ty_args },
            else => return null,
        }
    }

    fn compile_types(self: *Self, tys: ArrayList(Ty), ty_env: TyEnv) error{
        OutOfMemory, TypeArgumentCalledWithGenerics, MultipleTypesMatch,
        NoTypesMatch, StructTypeArgsCannotHaveTypeArgs, EnumTypeArgsCannotHaveTypeArgs,
        MultipleMatches, NoMatch, TypeArgumentCantHaveGenerics
    }!ArrayList(Name) {
        var args = ArrayList(Name).init(self.alloc);
        for (tys.items) |arg| {
            try args.append(try self.compile_type(arg, ty_env));
        }
        return args;
    }

    // Specializes a type such as `Maybe[T]` using a type environment such as
    // `{T: Int}` (resulting in `Maybe[Int]`). Also creates the needed specialized
    // types in the `mono.Types`.
    fn compile_type(self: *Self, ty: Ty, ty_env: TyEnv) !Name {
        var args = try self.compile_types(ty.args, ty_env);

        if (ty_env.get(ty.name)) |name| {
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

        switch ((try self.lookup(ty.name, args, null)).def) {
            .builtin_ty => |_| {
                try self.put_ty(ty, .builtin_ty);
            },
            .struct_ => |s| {
                var specialized_args = ArrayList(Ty).init(self.alloc);
                var inner_ty_env = TyEnv.init(self.alloc);
                for (s.ty_args.items, args.items) |from, to| {
                    try specialized_args.append(self.tys.get(to) orelse unreachable);
                    try inner_ty_env.put(from, to);
                }

                var fields = ArrayList(mono.Field).init(self.alloc);
                for (s.fields.items) |field| {
                    const field_type = try self.compile_type(field.ty, inner_ty_env);
                    try fields.append(.{ .name = field.name, .ty = field_type });
                }
                try self.put_ty(
                    .{ .name = ty.name, .args = specialized_args },
                    .{ .struct_ = .{ .fields = fields },
                });
            },
            .enum_ => |e| {
                var specialized_args = ArrayList(Ty).init(self.alloc);
                var inner_ty_env = TyEnv.init(self.alloc);
                for (e.ty_args.items, args.items) |from, to| {
                    try specialized_args.append(self.tys.get(to) orelse unreachable);
                    try inner_ty_env.put(from, to);
                }

                var variants = ArrayList(mono.Variant).init(self.alloc);
                for (e.variants.items) |variant| {
                    const variant_type = b: {
                        if (variant.ty) |t| {
                            break :b try self.compile_type(t, inner_ty_env);
                        } else {
                            break :b "Nothing";
                        }
                    };
                    try variants.append(.{ .name = variant.name, .ty = variant_type });
                }
                try self.put_ty(
                    .{ .name = ty.name, .args = specialized_args },
                    .{ .enum_ = .{ .variants = variants },
                });
            },
            .fun => {
                unreachable;
            },
        }

        return name;
    }
};
