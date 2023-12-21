/// A rough sketch on how this compiler stage works: The AST functions are
/// compiled into monomorphized functions, starting from the main function.
/// The Mono contains all compiled functions and types, corresponding to code
/// and type definitions that actually need to be generated later on.
///
/// # Generic functions
///
/// Generic functions can be compiled multiple times with multiple type
/// arguments. For example, take this code:
///
/// ```
/// fun main(): U8 {
///   var foo = wrap_in_foo(wrap_in_foo(2_U8))
///   0_U64
/// }
/// struct Foo[T] { inner: T }
/// fun wrap_in_foo[T](val: T) { Foo.{ inner = val } }
/// ```
///
/// The following types and functions are lowered:
///
/// - main
///   - wrap_in_foo[U8]
///     - Foo[U8]
///   - wrap_in_foo[Foo[U8]]
///     - Foo[Foo[U8]]
///
/// # Recursive functions
///
/// We want to allow recursive functions without the compiler itself getting
/// into an infinitely recursing state. That's why even before a function is
/// compiled, a mock-version of it is added to the function map. When this
/// function is encountered recursively, only its signature is needed to figure
/// out how to use it.
///
const std = @import("std");
const ArrayList = std.ArrayList;
const StringArrayHashMap = std.StringArrayHashMap;
const StringHashMap = std.StringHashMap;
const format = std.fmt.format;
const Ty = @import("ty.zig").Ty;
const string = @import("string.zig");
const String = string.String;
const Str = string.Str;
const Result = @import("result.zig").Result;
const ast = @import("ast.zig");
const mono = @import("mono.zig");
const numbers = @import("numbers.zig");
const print_on_same_line = @import("term.zig").print_on_same_line;

pub fn monomorphize(alloc: std.mem.Allocator, program: ast.Program) !Result(mono.Mono) {
    var monomorphizer = Monomorphizer{
        .alloc = alloc,
        .program = program,
        .context = ArrayList(Str).init(alloc),
        .tys = StringHashMap(Ty).init(alloc),
        .ty_defs = StringArrayHashMap(mono.TyDef).init(alloc),
        .funs = StringHashMap(mono.Fun).init(alloc),
        .err = String.init(alloc),
    };
    try monomorphizer.put_ty(.{ .name = "Never", .args = ArrayList(Ty).init(alloc) }, .builtin_ty);
    try monomorphizer.put_ty(.{ .name = "Nothing", .args = ArrayList(Ty).init(alloc) }, .builtin_ty);
    for (numbers.all_int_configs()) |config| {
        const name = try numbers.int_ty_name(alloc, config);
        try monomorphizer.put_ty(.{ .name = name, .args = ArrayList(Ty).init(alloc) }, .builtin_ty);
    }

    const main = try monomorphizer.lookup("main", &[_]Str{}, &[_]Str{});
    const main_fun = switch (main.def) {
        .fun => |f| f,
        else => return .{ .err = "Main is not a function.\n" },
    };

    const main_signature = FunMonomorphizer.compile(&monomorphizer, main_fun, TyEnv.init(alloc)) catch |error_| {
        if (error_ != error.CompileError) return error_;

        var err_with_context = String.init(alloc);
        const errw = err_with_context.writer();
        try format(errw, "Error while compiling\n", .{});
        for (monomorphizer.context.items) |context|
            try format(errw, "- {s}\n", .{context});
        try format(errw, "\n", .{});
        try format(errw, "{s}", .{monomorphizer.err.items});

        return .{ .err = err_with_context.items };
    };

    const return_ty = monomorphizer.funs.get(main_signature).?.return_ty;
    if (!string.eql(return_ty, "U8")) {
        var err = String.init(alloc);
        try format(err.writer(), "The main function should return a U8, but it returns a {s}.\n", .{return_ty});
        return .{ .err = err.items };
    }

    return .{ .ok = mono.Mono{
        .ty_defs = monomorphizer.ty_defs,
        .funs = monomorphizer.funs,
    } };
}

// Maps type parameter names to fully monomorphized types.
const TyEnv = StringHashMap(Str);

