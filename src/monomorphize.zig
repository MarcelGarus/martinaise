const std = @import("std");
const ArrayList = std.ArrayList;
const StringArrayHashMap = std.StringArrayHashMap;
const StringHashMap = std.StringHashMap;
const format = std.fmt.format;
const Ty = @import("ty.zig").Ty;
const string_mod = @import("string.zig");
const String = string_mod.String;
const Str = string_mod.Str;
const ast = @import("ast.zig");
const mono = @import("mono.zig");
const numbers = @import("numbers.zig");

pub fn monomorphize(alloc: std.mem.Allocator, program: ast.Program) !mono.Mono {
    var monomorphizer = Monomorphizer{
        .alloc = alloc,
        .program = program,
        .context = ArrayList(Str).init(alloc),
        .tys = StringHashMap(Ty).init(alloc),
        .ty_defs = StringArrayHashMap(mono.TyDef).init(alloc),
        .funs = StringHashMap(mono.Fun).init(alloc),
    };
    try monomorphizer.put_ty(.{ .name = "Never", .args = ArrayList(Ty).init(alloc) }, .builtin_ty);
    try monomorphizer.put_ty(.{ .name = "Nothing", .args = ArrayList(Ty).init(alloc) }, .builtin_ty);
    for ("IU") |signedness| {
        for ([_]u8{ 8, 16, 32, 64 }) |bits| {
            var name_buf = String.init(alloc);
            try std.fmt.format(name_buf.writer(), "{c}{}", .{ signedness, bits });
            const name = name_buf.items;
            try monomorphizer.put_ty(.{ .name = name, .args = ArrayList(Ty).init(alloc) }, .builtin_ty);
        }
    }

    const main = try monomorphizer.lookup("main", ArrayList(Str).init(alloc), ArrayList(Str).init(alloc));
    const main_fun = switch (main.def) {
        .fun => |f| f,
        else => return error.MainIsNotAFunction,
    };

    _ = FunMonomorphizer.compile(&monomorphizer, main_fun, TyEnv.init(alloc)) catch |err| {
        std.debug.print("{any}\n\nContext:\n", .{err});
        for (monomorphizer.context.items) |context| {
            std.debug.print("- {s}\n", .{context});
        }
        return err;
    };

    return mono.Mono{
        .ty_defs = monomorphizer.ty_defs,
        .funs = monomorphizer.funs,
    };
}

// Maps type parameter names to fully monomorphized types.
const TyEnv = StringHashMap(Str);

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

    fn put_ty(self: *Self, ty: Ty, ty_def: mono.TyDef) !void {
        var ty_name = String.init(self.alloc);
        try ty_name.writer().print("{}", .{ty});

        try self.tys.put(ty_name.items, ty);
        try self.ty_defs.put(ty_name.items, ty_def);
    }

    // Looks up the given name with the given number of type args and the args
    // of the given types.
    const LookupSolution = struct { def: ast.Def, ty_env: TyEnv };
    fn lookup(self: *Self, name: Str, ty_args: ?ArrayList(Str), args: ?ArrayList(Str)) error{ OutOfMemory, TypeArgumentCantHaveGenerics, TypeArgumentCalledWithGenerics, MultipleTypesMatch, NoTypesMatch, StructTypeArgsCannotHaveTypeArgs, EnumTypeArgsCannotHaveTypeArgs, MultipleMatches, NoMatch }!LookupSolution {
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
                var ty_env = StringHashMap(Str).init(self.alloc);
                {
                    var iter = solver_ty_env.iterator();
                    while (iter.next()) |constraint| {
                        try ty_env.put(constraint.key_ptr.*, try self.compile_type(constraint.value_ptr.*, TyEnv.init(self.alloc)));
                    }
                }

                try full_matches.append(.{ .def = .{ .fun = fun }, .ty_env = ty_env });
            } else {
                var ty_env = StringHashMap(Str).init(self.alloc);
                const ty_params = switch (def) {
                    .builtin_ty => |_| ArrayList(Str).init(self.alloc).items,
                    .struct_ => |s| s.ty_args.items,
                    .enum_ => |e| e.ty_args.items,
                    .fun => |f| f.ty_args.items,
                };
                const ty_args_ = (ty_args orelse ArrayList(Str).init(self.alloc)).items;
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
            Ty.print_args_of_strs(std.io.getStdOut().writer(), ty_args) catch @panic("couldn't write to stdout");
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
                    std.debug.print("{s} = {s}, ", .{ constraint.key_ptr.*, constraint.value_ptr.* });
                }
                std.debug.print("\n", .{});
            }
            return error.MultipleMatches;
        }

        return full_matches.items[0];
    }

    fn compile_types(self: *Self, tys: ArrayList(Ty), ty_env: TyEnv) error{ OutOfMemory, TypeArgumentCalledWithGenerics, MultipleTypesMatch, NoTypesMatch, StructTypeArgsCannotHaveTypeArgs, EnumTypeArgsCannotHaveTypeArgs, MultipleMatches, NoMatch, TypeArgumentCantHaveGenerics }!ArrayList(Str) {
        var args = ArrayList(Str).init(self.alloc);
        for (tys.items) |arg| {
            try args.append(try self.compile_type(arg, ty_env));
        }
        return args;
    }

    // Specializes a type such as `Maybe[T]` using a type environment such as
    // `{T: Int}` (resulting in `Maybe[Int]`). Also creates the needed specialized
    // types in the `mono.Types`.
    fn compile_type(self: *Self, ty: Ty, ty_env: TyEnv) !Str {
        var args = try self.compile_types(ty.args, ty_env);

        if (ty_env.get(ty.name)) |name| {
            if (args.items.len > 0) {
                return error.TypeArgumentCalledWithGenerics;
            }
            return name;
        }

        var name_buf = String.init(self.alloc);
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
                try self.put_ty(.{ .name = ty.name, .args = specialized_args }, .{
                    .struct_ = .{ .fields = fields },
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
                try self.put_ty(.{ .name = ty.name, .args = specialized_args }, .{
                    .enum_ = .{ .variants = variants },
                });
            },
            .fun => {
                unreachable;
            },
        }

        return name;
    }
};