const Monomorphizer = struct {
    alloc: std.mem.Allocator,
    program: ast.Program,
    context: ArrayList(Str),
    // The keys are strings of monomorphized types such as "Maybe[Int]".
    tys: StringHashMap(Ty),
    ty_defs: StringArrayHashMap(mono.TyDef),
    // The keys are strings of monomorphized function signatures such as "foo(Int)".
    funs: StringHashMap(mono.Fun),
    err: String,

    const Self = @This();

    fn put_ty(self: *Self, ty: Ty, ty_def: mono.TyDef) !void {
        var ty_name = String.init(self.alloc);
        try ty_name.writer().print("{}", .{ty});

        try self.tys.put(ty_name.items, ty);
        try self.ty_defs.put(ty_name.items, ty_def);
    }

    fn format_err(self: *Self, comptime fmt: Str, args: anytype) !void {
        try format(self.err.writer(), fmt, args);
    }

    // Looks up the given name with the given number of type args and the args
    // of the given types.
    const LookupSolution = struct { def: ast.Def, ty_env: TyEnv };
    fn lookup(
        self: *Self,
        name: Str,
        ty_args: ?[]const Str,
        args: ?[]const Str,
    ) error{ Todo, OutOfMemory, CompileError }!LookupSolution {
        var name_matches = ArrayList(ast.Def).init(self.alloc);
        for (self.program.defs.items) |def| {
            const def_name = switch (def) {
                .builtin_ty => |n| n,
                inline else => |it| it.name,
            };
            if (string.eql(name, def_name)) try name_matches.append(def);
        }

        var full_matches = ArrayList(LookupSolution).init(self.alloc);
        defs: for (name_matches.items) |def| {
            if (args) |args_| {
                const fun = switch (def) {
                    .fun => |f| f,
                    else => continue :defs, // Only funs can accept args.
                };
                if (args_.len != fun.args.items.len) continue :defs;

                var solver_ty_vars = StringHashMap(void).init(self.alloc);
                var solver_ty_env = StringHashMap(Ty).init(self.alloc);
                for (fun.ty_args.items) |ta| {
                    // TODO: Make sure type var only exists once
                    try solver_ty_vars.put(ta, {});
                }
                if (ty_args) |ty_args_| {
                    if (fun.ty_args.items.len != ty_args_.len) continue :defs;
                    for (fun.ty_args.items, ty_args_) |from, to|
                        try solver_ty_env.put(from, self.tys.get(to) orelse unreachable);
                }
                for (fun.args.items, args_) |param, arg_mono_ty| {
                    const arg_ty = self.tys.get(arg_mono_ty) orelse unreachable;
                    const is_assignable = arg_ty.is_assignable_to(solver_ty_vars, &solver_ty_env, param.ty) catch |err| {
                        if (err == error.TypeArgumentCantHaveGenerics) {
                            try self.format_err("Type arguments can't have generics.\n", .{});
                            return error.CompileError;
                        }
                        return error.Todo;
                    };
                    if (!is_assignable) continue :defs;
                }

                // TODO: Check if there are still unbound type parameters.

                // Compile types from solver ty env into mono ty env.
                var ty_env = StringHashMap(Str).init(self.alloc);
                {
                    var iter = solver_ty_env.iterator();
                    while (iter.next()) |constraint| {
                        try ty_env.put(
                            constraint.key_ptr.*,
                            self.compile_type(constraint.value_ptr.*, TyEnv.init(self.alloc)) catch |err| {
                                if (err == error.TypeArgumentCantHaveGenerics) {
                                    try self.format_err("Type arguments can't have generics.\n", .{});
                                    return error.CompileError;
                                }
                                return error.Todo;
                            },
                        );
                    }
                }

                try full_matches.append(.{ .def = .{ .fun = fun }, .ty_env = ty_env });
            } else {
                var ty_env = StringHashMap(Str).init(self.alloc);
                const ty_params = switch (def) {
                    .builtin_ty => |_| ArrayList(Str).init(self.alloc).items,
                    inline else => |it| it.ty_args.items,
                };
                const ty_args_ = ty_args orelse &[_]Str{};
                if (ty_args_.len != ty_params.len) continue :defs;
                for (ty_params, ty_args_) |from, to|
                    try ty_env.put(from, to);
                try full_matches.append(.{ .def = def, .ty_env = ty_env });
            }
        }

        if (full_matches.items.len != 1) {
            try self.format_err("This call doesn't work:\n> {s}", .{name});
            Ty.print_args_of_strs(self.err.writer(), ty_args) catch @panic("couldn't write to stdout");
            if (args) |args_| {
                try self.format_err("(", .{});
                for (args_, 0..) |arg, i| {
                    if (i > 0) try self.format_err(", ", .{});
                    try self.format_err("{s}", .{arg});
                }
                try self.format_err(")", .{});
            }
            try self.format_err("\n\n", .{});
        }

        if (full_matches.items.len == 0) {
            if (name_matches.items.len > 0) {
                try self.format_err("These definitions have the same name, but arguments don't match:\n", .{});
                for (name_matches.items) |match| {
                    try self.format_err("- ", .{});
                    ast.print_signature(self.err.writer(), match) catch @panic("couldn't write to stdout");
                    try self.format_err("\n", .{});
                }
            } else try self.format_err("There are no definitions named \"{s}\".\n", .{name});
            return error.CompileError;
        }

        if (full_matches.items.len > 1) {
            try self.format_err("Multiple definitions match:\n", .{});
            for (full_matches.items) |match| {
                try self.format_err("- ", .{});

                var padded_signature = ArrayList(u8).init(self.alloc);
                ast.print_signature(padded_signature.writer(), match.def) catch @panic("couldn't write to stdout");
                while (padded_signature.items.len < 30) try padded_signature.append(' ');
                try self.format_err("{s}", .{padded_signature.items});

                if (match.ty_env.count() > 0) {
                    try self.format_err(" with ", .{});
                    var iter = match.ty_env.iterator();
                    while (iter.next()) |constraint|
                        try self.format_err("{s} = {s}, ", .{ constraint.key_ptr.*, constraint.value_ptr.* });
                }
                try self.format_err("\n", .{});
            }
            return error.CompileError;
        }

        return full_matches.items[0];
    }

    fn compile_types(self: *Self, tys: ArrayList(Ty), ty_env: TyEnv) error{ Todo, OutOfMemory, CompileError }!ArrayList(Str) {
        var args = ArrayList(Str).init(self.alloc);
        for (tys.items) |arg|
            try args.append(try self.compile_type(arg, ty_env));
        return args;
    }

    // Specializes a type such as `Maybe[T]` using a type environment such as
    // `{T: Int}` (resulting in `Maybe[Int]`). Also creates the needed specialized
    // types in the `mono.Types`.
    fn compile_type(self: *Self, ty: Ty, ty_env: TyEnv) !Str {
        const args = try self.compile_types(ty.args, ty_env);

        if (ty_env.get(ty.name)) |name| {
            if (args.items.len > 0) {
                try self.format_err("A type argument is called with generics.\n", .{});
                return error.CompileError;
            }
            return name;
        }

        var name_buf = String.init(self.alloc);
        try name_buf.appendSlice(ty.name);
        if (args.items.len > 0) {
            if (!string.eql(ty.name, "&")) try name_buf.append('[');
            for (args.items, 0..) |arg, i| {
                if (i > 0) try name_buf.appendSlice(", ");
                try name_buf.appendSlice(arg);
            }
            if (!string.eql(ty.name, "&")) try name_buf.append(']');
        }
        const name = name_buf.items;

        switch ((try self.lookup(ty.name, args.items, null)).def) {
            .builtin_ty => |_| try self.put_ty(ty, .builtin_ty),
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
                    const variant_type = if (variant.ty) |t|
                        try self.compile_type(t, inner_ty_env)
                    else
                        "Nothing";
                    try variants.append(.{ .name = variant.name, .ty = variant_type });
                }
                try self.put_ty(.{ .name = ty.name, .args = specialized_args }, .{
                    .enum_ = .{ .variants = variants },
                });
            },
            .fun => unreachable,
        }

        return name;
    }
};

const FunMonomorphizer = struct {
    monomorphizer: *Monomorphizer,
    alloc: std.mem.Allocator,
    fun: *mono.Fun,
    ty_env: TyEnv, // the map from the fun's type parameters to concrete types
    var_env: *VarEnv, // maps local variables to types
    expected_return_ty: Str, // the return type explicitly given in the code
    return_ty: ?Str, // the inferred return type

    // When lowering loops, breaks don't know where to jump to yet. Instead,
    // they fill this structure.
    breakable_scopes: ArrayList(BreakableScope), // used like a stack
    continuable_scopes: ArrayList(ContinuableScope), // used like a stack

    const BreakableScope = struct {
        result: ?mono.StatementIndex,
        result_ty: ?Str,
        breaks: ArrayList(mono.StatementIndex),
    };
    const ContinuableScope = struct { continues: ArrayList(mono.StatementIndex) };

    const Self = @This();

    // Maps variable names to their expression index.
    const VarEnv = StringHashMap(VarInfo);
    // TODO: Type is already available as fun.types, no need for it here
    const VarInfo = struct { index: usize, ty: Str };

    fn compile(monomorphizer: *Monomorphizer, fun: ast.Fun, ty_env: TyEnv) !Str {
        const alloc = monomorphizer.alloc;

        var signature = String.init(alloc);
        var ty_args = ArrayList(Str).init(alloc);
        var arg_tys = ArrayList(Str).init(alloc);
        var var_env = VarEnv.init(alloc);

        try signature.appendSlice(fun.name);
        if (fun.ty_args.items.len > 0) {
            try signature.appendSlice("[");
            for (fun.ty_args.items, 0..) |arg, i| {
                if (i > 0) try signature.appendSlice(", ");
                const arg_ty: Str = ty_env.get(arg) orelse @panic("required type arg doesn't exist in type env");
                try ty_args.append(arg_ty);
                try signature.appendSlice(arg_ty);
            }
            try signature.appendSlice("]");
        }
        try signature.append('(');
        for (fun.args.items, 0..) |arg, i| {
            if (i > 0) try signature.appendSlice(", ");
            const arg_type = try monomorphizer.compile_type(arg.ty, ty_env);
            try arg_tys.append(arg_type);
            try signature.appendSlice(arg_type);
            try var_env.put(arg.name, .{ .index = i, .ty = arg_type });
        }
        try signature.append(')');

        if (monomorphizer.funs.contains(signature.items))
            return signature.items;

        try monomorphizer.context.append(signature.items);
        { // Printing
            var s = ArrayList(u8).init(alloc);
            try s.appendSlice("Compiling ");
            for (monomorphizer.context.items, 0..) |c, i| {
                if (i > 0) try s.appendSlice(" > ");
                var j: usize = 0;
                while (true) {
                    if (c[j] == '(' or c[j] == '[') break;
                    j += 1;
                }
                try s.appendSlice(c[0..j]);
            }
            if (s.items.len > 80) {
                s.items.len = 77;
                try s.appendSlice("...");
            }
            // try s.appendSlice(signature.items);
            print_on_same_line("{s}\n", .{s.items});
        }

        const expected_return_ty = if (fun.returns) |ty|
            try monomorphizer.compile_type(ty, ty_env)
        else
            "Nothing";

        var mono_fun = mono.Fun{
            .ty_args = ty_args,
            .arg_tys = arg_tys,
            .return_ty = expected_return_ty,
            .is_builtin = fun.is_builtin,
            .body = ArrayList(mono.Statement).init(alloc),
            .tys = ArrayList(Str).init(alloc),
        };
        for (arg_tys.items) |ty|
            _ = try mono_fun.put(.{ .arg = {} }, ty);

        try monomorphizer.funs.put(signature.items, mono_fun);

        var fun_monomorphizer = Self{
            .monomorphizer = monomorphizer,
            .alloc = alloc,
            .fun = &mono_fun,
            .ty_env = ty_env,
            .var_env = &var_env,
            .expected_return_ty = expected_return_ty,
            .return_ty = null,
            .breakable_scopes = ArrayList(BreakableScope).init(alloc),
            .continuable_scopes = ArrayList(ContinuableScope).init(alloc),
        };

        const body_result = try fun_monomorphizer.compile_body(fun.body.items);
        if (!string.eql(body_result.ty, "Never")) {
            _ = try mono_fun.put(.{ .return_ = body_result }, "Never");
            // TODO: Make sure body has the correct type
        }

        // For builtin functions, we trust the fully specified return type.
        // For user-written functions, we take the actual return type.
        if (!fun.is_builtin) {
            try fun_monomorphizer.new_returned_ty(body_result.ty);
            mono_fun.return_ty = fun_monomorphizer.return_ty orelse body_result.ty;
        }

        try monomorphizer.funs.put(signature.items, mono_fun);

        _ = monomorphizer.context.pop();

        return signature.items;
    }
    fn format_err(self: *Self, comptime fmt: Str, args: anytype) !void {
        try self.monomorphizer.format_err(fmt, args);
    }

    fn new_returned_ty(self: *Self, returned: Str) !void {
        if (string.eql(returned, "Never")) return;

        // TODO: Allow placeholders in types
        if (!string.eql(returned, self.expected_return_ty)) {
            try self.format_err(
                "This function should return {s}, but it returns {s}.\n",
                .{ self.expected_return_ty, returned },
            );
            return error.CompileError;
        }

        if (self.return_ty) |expected_ty| if (!string.eql(returned, expected_ty)) {
            try self.format_err(
                "This function returns {s} in a previous return, but {s} at some place.\n",
                .{ expected_ty, returned },
            );
            return error.CompileError;
        };

        self.return_ty = returned;
    }

    fn compile_expr(self: *Self, expression: ast.Expr) error{ Todo, OutOfMemory, CompileError }!mono.Expr {
        if (try self.compile_break(expression)) |expr| return expr;
        if (try self.compile_continue(expression)) |expr| return expr;

        // This may be an enum variant instantiation such as `Maybe[Int].some(3)`.
        if (try self.compile_enum_creation(expression)) |expr| return expr;
        switch (expression) {
            .int => |int| return try self.fun.put_and_get_expr(
                .{ .int = .{ .value = int.value, .signedness = int.signedness, .bits = int.bits } },
                try numbers.int_ty_name(self.alloc, .{ .signedness = int.signedness, .bits = int.bits }),
            ),
            .string => |str| {
                const u8_ty: Ty = .{ .name = "U8", .args = ArrayList(Ty).init(self.alloc) };

                var slice_ty_args = ArrayList(Ty).init(self.alloc);
                try slice_ty_args.append(u8_ty);
                const slice_ty: Ty = .{ .name = "Slice", .args = slice_ty_args };

                _ = try self.monomorphizer.compile_type(u8_ty, TyEnv.init(self.alloc));
                _ = try self.monomorphizer.compile_type(slice_ty, TyEnv.init(self.alloc));

                return try self.fun.put_and_get_expr(.{ .string = str }, "Slice[U8]");
            },
            .ref => |name| {
                if (self.var_env.get(name)) |var_info| return .{
                    .kind = .{ .statement = var_info.index },
                    .ty = var_info.ty,
                };

                // TODO: Try to lookup type.
                try self.format_err("No \"{s}\" is in scope.\n", .{name});
                return error.CompileError;
            },
            .call => |call| {
                var callee = call.callee.*;
                var ty_args: ?ArrayList(Str) = null;
                var args = ArrayList(mono.Expr).init(self.alloc);

                switch (callee) {
                    .ty_arged => |ta| {
                        callee = ta.arged.*;
                        ty_args = try self.monomorphizer.compile_types(ta.ty_args, self.ty_env);
                    },
                    else => {},
                }
                var compiled_callee: ?mono.Expr = null;
                const name = find_name: {
                    switch (callee) {
                        // Calls of the form `something.name()` cause `something` to
                        // be treated like an extra argument.
                        .member => |member| {
                            compiled_callee = try self.compile_expr(member.of.*);
                            break :find_name member.name;
                        },
                        .ref => |name| break :find_name name,
                        else => {
                            try self.format_err("You tried to call this expression:\n", .{});
                            try self.format_err("> ", .{});
                            ast.print_expr(self.monomorphizer.err.writer(), 2, callee) catch
                                @panic("formatting failed");
                            try self.format_err("\n{any}", .{callee});

                            try self.format_err("\n\nThis expression can't be called.\n", .{});
                            return error.CompileError;
                        },
                    }
                };
                for (call.args.items) |arg| try args.append(try self.compile_expr(arg));

                var ty_args_: ?[]const Str = null;
                if (ty_args) |ta| ty_args_ = ta.items;
                return self.compile_call(name, compiled_callee, ty_args_, args.items);
            },
            .member => |m| {
                // Struct field access.
                var of = try self.alloc.create(mono.Expr);
                of.* = try self.compile_expr(m.of.*);

                const field_ty = field_ty: while (true) {
                    // When accessing a member on a reference, we automatically
                    // dereference the receiver as often as necessary. For
                    // example, you can access point.x if point is a &&&Point.
                    if (!string.eql(m.name, "*") and string.starts_with(of.ty, "&")) {
                        const dereference = try self.alloc.create(mono.Expr);
                        dereference.* = .{
                            .ty = of.ty[1..], // trim the leading &
                            .kind = .{ .member = .{ .of = of, .name = "*" } },
                        };
                        of = dereference;
                        continue;
                    }

                    const of_type_def = self.monomorphizer.ty_defs.get(of.ty) orelse unreachable;
                    const struct_ = switch (of_type_def) {
                        .struct_ => |s| s,
                        else => {
                            try self.format_err("You tried to access a field on {s}, but it's not a struct.\n", .{of.ty});
                            return error.CompileError;
                        },
                    };
                    for (struct_.fields.items) |field|
                        if (string.eql(field.name, m.name))
                            break :field_ty field.ty;
                    try self.format_err("\"{s}\" is not a field on {s}.\n", .{ m.name, of.ty });
                    try self.format_err("{any}\n", .{(!string.eql(m.name, "*") and string.starts_with(of.ty, "&"))});
                    try self.format_err("It only contains these fields:\n", .{});
                    for (struct_.fields.items) |field|
                        try self.format_err("- {s}\n", .{field.name});
                    return error.CompileError;
                };
                return .{ .kind = .{ .member = .{ .of = of, .name = m.name } }, .ty = field_ty };
            },
            .var_ => |v| {
                const value = try self.compile_expr(v.value.*);
                const var_ = try self.fun.put(.{ .uninitialized = {} }, value.ty);
                _ = try self.fun.put(.{ .assign = .{
                    .to = .{ .kind = .{ .statement = var_ }, .ty = value.ty },
                    .value = value,
                } }, value.ty);
                try self.var_env.put(v.name, .{ .index = var_, .ty = value.ty });
                return .{ .kind = .{ .statement = var_ }, .ty = value.ty };
            },
            .assign => |assign| {
                const value = try self.compile_expr(assign.value.*);
                const to = try self.compile_expr(assign.to.*);
                return try self.fun.put_and_get_expr(.{ .assign = .{ .to = to, .value = value } }, "Nothing");
            },
            .struct_creation => |sc| {
                const ty = self.expr_to_type(sc.ty.*) orelse {
                    try self.format_err("You can only construct structs.\n", .{});
                    return error.CompileError;
                };
                const struct_type = try self.monomorphizer.compile_type(ty, self.ty_env);

                var fields = StringHashMap(mono.Expr).init(self.alloc);
                for (sc.fields.items) |f|
                    try fields.put(f.name, try self.compile_expr(f.value));

                return try self.fun.put_and_get_expr(.{ .struct_creation = .{
                    .struct_ty = struct_type,
                    .fields = fields,
                } }, struct_type);
            },
            .if_ => |if_| {
                const result = try self.fun.put(.{ .uninitialized = {} }, "Something"); // Type will be replaced later
                var result_ty: ?Str = null;

                const condition = try self.compile_expr(if_.condition.*);
                if (!string.eql(condition.ty, "Bool")) {
                    try self.format_err("The if condition has to be a Bool, but it was {s}.\n", .{condition.ty});
                    return error.CompileError;
                }
                const jump_if_true = try self.fun.put(.{ .uninitialized = {} }, "Nothing"); // Will be replaced with jump_if
                const jump_if_false = try self.fun.put(.{ .uninitialized = {} }, "Never"); // Will be replaced with jump

                // TODO: Create inner var env
                const then_body = self.fun.next_index();
                const then_result = try self.compile_expr(if_.then.*);
                if (!string.eql(then_result.ty, "Never")) {
                    result_ty = then_result.ty;
                    _ = try self.fun.put(.{ .assign = .{
                        .to = .{ .ty = result_ty.?, .kind = .{ .statement = result } },
                        .value = then_result,
                    } }, "Nothing");
                }
                const jump_after_then = try self.fun.put(.{ .uninitialized = {} }, "Never"); // Will be replaced with jump

                if (if_.else_) |else_| {
                    // TODO: Create inner var env
                    const else_body = self.fun.next_index();
                    const else_result = try self.compile_expr(else_.*);
                    if (!string.eql(else_result.ty, "Never")) {
                        if (result_ty) |expected_ty| {
                            if (!string.eql(expected_ty, else_result.ty)) {
                                try self.format_err("An if is inconsistenly typed:\n", .{});
                                try self.format_err("- The then body returns {s}.\n", .{expected_ty});
                                try self.format_err("- The else body returns {s}.\n", .{else_result.ty});
                                return error.CompileError;
                            }
                        } else result_ty = else_result.ty;

                        _ = try self.fun.put(.{ .assign = .{
                            .to = .{ .ty = result_ty.?, .kind = .{ .statement = result } },
                            .value = else_result,
                        } }, "Nothing");
                    }
                    const jump_after_else = try self.fun.put(.{ .uninitialized = {} }, "Never"); // Will be replaced with jump
                    const after_if = self.fun.next_index();

                    // Fill in jumps
                    self.fun.body.items[jump_if_true] = .{ .jump_if_variant = .{ .condition = condition, .variant = "true", .target = then_body } };
                    self.fun.body.items[jump_if_false] = .{ .jump = .{ .target = else_body } };
                    self.fun.body.items[jump_after_then] = .{ .jump = .{ .target = after_if } };
                    self.fun.body.items[jump_after_else] = .{ .jump = .{ .target = after_if } };
                } else {
                    const after_if = self.fun.next_index();

                    // Fill in jumps
                    self.fun.body.items[jump_if_true] = .{ .jump_if_variant = .{ .condition = condition, .variant = "true", .target = then_body } };
                    self.fun.body.items[jump_if_false] = .{ .jump = .{ .target = after_if } };
                    self.fun.body.items[jump_after_then] = .{ .jump = .{ .target = after_if } };
                }

                self.fun.tys.items[result] = result_ty orelse "Never";
                return .{ .kind = .{ .statement = result }, .ty = then_result.ty };
            },
            .switch_ => |switch_| {
                const result = try self.fun.put(.{ .uninitialized = {} }, "Something"); // Type will be replaced later
                var result_ty: ?Str = null;

                const value = try self.compile_expr(switch_.value.*);
                const enum_def = switch (self.monomorphizer.ty_defs.get(value.ty).?) {
                    .enum_ => |e| e,
                    else => {
                        try self.format_err("You tried to switch on {s}, but you can only switch on enums.\n", .{value.ty});
                        return error.CompileError;
                    },
                };

                // Jump table
                const jump_table_start = self.fun.next_index();
                for (switch_.cases.items) |_|
                    _ = try self.fun.put(.{ .uninitialized = {} }, "Nothing"); // Will be replaced with jump_if_variant

                // TODO: instead of looping, ensure all cases are matched
                // TODO: ensure cases aren't handled multiple times
                _ = try self.fun.put(.{ .jump = .{ .target = jump_table_start } }, "Never"); // unreachable

                // Case bodies
                var after_switch_jumps = ArrayList(mono.StatementIndex).init(self.alloc);
                for (switch_.cases.items, 0..) |case, i| {
                    self.fun.body.items[jump_table_start + i] = .{ .jump_if_variant = .{
                        .condition = value,
                        .variant = case.variant,
                        .target = self.fun.next_index(),
                    } };
                    const ty = find_ty: {
                        for (enum_def.variants.items) |variant|
                            if (string.eql(variant.name, case.variant))
                                break :find_ty variant.ty;
                        try self.format_err("You switched on {s}, which doesn't have a \"{s}\" variant.\n", .{ value.ty, case.variant });
                        return error.CompileError;
                    };
                    const unpacked = try self.fun.put(.{ .get_enum_value = .{ .of = value, .variant = case.variant, .ty = ty } }, ty);
                    // TODO: Create inner var env
                    // const inner_self.var_env = self.var_env.clone();
                    if (case.binding) |binding|
                        try self.var_env.put(binding, .{ .index = unpacked, .ty = ty });

                    const then_result = try self.compile_expr(case.then.*);
                    if (!string.eql(then_result.ty, "Never")) {
                        if (result_ty) |expected_ty| {
                            if (!string.eql(expected_ty, then_result.ty)) {
                                try self.format_err(
                                    "Previous switch cases return {s}, but the case for \"{s}\" returns {s}.\n",
                                    .{ expected_ty, case.variant, then_result.ty },
                                );
                                return error.CompileError;
                            }
                        } else result_ty = then_result.ty;

                        _ = try self.fun.put(.{ .assign = .{
                            .to = .{ .ty = self.fun.tys.items[result], .kind = .{ .statement = result } },
                            .value = then_result,
                        } }, "Nothing");
                    }
                    try after_switch_jumps.append(try self.fun.put(.{ .uninitialized = {} }, "Never")); // will be replaced with jump to after switch
                }
                const after_switch = self.fun.next_index();
                for (after_switch_jumps.items) |jump|
                    self.fun.body.items[jump] = .{ .jump = .{ .target = after_switch } };

                const final_ty = result_ty orelse "Never";
                self.fun.tys.items[result] = final_ty;
                return .{ .kind = .{ .statement = result }, .ty = final_ty };
            },
            .orelse_ => |orelse_| {
                // primary = ...
                // result = uninitialized
                // jump_if_variant primary none >---------+
                // result = get_enum_variant result some  |
                // jump >------------------------------+  |
                // alternative = ...                   |  |
                // result = alternative                |  |
                // [after] <---------------------------+--+

                const primary = try self.compile_expr(orelse_.primary.*);
                if (!string.starts_with(primary.ty, "Maybe[")) {
                    try self.format_err("The left side of an orelse has to be a Maybe, but it was {s}.\n", .{primary.ty});
                    return error.CompileError;
                }
                const primary_ty = primary.ty["Maybe[".len .. primary.ty.len - "]".len];

                const result = try self.fun.put(.{ .uninitialized = {} }, "Something"); // Type will be replaced later
                var result_ty: ?Str = null;

                const jump_if_none = try self.fun.put(.{
                    .jump_if_variant = .{ .condition = primary, .variant = "none", .target = 0 },
                }, "Nothing"); // target be replaced with jump_if
                const unwrapped = try self.fun.put(.{ .get_enum_value = .{ .of = primary, .variant = "some", .ty = primary_ty } }, "Nothing");
                if (!string.eql(primary_ty, "Never")) {
                    _ = try self.fun.put(.{ .assign = .{
                        .to = .{ .ty = "Nothing", .kind = .{ .statement = result } },
                        .value = .{ .ty = primary_ty, .kind = .{ .statement = unwrapped } },
                    } }, "Nothing");
                    result_ty = primary_ty;
                }
                const jump_if_some = try self.fun.put(.{ .jump = .{ .target = 0 } }, "Never"); // target will be replaced

                // TODO: Create inner var env
                const alternative_target = self.fun.next_index();
                const alternative = try self.compile_expr(orelse_.alternative.*);
                if (!string.eql(alternative.ty, "Never")) {
                    if (result_ty) |expected_ty| {
                        if (!string.eql(expected_ty, alternative.ty)) {
                            try self.format_err("An orelse is inconsistenly typed:\n", .{});
                            try self.format_err("- The primary expression is a Maybe of {s}.\n", .{expected_ty});
                            try self.format_err("- The alternative is a {s}.\n", .{alternative.ty});
                            return error.CompileError;
                        }
                    } else result_ty = alternative.ty;

                    _ = try self.fun.put(.{ .assign = .{
                        .to = .{ .ty = result_ty.?, .kind = .{ .statement = result } },
                        .value = alternative,
                    } }, "Nothing");
                }

                const after_orelse = self.fun.next_index();

                self.fun.body.items[jump_if_none].jump_if_variant.target = alternative_target;
                self.fun.body.items[jump_if_some].jump.target = after_orelse;

                const final_ty = result_ty orelse "Never";
                self.fun.tys.items[result] = final_ty;
                return .{ .kind = .{ .statement = result }, .ty = final_ty };
            },
            .loop => |expr| {
                const result = try self.fun.put(.{ .uninitialized = {} }, "Nothing"); // type will be replaced
                try self.breakable_scopes.append(.{
                    .result = result,
                    .result_ty = null,
                    .breaks = ArrayList(mono.StatementIndex).init(self.alloc),
                });
                try self.continuable_scopes.append(.{
                    .continues = ArrayList(mono.StatementIndex).init(self.alloc),
                });
                // TODO: Create inner var env
                const loop_start = self.fun.next_index();
                _ = try self.compile_expr(expr.*);
                _ = try self.fun.put(.{ .jump = .{ .target = loop_start } }, "Never");

                const after_loop = self.fun.next_index();
                {
                    const scope = self.breakable_scopes.pop();
                    if (scope.result_ty) |ty| self.fun.tys.items[result] = ty;
                    for (scope.breaks.items) |b| self.fun.body.items[b] = .{ .jump = .{ .target = after_loop } };
                }
                {
                    const scope = self.continuable_scopes.pop();
                    for (scope.continues.items) |b| self.fun.body.items[b] = .{ .jump = .{ .target = loop_start } };
                }

                return .{ .kind = .{ .statement = result }, .ty = self.fun.tys.items[result] };
            },
            .for_ => |for_| {
                try self.breakable_scopes.append(.{
                    .result = null,
                    .result_ty = null,
                    .breaks = ArrayList(mono.StatementIndex).init(self.alloc),
                });

                const iter = try self.compile_expr(for_.iter.*);
                const loop_start = self.fun.next_index();

                const result_of_next = try self.compile_call("next", iter, null, &[_]mono.Expr{});
                const next_ty = self.monomorphizer.tys.get(result_of_next.ty) orelse unreachable;
                if (!string.eql(next_ty.name, "Maybe")) {
                    try self.format_err("The iterator's next function returns {s}, not Maybe.\n", .{result_of_next.ty});
                    return error.CompileError;
                }
                const unpacked_ty = result_of_next.ty["Maybe[".len .. result_of_next.ty.len - "]".len];

                // Will be replaced with a jump_if_variant none
                const jump_out = try self.fun.put(.{ .uninitialized = {} }, "Never");

                const unpacked = try self.fun.put(.{ .get_enum_value = .{
                    .of = result_of_next,
                    .variant = "some",
                    .ty = unpacked_ty,
                } }, unpacked_ty);
                // TODO: Create inner var env
                // const inner_self.var_env = self.var_env.clone();
                try self.var_env.put(for_.iter_var, .{ .index = unpacked, .ty = unpacked_ty });

                _ = try self.compile_expr(for_.expr.*);
                _ = try self.fun.put(.{ .jump = .{ .target = loop_start } }, "Never");

                const after_loop = self.fun.next_index();
                self.fun.body.items[jump_out] = .{ .jump_if_variant = .{
                    .condition = result_of_next,
                    .variant = "none",
                    .target = after_loop,
                } };
                const scope = self.breakable_scopes.pop();
                for (scope.breaks.items) |b|
                    self.fun.body.items[b] = .{ .jump = .{ .target = after_loop } };
                return self.compile_nothing_instance();
            },
            .return_ => |returned| {
                const compiled_arg = try self.compile_expr(returned.*);
                try self.new_returned_ty(compiled_arg.ty);
                return try self.fun.put_and_get_expr(.{ .return_ = compiled_arg }, "Never");
            },
            .ampersanded => |expr| {
                const amped = try self.compile_expr(expr.*);
                const ty = self.monomorphizer.tys.get(amped.ty) orelse unreachable;

                var args = ArrayList(Ty).init(self.alloc);
                try args.append(ty);
                const ref_ty: Ty = .{ .name = "&", .args = args };
                const compiled_ref_ty = try self.monomorphizer.compile_type(ref_ty, self.ty_env);

                return try self.fun.put_and_get_expr(.{ .ref = amped }, compiled_ref_ty);
            },
            .body => |body| return try self.compile_body(body.items),
            else => {
                try self.format_err("Compiling {any}\n", .{expression});
                return error.Todo;
            },
        }
    }

    fn compile_body(self: *Self, body: []const ast.Expr) !mono.Expr {
        var last: ?mono.Expr = null;
        for (body) |expr| last = try self.compile_expr(expr);
        return if (last) |l| l else try self.compile_nothing_instance();
    }

    fn compile_nothing_instance(self: *Self) !mono.Expr {
        return try self.fun.put_and_get_expr(.{ .struct_creation = .{
            .struct_ty = "Nothing",
            .fields = StringHashMap(mono.Expr).init(self.alloc),
        } }, "Nothing");
    }

    fn compile_call(self: *Self, name: Str, callee: ?mono.Expr, ty_args: ?[]const Str, args: []const mono.Expr) !mono.Expr {
        var full_args = ArrayList(mono.Expr).init(self.alloc);
        if (callee) |c| try full_args.append(c);
        try full_args.appendSlice(args);

        var arg_tys = ArrayList(Str).init(self.alloc);
        for (full_args.items) |arg| try arg_tys.append(arg.ty);

        // If a call has a callee and it's a ref, it also matches functions
        // where it's dereferenced. For example, if you have a value of type T,
        // calling value.foo() also matches foo(&T).
        var first_error: ?String = null;
        var called_fun: ?ast.Fun = null;
        var call_ty_env: ?TyEnv = null;
        while (true) {
            const lookup_solution = self.monomorphizer.lookup(name, ty_args, arg_tys.items) catch |err| {
                if (err != error.CompileError) return err;
                if (first_error == null) first_error = self.monomorphizer.err;
                self.monomorphizer.err = String.init(self.alloc);

                if (callee != null and string.starts_with(arg_tys.items[0], "&")) {
                    // There is a callee and it's a reference. Dereference it.
                    const derefed_callee = try self.alloc.create(mono.Expr);
                    derefed_callee.* = full_args.items[0];
                    const deref_ty = arg_tys.items[0][1..]; // trim &
                    full_args.items[0] = .{
                        .ty = deref_ty,
                        .kind = .{ .member = .{ .of = derefed_callee, .name = "*" } },
                    };
                    arg_tys.items[0] = deref_ty;
                    continue;
                } else {
                    self.monomorphizer.err = first_error.?;
                    return error.CompileError;
                }
            };

            called_fun = lookup_solution.def.fun;
            call_ty_env = lookup_solution.ty_env;
            break;
        }

        // TODO: Make sure all type args are different.

        const fun_name = try FunMonomorphizer.compile(self.monomorphizer, called_fun.?, call_ty_env.?);
        const return_type = if (called_fun.?.returns) |ty|
            try self.monomorphizer.compile_type(ty, call_ty_env.?)
        else
            "Nothing";

        return try self.fun.put_and_get_expr(.{ .call = .{ .fun = fun_name, .args = full_args } }, return_type);
    }

    // Some calls and some refs may be breaks. For example, `break(5)` and `break` both break.
    fn compile_break(self: *Self, expr: ast.Expr) !?mono.Expr {
        const arg: ?ast.Expr = break_arg: {
            switch (expr) {
                .ref => |name| if (string.eql(name, "break"))
                    break :break_arg null
                else
                    return null,
                .call => |call| switch (call.callee.*) {
                    .ref => |name| if (string.eql(name, "break")) {
                        if (call.args.items.len == 0) break :break_arg null;
                        if (call.args.items.len == 1) break :break_arg call.args.items[0];
                        try self.format_err("break can only take one argument.\n", .{});
                        return error.CompileError;
                    } else return null,
                    else => return null,
                },
                else => return null,
            }
        };

        const compiled_arg: mono.Expr = if (arg) |a|
            try self.compile_expr(a)
        else
            try self.compile_nothing_instance();

        const arg_ty = compiled_arg.ty;

        if (self.breakable_scopes.items.len == 0) {
            try self.format_err("break outside of a loop", .{});
            return error.CompileError;
        }
        var scope = &self.breakable_scopes.items[self.breakable_scopes.items.len - 1];

        if (scope.result) |result| {
            if (scope.result_ty) |expected_ty| if (!string.eql(arg_ty, expected_ty)) {
                try self.format_err("A previous break returned {s}, but this break returns {s}.\n", .{ expected_ty, arg_ty });
                return error.CompileError;
            };

            scope.result_ty = arg_ty;

            _ = try self.fun.put(.{ .assign = .{
                .to = .{ .ty = arg_ty, .kind = .{ .statement = result } },
                .value = compiled_arg,
            } }, "Nothing");
        } else if (arg) |_| {
            try self.format_err("Breaks in for can't take an argument.\n", .{});
            return error.CompileError;
        }

        const jump = try self.fun.put(.{ .uninitialized = {} }, "Never"); // will be replaced by jump to after loop
        try scope.breaks.append(jump);
        return .{ .kind = .{ .statement = jump }, .ty = "Never" };
    }

    // Some refs may be continues.
    fn compile_continue(self: *Self, expr: ast.Expr) !?mono.Expr {
        switch (expr) {
            .ref => |name| if (!string.eql(name, "continue")) return null,
            else => return null,
        }

        if (self.continuable_scopes.items.len == 0) {
            try self.format_err("continue outside of a loop", .{});
            return error.CompileError;
        }
        var scope = &self.continuable_scopes.items[self.continuable_scopes.items.len - 1];

        const jump = try self.fun.put(.{ .uninitialized = {} }, "Never"); // will be replaced by jump to loop start
        try scope.continues.append(jump);
        return .{ .kind = .{ .statement = jump }, .ty = "Never" };
    }

    // Some calls and some members may be enum creations. For example, `Maybe[U8].some(4_u8)` and
    // `Bool.true` both create enum variants.
    fn compile_enum_creation(self: *Self, expr_: ast.Expr) !?mono.Expr {
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
        if (self.var_env.contains(enum_name)) return null;

        const compiled_ty_args = try self.monomorphizer.compile_types(enum_ty_args, self.ty_env);
        const solution = try self.monomorphizer.lookup(enum_name, compiled_ty_args.items, null);
        const enum_def = switch (solution.def) {
            .enum_ => |e| e,
            else => return null,
        };
        const enum_ty = try self.monomorphizer.compile_type(.{ .name = enum_name, .args = enum_ty_args }, self.ty_env);

        find_variant: {
            for (enum_def.variants.items) |variant| {
                if (string.eql(variant.name, member.name)) break :find_variant;
            }
            // Did not find a variant. Restore the sacred timeline.
            try self.format_err("You tried to instantiate the enum {s}, which doesn't have a \"{s}\" variant.\n", .{ enum_ty, member.name });
            return error.CompileError;
        }

        const compiled_value = try self.alloc.create(mono.Expr);
        compiled_value.* = if (value) |val|
            try self.compile_expr(val)
        else
            try self.compile_nothing_instance();

        return try self.fun.put_and_get_expr(.{ .variant_creation = .{
            .enum_ty = enum_ty,
            .variant = member.name,
            .value = compiled_value,
        } }, enum_ty);
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