const FunMonomorphizer = struct {
    monomorphizer: *Monomorphizer,
    alloc: std.mem.Allocator,
    fun: *mono.Fun,
    ty_env: TyEnv,
    var_env: *VarEnv,

    // When lowering loops, breaks don't know where to jump to yet. Instead,
    // they fill this structure.
    breakable_scopes: ArrayList(BreakableScope), // used like a stack
    const BreakableScope = struct {
        result: mono.ExprIndex,
        result_ty: ?Str,
        breaks: ArrayList(mono.ExprIndex),
    };

    const Self = @This();

    // Maps variable names to their expression index.
    const VarEnv = StringHashMap(VarInfo);
    // TODO: Type is already available as fun.types, no need for it here
    const VarInfo = struct { expr_index: usize, ty: Str };

    fn compile(monomorphizer: *Monomorphizer, fun: ast.Fun, ty_env: TyEnv) !Str {
        var alloc = monomorphizer.alloc;

        var signature = String.init(alloc);
        var ty_args = ArrayList(Str).init(alloc);
        var arg_tys = ArrayList(Str).init(alloc);
        var var_env = VarEnv.init(alloc);

        try signature.appendSlice(fun.name);
        if (fun.ty_args.items.len > 0) {
            try signature.appendSlice("[");
            for (fun.ty_args.items, 0..) |arg, i| {
                if (i > 0) {
                    try signature.appendSlice(", ");
                }
                const arg_ty: Str = ty_env.get(arg) orelse @panic("required type arg doesn't exist in type env");
                try ty_args.append(arg_ty);
                try signature.appendSlice(arg_ty);
            }
            try signature.appendSlice("]");
        }
        try signature.append('(');
        for (fun.args.items, 0..) |arg, i| {
            if (i > 0) {
                try signature.appendSlice(", ");
            }
            const arg_type = try monomorphizer.compile_type(arg.ty, ty_env);
            try arg_tys.append(arg_type);
            try signature.appendSlice(arg_type);
            try var_env.put(arg.name, .{ .expr_index = i, .ty = arg_type });
        }
        try signature.append(')');
        try monomorphizer.context.append(signature.items);

        const return_ty = ret: {
            if (fun.returns) |ty| {
                break :ret try monomorphizer.compile_type(ty, ty_env);
            } else {
                break :ret "Nothing";
            }
        };

        var mono_fun = mono.Fun{
            .ty_args = ty_args,
            .arg_tys = arg_tys,
            .return_ty = return_ty,
            .is_builtin = fun.is_builtin,
            .body = ArrayList(mono.Expr).init(alloc),
            .tys = ArrayList(Str).init(alloc),
        };
        for (arg_tys.items) |ty| {
            _ = try mono_fun.put(.{ .arg = {} }, ty);
        }

        var fun_monomorphizer = Self{
            .monomorphizer = monomorphizer,
            .alloc = alloc,
            .fun = &mono_fun,
            .ty_env = ty_env,
            .var_env = &var_env,
            .breakable_scopes = ArrayList(BreakableScope).init(alloc),
        };

        const body_result = try fun_monomorphizer.compile_body(fun.body.items);
        _ = try mono_fun.put(.{ .return_ = body_result }, "Never");
        // TODO: Make sure body has the correct type

        try monomorphizer.funs.put(signature.items, mono_fun);

        _ = monomorphizer.context.pop();

        return signature.items;
    }

    fn compile_expr(self: *Self, expression: ast.Expr) error{
        OutOfMemory,
        MultipleMatches,
        NoMatch,
        TypeArgumentCalledWithGenerics,
        MultipleTypesMatch,
        NoTypesMatch,
        StructTypeArgsCannotHaveTypeArgs,
        EnumTypeArgsCannotHaveTypeArgs,
        InvalidExpressionCalled,
        CalledNonFunction,
        FunctionTypeArgsCannotHaveTypeArgs,
        ExpressionNotHandled,
        VariableNotInScope,
        CanOnlyAssignToName,
        YouCanOnlyConstructStructs,
        TypeArgumentCantHaveGenerics,
        FieldDoesNotExist,
        AccessedMemberOnNonStruct,
        VariantDoesntExist,
        IfConditionMustBeBool,
        SwitchOnNonEnum,
        UnknownVariant,
        TooManyArgumentsForVariant,
        IfWithMismatchedTypes,
        CannotAssignToThis,
        BreakCanOnlyTakeOneArgument,
        BreaksReturnInconsistentTypes,
    }!mono.ExprIndex {
        if (try self.compile_break(expression)) |index| {
            return index;
        }
        // This may be an enum variant instantiation such as `Maybe[Int].some(3)`.
        if (try self.compile_enum_creation(expression)) |index| {
            return index;
        }
        switch (expression) {
            .int => |int| return try self.fun.put(
                .{ .int = .{ .value = int.value, .signedness = int.signedness, .bits = int.bits } },
                try numbers.int_ty_name(self.alloc, .{ .signedness = int.signedness, .bits = int.bits }),
            ),
            .string => |str| {
                var u8_ty: Ty = .{ .name = "U8", .args = ArrayList(Ty).init(self.alloc) };

                var slice_ty_args = ArrayList(Ty).init(self.alloc);
                try slice_ty_args.append(u8_ty);
                const slice_ty: Ty = .{ .name = "Slice", .args = slice_ty_args };

                const string_ty: Ty = .{ .name = "Str", .args = ArrayList(Ty).init(self.alloc) };

                _ = try self.monomorphizer.compile_type(u8_ty, TyEnv.init(self.alloc));
                _ = try self.monomorphizer.compile_type(slice_ty, TyEnv.init(self.alloc));
                _ = try self.monomorphizer.compile_type(string_ty, TyEnv.init(self.alloc));

                return try self.fun.put(.{ .string = str }, "Str");
            },
            .ref => |name| {
                if (self.var_env.get(name)) |var_info| {
                    return var_info.expr_index;
                }

                // TODO: Try to lookup type.
                std.debug.print("Tried to find `{s}`.\n", .{name});
                return error.VariableNotInScope;
            },
            .call => |call| {
                var callee = call.callee.*;
                var ty_args: ?ArrayList(Str) = null;
                var args = ArrayList(mono.ExprIndex).init(self.alloc);
                var arg_tys = ArrayList(Str).init(self.alloc);

                switch (callee) {
                    .ty_arged => |ta| {
                        callee = ta.arged.*;
                        ty_args = try self.monomorphizer.compile_types(ta.ty_args, self.ty_env);
                    },
                    else => {},
                }
                const name = find_name: {
                    switch (callee) {
                        // Calls of the form `something.name()` cause `something` to
                        // be treated like an extra argument.
                        .member => |member| {
                            const expr = try self.compile_expr(member.of.*);
                            try args.append(expr);
                            try arg_tys.append(self.fun.tys.items[@intCast(expr)]);
                            break :find_name member.name;
                        },
                        .ref => |name| break :find_name name,
                        else => return error.InvalidExpressionCalled,
                    }
                };
                for (call.args.items) |arg| {
                    const expr = try self.compile_expr(arg);
                    try args.append(expr);
                    try arg_tys.append(self.fun.tys.items[@intCast(expr)]);
                }

                // We have lowered the explicit type arguments and the value
                // arguments. Let's look for matching functions!

                const lookup_solution = try self.monomorphizer.lookup(name, ty_args, arg_tys);
                const called_fun = switch (lookup_solution.def) {
                    .fun => |f| f,
                    else => unreachable,
                };
                const call_ty_env = lookup_solution.ty_env;

                // TODO: Make sure all type args are different.

                const fun_name = try FunMonomorphizer.compile(self.monomorphizer, called_fun, call_ty_env);
                const return_type = ret: {
                    if (called_fun.returns) |ty| {
                        break :ret try self.monomorphizer.compile_type(ty, call_ty_env);
                    } else {
                        break :ret "Nothing";
                    }
                };

                return try self.fun.put(.{ .call = .{ .fun = fun_name, .args = args } }, return_type);
            },
            .member => |m| {
                // Struct field access.
                const of = try self.compile_expr(m.of.*);
                const of_type_def = self.monomorphizer.ty_defs.get(self.fun.tys.items[of]) orelse unreachable;
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
                return try self.fun.put(.{ .member = .{ .of = of, .name = m.name } }, field_ty);
            },
            .var_ => |v| {
                const value = try self.compile_expr(v.value.*);
                const ty = self.fun.tys.items[@intCast(value)];
                const copy = try self.fun.put(.{ .copy = value }, ty);
                try self.var_env.put(v.name, .{ .expr_index = copy, .ty = ty });
                return copy;
            },
            .assign => |assign| {
                const value = try self.compile_expr(assign.value.*);
                const to = try self.compile_left_expr(assign.to.*, self.fun.tys.items[value]);
                return try self.fun.put(.{ .assign = .{ .to = to, .value = value } }, "Nothing");
            },
            .struct_creation => |sc| {
                var ty = self.expr_to_type(sc.ty.*) orelse return error.YouCanOnlyConstructStructs;
                const struct_type = try self.monomorphizer.compile_type(ty, self.ty_env);

                var fields = StringHashMap(mono.ExprIndex).init(self.alloc);
                for (sc.fields.items) |f| {
                    try fields.put(f.name, try self.compile_expr(f.value));
                }

                return try self.fun.put(.{ .struct_creation = .{
                    .struct_ty = struct_type,
                    .fields = fields,
                } }, struct_type);
            },
            .if_ => |if_| {
                const result = try self.fun.put(.{ .uninitialized = {} }, "Something"); // Type will be replaced later
                const condition = try self.compile_expr(if_.condition.*);
                if (!std.mem.eql(u8, self.fun.tys.items[condition], "Bool")) {
                    return error.IfConditionMustBeBool;
                }
                const jump_if_true = try self.fun.put(.{ .arg = {} }, "Nothing"); // Will be replaced with jump_if
                const jump_if_false = try self.fun.put(.{ .arg = {} }, "Never"); // Will be replaced with jump

                // TODO: Create inner var env
                const then_body = self.fun.next_index();
                const then_result = try self.compile_body(if_.then.items);
                self.fun.tys.items[result] = self.fun.tys.items[then_result];
                _ = try self.fun.put(.{ .assign = .{ .to = .{ .ty = self.fun.tys.items[result], .kind = .{ .ref = result } }, .value = then_result } }, "Nothing");
                const jump_after_then = try self.fun.put(.{ .arg = {} }, "Never"); // Will be replaced with jump

                if (if_.else_) |else_| {
                    // TODO: Create inner var env
                    const else_body = self.fun.next_index();
                    const else_result = try self.compile_body(else_.items);
                    if (!std.mem.eql(u8, self.fun.tys.items[then_result], self.fun.tys.items[else_result])) {
                        std.debug.print("The then body returns {s}, else body returns {s}.\n", .{ self.fun.tys.items[then_result], self.fun.tys.items[else_result] });
                        return error.IfWithMismatchedTypes;
                    }
                    _ = try self.fun.put(.{ .assign = .{ .to = .{ .ty = self.fun.tys.items[result], .kind = .{ .ref = result } }, .value = else_result } }, "Nothing");
                    const jump_after_else = try self.fun.put(.{ .arg = {} }, "Never"); // Will be replaced with jump
                    const after_if = self.fun.next_index();

                    // Fill in jumps
                    self.fun.body.items[jump_if_true] = .{ .jump_if = .{ .condition = condition, .target = then_body } };
                    self.fun.body.items[jump_if_false] = .{ .jump = .{ .target = else_body } };
                    self.fun.body.items[jump_after_then] = .{ .jump = .{ .target = after_if } };
                    self.fun.body.items[jump_after_else] = .{ .jump = .{ .target = after_if } };
                } else {
                    const after_if = self.fun.next_index();

                    // Fill in jumps
                    self.fun.body.items[jump_if_true] = .{ .jump_if = .{ .condition = condition, .target = then_body } };
                    self.fun.body.items[jump_if_false] = .{ .jump = .{ .target = after_if } };
                    self.fun.body.items[jump_after_then] = .{ .jump = .{ .target = after_if } };
                }

                return result;
            },
            .switch_ => |switch_| {
                const result = try self.fun.put(.{ .uninitialized = {} }, "Something"); // Type will be replaced later
                const value = try self.compile_expr(switch_.value.*);
                const enum_ty = self.fun.tys.items[value];
                const enum_def = switch (self.monomorphizer.ty_defs.get(enum_ty) orelse unreachable) {
                    .enum_ => |e| e,
                    else => return error.SwitchOnNonEnum,
                };

                // Jump table
                const jump_table_start = self.fun.next_index();
                for (switch_.cases.items) |_| {
                    _ = try self.fun.put(.{ .arg = {} }, "Nothing"); // Will be replaced with jump_if_variant
                }
                // TODO: instead of looping, ensure all cases are matched
                // TODO: ensure cases aren't handled multiple times
                _ = try self.fun.put(.{ .jump = .{ .target = jump_table_start } }, "Never"); // unreachable

                // Case bodies
                var after_switch_jumps = ArrayList(mono.ExprIndex).init(self.alloc);
                for (switch_.cases.items, 0..) |case, i| {
                    self.fun.body.items[jump_table_start + i] = .{ .jump_if_variant = .{
                        .condition = value,
                        .variant = case.variant,
                        .target = self.fun.next_index(),
                    } };
                    const ty = find_ty: {
                        for (enum_def.variants.items) |variant| {
                            if (std.mem.eql(u8, variant.name, case.variant)) {
                                break :find_ty variant.ty;
                            }
                        }
                        return error.UnknownVariant;
                    };
                    const unpacked = try self.fun.put(.{ .get_enum_value = .{ .of = value, .variant = case.variant, .ty = ty } }, ty);
                    // TODO: Create inner var env
                    // const inner_self.var_env = self.var_env.clone();
                    if (case.binding) |binding| {
                        try self.var_env.put(binding, .{ .expr_index = unpacked, .ty = ty });
                    }

                    const body_result = try self.compile_body(case.body.items);
                    if (i == 0) {
                        self.fun.tys.items[result] = self.fun.tys.items[body_result];
                    } else if (!std.mem.eql(u8, self.fun.tys.items[result], self.fun.tys.items[body_result])) {
                        std.debug.print("Previous switch cases return {s}, but the case for {s} returns {s}.\n", .{ self.fun.tys.items[result], case.variant, self.fun.tys.items[body_result] });
                        return error.IfWithMismatchedTypes;
                    }
                    _ = try self.fun.put(.{ .assign = .{ .to = .{ .ty = self.fun.tys.items[result], .kind = .{ .ref = result } }, .value = body_result } }, "Nothing");
                    try after_switch_jumps.append(try self.fun.put(.{ .arg = {} }, "Never")); // will be replaced with jump to after switch
                }
                const after_switch = self.fun.next_index();
                for (after_switch_jumps.items) |jump| {
                    self.fun.body.items[jump] = .{ .jump = .{ .target = after_switch } };
                }

                return result;
            },
            .loop => |body| {
                const result = try self.fun.put(.{ .uninitialized = {} }, "Nothing"); // type will be replaced
                try self.breakable_scopes.append(.{
                    .result = result,
                    .result_ty = null,
                    .breaks = ArrayList(mono.ExprIndex).init(self.alloc),
                });
                // TODO: Create inner var env
                const loop_start = self.fun.next_index();
                _ = try self.compile_body(body.items);
                _ = try self.fun.put(.{ .jump = .{ .target = loop_start } }, "Never");

                const after_loop = self.fun.next_index();
                const scope = self.breakable_scopes.pop();
                if (scope.result_ty) |ty| {
                    self.fun.tys.items[result] = ty;
                }
                for (scope.breaks.items) |b| {
                    self.fun.body.items[b] = .{ .jump = .{ .target = after_loop } };
                }

                return result;
            },
            .return_ => |returned| {
                const index = try self.compile_expr(returned.*);
                // TODO: Make sure return has correct type
                return try self.fun.put(.{ .return_ = index }, "Never");
            },
            .ampersanded => |expr| {
                const index = try self.compile_expr(expr.*);
                const ty = self.monomorphizer.tys.get(self.fun.tys.items[index]) orelse unreachable;

                var args = ArrayList(Ty).init(self.alloc);
                try args.append(ty);
                const ref_ty: Ty = .{ .name = "&", .args = args };
                const compiled_ref_ty = try self.monomorphizer.compile_type(ref_ty, self.ty_env);

                return try self.fun.put(.{ .take_ref = index }, compiled_ref_ty);
            },
            else => {
                std.debug.print("compiling {any}\n", .{expression});
                return error.ExpressionNotHandled;
            },
        }
    }

    fn compile_left_expr(self: *Self, expr: ast.Expr, right_ty: Str) !mono.LeftExpr {
        var left = try self.compile_left_expr_rec(expr);
        while (!std.mem.eql(u8, left.ty, right_ty) and std.mem.eql(u8, (self.monomorphizer.tys.get(left.ty) orelse unreachable).name, "Ref")) {
            // TODO: This is so horrible.
            const derefed_ty = left.ty["Ref[".len .. left.ty.len - "]".len];
            const heaped = try self.alloc.create(mono.LeftExpr);
            heaped.* = left;
            left = .{ .ty = derefed_ty, .kind = .{ .deref = heaped } };
        }
        return left;
    }
    fn compile_left_expr_rec(self: *Self, expr: ast.Expr) !mono.LeftExpr {
        switch (expr) {
            .ref => |ref| {
                if (self.var_env.get(ref)) |var_info| {
                    return .{
                        .ty = self.fun.tys.items[var_info.expr_index],
                        .kind = .{ .ref = var_info.expr_index },
                    };
                }

                std.debug.print("Tried to find `{s}`.\n", .{ref});
                return error.VariableNotInScope;
            },
            .member => |member| {
                var of = try self.compile_left_expr_rec(member.of.*);
                const of_type_def = self.monomorphizer.ty_defs.get(of.ty) orelse unreachable;
                const field_ty = get_field_ty: {
                    switch (of_type_def) {
                        .struct_ => |s| {
                            for (s.fields.items) |field| {
                                if (std.mem.eql(u8, field.name, member.name)) {
                                    break :get_field_ty field.ty;
                                }
                            }
                            return error.FieldDoesNotExist;
                        },
                        else => return error.AccessedMemberOnNonStruct,
                    }
                };

                const heaped = try self.alloc.create(mono.LeftExpr);
                heaped.* = of;
                return .{ .ty = field_ty, .kind = .{ .member = .{ .of = heaped, .name = member.name } } };
            },
            else => return error.CannotAssignToThis,
        }
    }

    fn compile_body(self: *Self, body: []const ast.Expr) !mono.ExprIndex {
        var last_index: ?mono.ExprIndex = null;
        for (body) |expr| {
            last_index = try self.compile_expr(expr);
        }
        if (last_index) |last| {
            return last;
        } else {
            return try self.compile_nothing_instance();
        }
    }

    fn compile_nothing_instance(self: *Self) !mono.ExprIndex {
        return try self.fun.put(.{ .struct_creation = .{ .struct_ty = "Nothing", .fields = StringHashMap(mono.ExprIndex).init(self.alloc) } }, "Nothing");
    }

    // Some calls and some refs may be breaks. For example, `break(5)` and `break` both break.
    fn compile_break(self: *Self, expr: ast.Expr) !?mono.ExprIndex {
        const arg: ?ast.Expr = break_arg: {
            switch (expr) {
                .ref => |name| if (std.mem.eql(u8, name, "break")) {
                    break :break_arg null;
                } else {
                    return null;
                },
                .call => |call| switch (call.callee.*) {
                    .ref => |name| if (std.mem.eql(u8, name, "break")) {
                        if (call.args.items.len == 0) {
                            break :break_arg null;
                        }
                        if (call.args.items.len == 1) {
                            break :break_arg call.args.items[0];
                        }
                        return error.BreakCanOnlyTakeOneArgument;
                    } else {
                        return null;
                    },
                    else => return null,
                },
                else => return null,
            }
        };

        const compiled_arg = ca: {
            if (arg) |a| {
                break :ca try self.compile_expr(a);
            } else {
                break :ca try self.compile_nothing_instance();
            }
        };
        const arg_ty = self.fun.tys.items[compiled_arg];

        var scope = &self.breakable_scopes.items[self.breakable_scopes.items.len - 1];

        if (scope.result_ty) |expected_ty| {
            if (!std.mem.eql(u8, arg_ty, expected_ty)) {
                std.debug.print("Previous break returned {s}, this break returns {s}.\n", .{ expected_ty, arg_ty });
                return error.BreaksReturnInconsistentTypes;
            }
        }
        scope.result_ty = arg_ty;

        _ = try self.fun.put(.{ .assign = .{
            .to = .{ .ty = arg_ty, .kind = .{ .ref = scope.result } },
            .value = compiled_arg,
        } }, "Nothing");
        const jump = try self.fun.put(.{ .uninitialized = {} }, "Never"); // will be replaced by jump to after loop
        try scope.breaks.append(jump);
        return jump;
    }

    // Some calls and some members may be enum creations. For example, `Maybe[U8].some(4_u8)` and
    // `Bool.true` both create enum variants.
    fn compile_enum_creation(self: *Self, expr_: ast.Expr) !?mono.ExprIndex {
        var expr = expr_;

        const value: ?ast.Expr = find_value: {
            switch (expr) {
                .call => |call| {
                    if (call.args.items.len == 0) {
                        expr = call.callee.*;
                        break :find_value null;
                    }
                    if (call.args.items.len == 1) {
                        expr = call.callee.*;
                        break :find_value call.args.items[0];
                    }
                    return null;
                },
                else => break :find_value null,
            }
        };

        const member = switch (expr) {
            .member => |member| member,
            else => return null,
        };
        var potential_enum = member.of.*;
        const enum_ty_args = ty_args: {
            switch (potential_enum) {
                .ty_arged => |ta| {
                    potential_enum = ta.arged.*;
                    break :ty_args ta.ty_args;
                },
                .ref => break :ty_args ArrayList(Ty).init(self.alloc),
                else => return null,
            }
        };
        const enum_name = switch (potential_enum) {
            .ref => |ref| ref,
            else => return null,
        };
        if (self.var_env.contains(enum_name)) {
            return null;
        }
        var compiled_ty_args = try self.monomorphizer.compile_types(enum_ty_args, self.ty_env);
        const solution = try self.monomorphizer.lookup(enum_name, compiled_ty_args, null);
        const enum_def = switch (solution.def) {
            .enum_ => |e| e,
            else => return null,
        };
        const enum_ty = try self.monomorphizer.compile_type(.{ .name = enum_name, .args = enum_ty_args }, self.ty_env);

        find_variant: {
            for (enum_def.variants.items) |variant| {
                if (std.mem.eql(u8, variant.name, member.name)) {
                    break :find_variant;
                }
            }
            // Did not find a variant. Restore the sacred timeline.
            return error.VariantDoesntExist;
        }

        const compiled_value = variant_value: {
            if (value) |val| {
                break :variant_value try self.compile_expr(val);
            } else {
                break :variant_value try self.compile_nothing_instance();
            }
            return error.TooManyArgumentsForVariant;
        };

        return try self.fun.put(.{ .variant_creation = .{ .enum_ty = enum_ty, .variant = member.name, .value = compiled_value } }, enum_ty);
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
            .ref => |name| return Ty{ .name = name, .args = ty_args },
            else => return null,
        }
    }
};
