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
///   0_U8
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
const ArrayHashMap = std.ArrayHashMap;
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
        .ty_defs = mono.TyDefs.init(alloc),
        .funs = StringHashMap(mono.Fun).init(alloc),
        .err = String.init(alloc),
    };
    _ = try monomorphizer.compile_type(Ty.named("Never"));
    _ = try monomorphizer.compile_type(Ty.named("Nothing"));
    for (numbers.all_int_configs()) |config| {
        try monomorphizer.ty_defs.put(try numbers.int_ty(alloc, config), .builtin_ty);
    }

    const main = (try monomorphizer.lookup_fun("main", &[_]Ty{}, &[_]Ty{})).fun;

    const main_signature = FunMonomorphizer.compile(&monomorphizer, main, TyEnv.init(alloc)) catch |error_| {
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
    if (!return_ty.eql(Ty.named("Never"))) {
        var err = String.init(alloc);
        try format(err.writer(), "The main function should return Never, but it returns a {s}. You can call exit(U8) if you want the program to stop.\n", .{return_ty});
        return .{ .err = err.items };
    }

    return .{ .ok = mono.Mono{
        .ty_defs = monomorphizer.ty_defs,
        .funs = monomorphizer.funs,
    } };
}

// Maps type parameter names to fully monomorphized types.
const TyEnv = StringHashMap(Ty);

const Monomorphizer = struct {
    alloc: std.mem.Allocator,
    program: ast.Program,
    context: ArrayList(Str),
    ty_defs: mono.TyDefs,
    // The keys are strings of monomorphized function signatures such as "foo(Int)".
    funs: StringHashMap(mono.Fun),
    err: String,

    const Self = @This();

    fn format_err(self: *Self, comptime fmt: Str, args: anytype) !void {
        try format(self.err.writer(), fmt, args);
    }

    // Looks up a type with the given name. Type names have to be unique.
    fn lookup_ty(self: *Self, name: Str) error{ Todo, OutOfMemory, CompileError }!ast.Def {
        var matches = ArrayList(ast.Def).init(self.alloc);
        for (self.program) |def| {
            const def_name = switch (def) {
                .builtin_ty => |n| n,
                inline else => |it| it.name,
            };
            if (string.eql(name, def_name)) try matches.append(def);
        }

        if (matches.items.len == 0) {
            try self.format_err("There are no definitions named \"{s}\".\n", .{name});
            return error.CompileError;
        }
        if (matches.items.len > 1) {
            try self.format_err("There are multiple types named \"{s}\".\n", .{name});
            return error.CompileError;
        }

        return matches.items[0];
    }

    // Looks up the function with the given name, the given number of type args
    // (null means they might be inferred) and the args of the given types.
    const LookupFunSolution = struct { fun: ast.Fun, ty_env: TyEnv };
    fn lookup_fun(
        self: *Self,
        name: Str,
        ty_args: ?[]const Ty,
        args: ?[]const Ty,
    ) error{ Todo, OutOfMemory, CompileError, WrongNumberOfGenerics }!LookupFunSolution {
        var name_matches = ArrayList(ast.Fun).init(self.alloc);
        for (self.program) |def| {
            const def_name = switch (def) {
                .fun => |f| f.name,
                else => continue,
            };
            if (string.eql(name, def_name)) try name_matches.append(def.fun);
        }

        var full_matches = ArrayList(LookupFunSolution).init(self.alloc);
        funs: for (name_matches.items) |fun| {
            if (args) |args_| {
                if (args_.len != fun.args.count()) continue :funs;

                var solver = try TySolver.init(self, fun.ty_args);
                if (ty_args) |ty_args_| {
                    if (fun.ty_args.len != ty_args_.len) continue :funs;
                    for (fun.ty_args, ty_args_) |param, arg| {
                        const param_ = Ty.named(param);
                        if (!try solver.unify(param_, arg)) unreachable;
                    }
                }
                var args__ = fun.args.iterator();
                for (0..fun.args.count(), args_) |i, arg_ty| {
                    _ = i;
                    const param = args__.next().?;
                    if (!try solver.unify(param.value_ptr.*, arg_ty)) continue :funs;
                }
                const ty_env = try solver.finish("When considering fun {s}:\n", .{fun.name});

                try full_matches.append(.{ .fun = fun, .ty_env = ty_env });
            } else {
                var ty_env = TyEnv.init(self.alloc);
                const ty_params = fun.ty_args;
                const ty_args_ = ty_args orelse &[_]Ty{};
                if (ty_args_.len != ty_params.len) continue :funs;
                for (ty_params, ty_args_) |from, to|
                    try ty_env.put(from, to);
                try full_matches.append(.{ .fun = fun, .ty_env = ty_env });
            }
        }

        if (full_matches.items.len != 1) {
            try self.format_err("This call doesn't work:\n> {s}", .{name});
            Ty.print_args_of_tys(self.err.writer(), ty_args) catch @panic("couldn't write to stdout");
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
                    ast.print_signature(self.err.writer(), .{ .fun = match }) catch @panic("couldn't write signature");
                    try self.format_err("\n", .{});
                }
            } else try self.format_err("There are no definitions named \"{s}\".\n", .{name});
            return error.CompileError;
        }

        if (full_matches.items.len > 1) {
            try self.format_err("Multiple definitions match:\n", .{});
            for (full_matches.items) |match| {
                try self.format_err("- ", .{});

                var padded_signature = String.init(self.alloc);
                ast.print_signature(padded_signature.writer(), .{ .fun = match.fun }) catch @panic("couldn't write signature");
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

    fn compile_types(self: *Self, tys: []const Ty) error{ Todo, OutOfMemory, CompileError }![]const Str {
        var args = ArrayList(Str).init(self.alloc);
        for (tys) |arg| try args.append(try self.compile_type(arg));
        return args.items;
    }

    // Creates the needed type defs.
    fn compile_type(self: *Self, ty: Ty) !void {
        if (self.ty_defs.contains(ty)) return;
        try self.ty_defs.put(ty, .{ .builtin_ty = {} });

        switch (try self.lookup_ty(ty.name)) {
            .builtin_ty => |_| try self.ty_defs.put(ty, .builtin_ty),
            .struct_ => |s| {
                var ty_env = TyEnv.init(self.alloc);
                if (ty.args.len != s.ty_args.len) {
                    return error.WrongNumberOfGenerics;
                }
                for (s.ty_args, ty.args) |from, to| {
                    try ty_env.put(from, to);
                }

                var fields = ArrayList(mono.Field).init(self.alloc);
                var iter = s.fields.iterator();
                while (iter.next()) |field| {
                    const field_ty = try field.value_ptr.specialize(self.alloc, ty_env);
                    try self.compile_type(field_ty);
                    try fields.append(.{ .name = field.key_ptr.*, .ty = field_ty });
                }
                try self.ty_defs.put(ty, .{ .struct_ = .{ .fields = fields.items } });
            },
            .enum_ => |e| {
                var ty_env = TyEnv.init(self.alloc);
                if (ty.args.len != e.ty_args.len) {
                    return error.WrongNumberOfGenerics;
                }
                for (e.ty_args, ty.args) |from, to| {
                    try ty_env.put(from, to);
                }

                var variants = ArrayList(mono.Variant).init(self.alloc);
                var iter = e.variants.iterator();
                while (iter.next()) |variant| {
                    const variant_ty = try variant.value_ptr.specialize(self.alloc, ty_env);
                    try self.compile_type(variant_ty);
                    try variants.append(.{ .name = variant.key_ptr.*, .ty = variant_ty });
                }
                try self.ty_defs.put(ty, .{ .enum_ = .{ .variants = variants.items } });
            },
            .fun => unreachable,
        }
    }
};

// When using generic code, the free type variables need to be bound to concrete
// types. This struct helps with that. How to use:
//
// 1. Create it, passing type variables that need to be bound.
// 2. Repeatedly call unify with the concrete types of the usage site and the
//    type in the generic code.
//    - For calls, unify all arguments.
//    - For struct creations, unify all fields.
//    - For enum creations, unify the argument.
// 3. Call finish. This ensures that no type variables are unbound and it
//    returns a new TyEnv that can be used to specialize the generic code to the
//    usage site.
//
// Example:
// You want to specialize the function foo[A](Foo[A], A) for a call site with
// the argument types foo(Foo[Baz], Baz).
// 1. Create a solver with A as a type var.
// 2. Call unify:
//    - unify(Foo[Baz], A)
//    - unify(Baz, A)
// 3. Call finish to get the TyEnv {A: Baz}.
const TySolver = struct {
    monomorphizer: *Monomorphizer, // used for alloc, compile_type and error reporting
    ty_vars: StringHashMap(void),
    ty_env: TyEnv, // note: not the same type as TyEnv from monomorphizer (StringHashMap(Str))

    const Self = @This();

    fn init(monomorphizer: *Monomorphizer, ty_vars: []const Str) !Self {
        // TODO: Make sure type var only exists once
        var ty_vars_ = StringHashMap(void).init(monomorphizer.alloc);
        for (ty_vars) |var_| try ty_vars_.put(var_, {});
        return Self{
            .monomorphizer = monomorphizer,
            .ty_vars = ty_vars_,
            .ty_env = TyEnv.init(monomorphizer.alloc),
        };
    }

    // Calling this adds the constraint that `concrete` needs to be assignable
    // to `generic`. Returns whether that works.
    fn unify(self: *Self, generic: Ty, concrete: Ty) !bool {
        // Under ty env `{A: Int}`, is `Str` assignable to `A`? Depends on
        // whether `Str` is assignable to `Int`.
        if (self.ty_env.get(generic.name)) |mapped| {
            if (generic.args.len > 0) {
                try self.monomorphizer.format_err("Generics can't have type arguments.\n", .{});
                return error.CompileError;
            }
            if (self.ty_vars.contains(mapped.name)) unreachable;
            return self.unify(mapped, concrete);
        }

        if (self.ty_vars.get(generic.name)) |_| {
            try self.ty_env.put(generic.name, concrete);
            return true;
        }

        if (!string.eql(generic.name, concrete.name)) return false;
        if (generic.args.len != concrete.args.len) return false;
        for (generic.args, concrete.args) |generic_arg, concrete_arg|
            if (!try self.unify(generic_arg, concrete_arg))
                return false;

        return true;
    }

    fn finish(self: Self, comptime err_fmt: Str, err_args: anytype) !TyEnv {
        var var_iter = self.ty_vars.iterator();
        while (var_iter.next()) |var_| {
            const name = var_.key_ptr.*;
            if (!self.ty_env.contains(name)) {
                try self.monomorphizer.format_err(err_fmt, err_args);
                if (self.ty_env.count() > 0) {
                    try self.monomorphizer.format_err("These type variables are bound:", .{});
                    var iter = self.ty_env.iterator();
                    while (iter.next()) |entry|
                        try self.monomorphizer.format_err("- {s} = {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
                }
                try self.monomorphizer.format_err("The type variable {s} is unbound.\n", .{name});
                return error.CompileError;
            }
        }

        var env_iter = self.ty_env.iterator();
        while (env_iter.next()) |constraint| {
            const to = constraint.value_ptr.*;
            try self.monomorphizer.compile_type(to);
        }

        return self.ty_env;
    }
};

const FunMonomorphizer = struct {
    monomorphizer: *Monomorphizer,
    alloc: std.mem.Allocator,
    fun: *mono.Fun,
    ty_env: TyEnv, // the map from the fun's type parameters to concrete types
    var_env: *VarEnv, // maps local variables to types
    expected_return_ty: Ty, // the return type explicitly given in the code
    return_ty: ?Ty, // the inferred return type

    // When lowering loops, breaks don't know where to jump to yet. Instead,
    // they fill this structure.
    breakable_scopes: ArrayList(BreakableScope), // used like a stack
    continuable_scopes: ArrayList(ContinuableScope), // used like a stack

    const BreakableScope = struct {
        result: ?mono.StatementIndex,
        result_ty: ?Ty,
        breaks: ArrayList(mono.StatementIndex),
    };
    const ContinuableScope = struct { continues: ArrayList(mono.StatementIndex) };

    const Self = @This();

    // Maps variable names to their expression index.
    const VarEnv = StringHashMap(VarInfo);
    // TODO: Type is already available as fun.tys, no need for it here
    const VarInfo = struct { index: usize, ty: Ty };

    fn compile(monomorphizer: *Monomorphizer, fun: ast.Fun, ty_env: TyEnv) !Str {
        const alloc = monomorphizer.alloc;

        var signature = String.init(alloc);
        var ty_args = ArrayList(Ty).init(alloc);
        var arg_tys = ArrayList(Ty).init(alloc);
        var var_env = VarEnv.init(alloc);

        try signature.appendSlice(fun.name);
        if (fun.ty_args.len > 0) {
            try signature.appendSlice("[");
            for (fun.ty_args, 0..) |arg, i| {
                if (i > 0) try signature.appendSlice(", ");
                const arg_ty: Ty = ty_env.get(arg) orelse @panic("required type arg doesn't exist in type env");
                try ty_args.append(arg_ty);
                try format(signature.writer(), "{}", .{arg_ty});
            }
            try signature.appendSlice("]");
        }
        try signature.append('(');
        var args = fun.args.iterator();
        for (0..fun.args.count()) |i| {
            const arg = args.next().?;
            const arg_ty = try arg.value_ptr.specialize(alloc, ty_env);
            if (i > 0) try signature.appendSlice(", ");
            try arg_tys.append(arg_ty);
            try format(signature.writer(), "{}", .{arg_ty});
            try var_env.put(arg.key_ptr.*, .{ .index = i, .ty = arg_ty });
        }
        try signature.append(')');

        if (monomorphizer.funs.contains(signature.items))
            return signature.items;

        try monomorphizer.context.append(signature.items);
        { // Printing
            var s = String.init(alloc);
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

        const return_ty = try fun.returns.specialize(alloc, ty_env);
        try monomorphizer.compile_type(return_ty);

        var mono_fun = mono.Fun{
            .ty_args = ty_args.items,
            .arg_tys = arg_tys.items,
            .return_ty = return_ty,
            .is_builtin = fun.is_builtin,
            .body = ArrayList(mono.Statement).init(alloc),
            .tys = ArrayList(Ty).init(alloc),
        };
        for (arg_tys.items) |ty| _ = try mono_fun.put(.{ .arg = {} }, ty);
        try monomorphizer.funs.put(signature.items, mono_fun);

        var fun_monomorphizer = Self{
            .monomorphizer = monomorphizer,
            .alloc = alloc,
            .fun = &mono_fun,
            .ty_env = ty_env,
            .var_env = &var_env,
            .expected_return_ty = return_ty,
            .return_ty = null,
            .breakable_scopes = ArrayList(BreakableScope).init(alloc),
            .continuable_scopes = ArrayList(ContinuableScope).init(alloc),
        };

        const body_result = try fun_monomorphizer.compile_body(fun.body);

        // For builtin functions, we trust the fully specified return type.
        // For user-written functions, we take the actual return type.
        if (!fun.is_builtin) {
            try fun_monomorphizer.new_returned_ty(body_result.ty);
            if (!string.eql(body_result.ty.name, "Never"))
                _ = try mono_fun.put(.{ .return_ = body_result }, Ty.named("Never"));
            mono_fun.return_ty = fun_monomorphizer.return_ty orelse body_result.ty;
        }

        try monomorphizer.funs.put(signature.items, mono_fun);
        _ = monomorphizer.context.pop();
        { // Printing
            var s = String.init(alloc);
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
        return signature.items;
    }
    fn format_err(self: *Self, comptime fmt: Str, args: anytype) !void {
        try self.monomorphizer.format_err(fmt, args);
    }

    fn new_returned_ty(self: *Self, returned: Ty) !void {
        if (string.eql(returned.name, "Never")) return;

        // TODO: Allow placeholders in types
        if (!returned.eql(self.expected_return_ty)) {
            try self.format_err(
                "This function should return {s}, but it returns {s}.\n",
                .{ self.expected_return_ty, returned },
            );
            return error.CompileError;
        }

        if (self.return_ty) |expected_ty| if (!returned.eql(expected_ty)) {
            try self.format_err(
                "This function returns {s} in a previous return, but {s} at some place.\n",
                .{ expected_ty, returned },
            );
            return error.CompileError;
        };

        self.return_ty = returned;
    }

    fn compile_expr(self: *Self, expression: ast.Expr) error{ Todo, OutOfMemory, CompileError, WrongNumberOfGenerics }!mono.Expr {
        // TODO: special-case these in the parser instead
        if (try self.compile_break(expression)) |expr| return expr;
        if (try self.compile_continue(expression)) |expr| return expr;

        switch (expression) {
            .int => |int| return try self.fun.put_and_get_expr(
                .{ .int = .{ .value = int.value, .signedness = int.signedness, .bits = int.bits } },
                try numbers.int_ty(self.alloc, .{ .signedness = int.signedness, .bits = int.bits }),
            ),
            .string => |str| {
                const u8_ty: Ty = Ty.named("U8");

                var slice_ty_args = ArrayList(Ty).init(self.alloc);
                try slice_ty_args.append(u8_ty);
                const slice_ty: Ty = .{ .name = "Slice", .args = slice_ty_args.items };

                _ = try self.monomorphizer.compile_type(u8_ty);
                _ = try self.monomorphizer.compile_type(slice_ty);

                return try self.fun.put_and_get_expr(.{ .string = str }, slice_ty);
            },
            .name => |name| {
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
                var ty_args: ?[]const Ty = null;
                var args = ArrayList(mono.Expr).init(self.alloc);

                switch (callee) {
                    .ty_arged => |ta| {
                        callee = ta.arged.*;
                        var ty_args_ = ArrayList(Ty).init(self.alloc);
                        for (ta.ty_args) |ta_| {
                            const ty = try ta_.specialize(self.alloc, self.ty_env);
                            try self.monomorphizer.compile_type(ty);
                            try ty_args_.append(ty);
                        }
                        ty_args = ty_args_.items;
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
                        .name => |name| break :find_name name,
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
                for (call.args) |arg| try args.append(try self.compile_expr(arg));

                var ty_args_: ?[]const Ty = null;
                if (ty_args) |ta| ty_args_ = ta;
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
                    if (!string.eql(m.name, "*") and string.eql(of.ty.name, "&")) {
                        const dereference = try self.alloc.create(mono.Expr);
                        dereference.* = .{
                            .ty = of.ty.args[0], // trim the leading &
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
                    for (struct_.fields) |field|
                        if (string.eql(field.name, m.name))
                            break :field_ty field.ty;
                    try self.format_err("\"{s}\" is not a field on {s}.\n", .{ m.name, of.ty });
                    try self.format_err("It only contains these fields:\n", .{});
                    for (struct_.fields) |field|
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
                if (!value.ty.eql(to.ty)) {
                    try self.format_err("Tried to assign {s} to a variable of type {s}.\n", .{ value.ty, to.ty });
                    return error.CompileError;
                }
                return try self.fun.put_and_get_expr(.{ .assign = .{ .to = to, .value = value } }, Ty.named("Nothing"));
            },
            .struct_creation => |sc| {
                const struct_ = switch (try self.monomorphizer.lookup_ty(sc.ty.name)) {
                    .struct_ => |s| s,
                    else => {
                        try self.format_err("Tried to create a struct, but {s} is not a struct type.", .{sc.ty.name});
                        return error.CompileError;
                    },
                };

                var fields = StringHashMap(mono.Expr).init(self.alloc);
                for (sc.fields) |f|
                    try fields.put(f.name, try self.compile_expr(f.value));

                var solver = try TySolver.init(self.monomorphizer, struct_.ty_args);
                // TODO: Foo[] { ... } should not be treated like Foo { ... }
                if (sc.ty.args.len > 0) {
                    if (sc.ty.args.len != struct_.ty_args.len) {
                        try self.format_err(
                            "Tried to create struct {s} with {} type arguments, but it needs {}.",
                            .{ struct_.name, sc.ty.args.len, struct_.ty_args.len },
                        );
                        return error.CompileError;
                    }
                    var ty_env = StringHashMap(Ty).init(self.alloc);
                    var iter = self.ty_env.iterator();
                    while (iter.next()) |entry|
                        try ty_env.put(entry.key_ptr.*, entry.value_ptr.*);
                    for (struct_.ty_args, sc.ty.args) |param, arg| {
                        const param_ = Ty.named(param);
                        if (!try solver.unify(param_, try arg.specialize(self.alloc, ty_env))) unreachable;
                    }
                }
                var iter = fields.iterator();
                while (iter.next()) |entry| {
                    const name = entry.key_ptr.*;
                    const struct_field_ty = struct_.fields.get(name) orelse {
                        try self.format_err("Tried to init field {s} of {s}, but it doesn't have that.\n", .{ name, struct_.name });
                        return error.CompileError;
                    };
                    const field_ty = entry.value_ptr.*.ty;
                    if (!try solver.unify(struct_field_ty, field_ty)) {
                        try self.format_err(
                            "Tried to assign {s} to field \"{s}\" of type {s}.\n",
                            .{ field_ty, name, struct_field_ty },
                        );
                        return error.CompileError;
                    }
                }
                const ty_env = try solver.finish("When creating struct {s}:", .{sc.ty.name});

                var unspecialized_ty = sc.ty;
                if (sc.ty.args.len == 0 and struct_.ty_args.len > 0) {
                    var args = ArrayList(Ty).init(self.alloc);
                    for (struct_.ty_args) |arg|
                        try args.append(Ty.named(arg));
                    unspecialized_ty.args = args.items;
                }
                const struct_ty = try unspecialized_ty.specialize(self.alloc, ty_env);
                try self.monomorphizer.compile_type(struct_ty);

                return try self.fun.put_and_get_expr(.{ .struct_creation = .{
                    .struct_ty = struct_ty,
                    .fields = fields,
                } }, struct_ty);
            },
            .enum_creation => |ec| {
                const enum_ = switch (try self.monomorphizer.lookup_ty(ec.ty.name)) {
                    .enum_ => |s| s,
                    else => {
                        try self.format_err("Tried to create an enum, but {s} is not an enum type.\n", .{ec.ty.name});
                        return error.CompileError;
                    },
                };
                const arg_ = try self.alloc.create(mono.Expr);
                arg_.* = try if (ec.arg) |arg| self.compile_expr(arg.*) else self.compile_nothing_instance();

                const variant_ty = find_variant: {
                    var iter = enum_.variants.iterator();
                    while (iter.next()) |variant|
                        if (string.eql(variant.key_ptr.*, ec.variant))
                            break :find_variant variant.value_ptr.*;
                    try self.format_err("Unknown variant {s}.{s}.\n", .{ ec.ty.name, ec.variant });
                    return error.CompileError;
                };

                var solver = try TySolver.init(self.monomorphizer, enum_.ty_args);
                // TODO: Maybe[].some(3) should not be treated like Maybe.some(3)
                if (ec.ty.args.len > 0) {
                    if (ec.ty.args.len != enum_.ty_args.len) {
                        try self.format_err(
                            "Tried to create enum {s} with {} type arguments, but it needs {}.\n",
                            .{ enum_.name, ec.ty.args.len, enum_.ty_args.len },
                        );
                        return error.CompileError;
                    }
                    for (enum_.ty_args, ec.ty.args) |param, arg| {
                        const param_ = Ty.named(param);
                        if (!try solver.unify(param_, try arg.specialize(self.alloc, self.ty_env))) unreachable;
                    }
                }
                if (!try solver.unify(variant_ty, arg_.ty)) {
                    try self.format_err(
                        "Tried to create {s}.{s} with {s}, but it needs a {s}.\n",
                        .{ ec.ty.name, ec.variant, arg_.ty, variant_ty },
                    );
                    return error.CompileError;
                }
                const ty_env = try solver.finish("When creating enum {s}:\n", .{ec.ty.name});

                var unspecialized_ty = ec.ty;
                if (ec.ty.args.len == 0 and enum_.ty_args.len > 0) {
                    var args = ArrayList(Ty).init(self.alloc);
                    for (enum_.ty_args) |arg|
                        try args.append(Ty.named(arg));
                    unspecialized_ty.args = args.items;
                }
                const enum_ty = try unspecialized_ty.specialize(self.alloc, ty_env);
                try self.monomorphizer.compile_type(enum_ty);

                return try self.fun.put_and_get_expr(.{ .variant_creation = .{
                    .enum_ty = enum_ty,
                    .variant = ec.variant,
                    .value = arg_,
                } }, enum_ty);
            },
            .switch_ => |switch_| {
                const result = try self.fun.put(.{ .uninitialized = {} }, Ty.named("Something")); // Type will be replaced later
                var result_ty: ?Ty = null;

                const value = try self.compile_expr(switch_.value.*);
                const enum_def = switch (self.monomorphizer.ty_defs.get(value.ty).?) {
                    .enum_ => |e| e,
                    else => {
                        try self.format_err("You tried to switch on {s}, but you can only switch on enums.\n", .{value.ty});
                        return error.CompileError;
                    },
                };

                // Ensure all cases refer to enum variants and all variants are
                // handled exactly once.
                var handled = StringHashMap(void).init(self.alloc);
                cases: for (switch_.cases) |case| {
                    if (handled.contains(case.variant)) {
                        try self.format_err("When switching on {s}, you handle the \"{s}\" variant multiple times.\n", .{ value.ty, case.variant });
                        return error.CompileError;
                    }
                    for (enum_def.variants) |variant|
                        if (string.eql(variant.name, case.variant)) {
                            try handled.put(case.variant, {});
                            continue :cases;
                        };
                    try self.format_err("You switched on {s}, which doesn't have a \"{s}\" variant.\n", .{ value.ty, case.variant });
                    try self.format_err("It only has these variants:\n", .{});
                    for (enum_def.variants) |variant|
                        try self.format_err("- {s}\n", .{variant.name});
                    return error.CompileError;
                }
                if (switch_.default == null)
                    for (enum_def.variants) |variant|
                        if (!handled.contains(variant.name)) {
                            try self.format_err("You switched on {s}, but you don't handle the \"{s}\" variant.\n", .{ value.ty, variant.name });
                            return error.CompileError;
                        };

                // Jump table
                const jump_table_start = self.fun.next_index();
                for (switch_.cases) |_|
                    _ = try self.fun.put(.{ .uninitialized = {} }, Ty.named("Nothing")); // Will be replaced with jump_if_variant
                var after_switch_jumps = ArrayList(mono.StatementIndex).init(self.alloc);

                // Default case
                if (switch_.default) |default| {
                    const default_result = try self.compile_expr(default.*);
                    if (!default_result.ty.eql(Ty.named("Never"))) {
                        result_ty = default_result.ty;
                        _ = try self.fun.put(.{ .assign = .{
                            .to = .{ .ty = self.fun.tys.items[result], .kind = .{ .statement = result } },
                            .value = default_result,
                        } }, Ty.named("Nothing"));
                    }
                    try after_switch_jumps.append(try self.fun.put(.{ .uninitialized = {} }, Ty.named("Never"))); // will be replaced with jump to after switch
                }

                // Case bodies
                for (switch_.cases, 0..) |case, i| {
                    self.fun.body.items[jump_table_start + i] = .{ .jump_if_variant = .{
                        .condition = value,
                        .variant = case.variant,
                        .target = self.fun.next_index(),
                    } };
                    const ty = find_ty: {
                        for (enum_def.variants) |variant|
                            if (string.eql(variant.name, case.variant))
                                break :find_ty variant.ty;
                        unreachable;
                    };
                    const unpacked = try self.fun.put(.{ .get_enum_value = .{ .of = value, .variant = case.variant, .ty = ty } }, ty);
                    // TODO: Create inner var env
                    // const inner_self.var_env = self.var_env.clone();
                    if (case.binding) |binding|
                        try self.var_env.put(binding, .{ .index = unpacked, .ty = ty });

                    const then_result = try self.compile_expr(case.then.*);
                    if (!then_result.ty.eql(Ty.named("Never"))) {
                        if (result_ty) |expected_ty| {
                            if (!expected_ty.eql(then_result.ty)) {
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
                        } }, Ty.named("Nothing"));
                    }
                    try after_switch_jumps.append(try self.fun.put(.{ .uninitialized = {} }, Ty.named("Never"))); // will be replaced with jump to after switch
                }
                const after_switch = self.fun.next_index();
                for (after_switch_jumps.items) |jump|
                    self.fun.body.items[jump] = .{ .jump = .{ .target = after_switch } };

                const final_ty = result_ty orelse Ty.named("Never");
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
                if (!string.eql(primary.ty.name, "Maybe")) {
                    try self.format_err("The left side of an orelse has to be a Maybe, but it was {s}.\n", .{primary.ty});
                    return error.CompileError;
                }
                const primary_ty = primary.ty.args[0];

                const result = try self.fun.put(.{ .uninitialized = {} }, Ty.named("Something")); // Type will be replaced later
                var result_ty: ?Ty = null;

                const jump_if_none = try self.fun.put(.{
                    .jump_if_variant = .{ .condition = primary, .variant = "none", .target = 0 },
                }, Ty.named("Nothing")); // target be replaced with jump_if
                const unwrapped = try self.fun.put(.{ .get_enum_value = .{ .of = primary, .variant = "some", .ty = primary_ty } }, Ty.named("Nothing"));
                if (!primary_ty.eql(Ty.named("Never"))) {
                    _ = try self.fun.put(.{ .assign = .{
                        .to = .{ .ty = Ty.named("Nothing"), .kind = .{ .statement = result } },
                        .value = .{ .ty = primary_ty, .kind = .{ .statement = unwrapped } },
                    } }, Ty.named("Nothing"));
                    result_ty = primary_ty;
                }
                const jump_if_some = try self.fun.put(.{ .jump = .{ .target = 0 } }, Ty.named("Never")); // target will be replaced

                // TODO: Create inner var env
                const alternative_target = self.fun.next_index();
                const alternative = try self.compile_expr(orelse_.alternative.*);
                if (!string.eql(alternative.ty.name, "Never")) {
                    if (result_ty) |expected_ty| {
                        if (!expected_ty.eql(alternative.ty)) {
                            try self.format_err("An orelse is inconsistenly typed:\n", .{});
                            try self.format_err("- The primary expression is a Maybe of {s}.\n", .{expected_ty});
                            try self.format_err("- The alternative is a {s}.\n", .{alternative.ty});
                            return error.CompileError;
                        }
                    } else result_ty = alternative.ty;

                    _ = try self.fun.put(.{ .assign = .{
                        .to = .{ .ty = result_ty.?, .kind = .{ .statement = result } },
                        .value = alternative,
                    } }, Ty.named("Nothing"));
                }

                const after_orelse = self.fun.next_index();

                self.fun.body.items[jump_if_none].jump_if_variant.target = alternative_target;
                self.fun.body.items[jump_if_some].jump.target = after_orelse;

                const final_ty = result_ty orelse Ty.named("Never");
                self.fun.tys.items[result] = final_ty;
                return .{ .kind = .{ .statement = result }, .ty = final_ty };
            },
            .loop => |expr| {
                const result = try self.fun.put(.{ .uninitialized = {} }, Ty.named("Something")); // type will be replaced
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
                _ = try self.fun.put(.{ .jump = .{ .target = loop_start } }, Ty.named("Never"));

                const after_loop = self.fun.next_index();
                {
                    const scope = self.breakable_scopes.pop();
                    self.fun.tys.items[result] = scope.result_ty orelse Ty.named("Never");
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
                try self.continuable_scopes.append(.{
                    .continues = ArrayList(mono.StatementIndex).init(self.alloc),
                });

                const iterable = try self.compile_expr(for_.iter.*);
                const owned_iter = try self.compile_call("iter", iterable, null, &[_]mono.Expr{});
                var args = ArrayList(Ty).init(self.alloc);
                try args.append(owned_iter.ty);
                const ref_ty: Ty = .{ .name = "&", .args = args.items };
                try self.monomorphizer.compile_type(ref_ty);
                const iter = try self.fun.put_and_get_expr(.{ .ref = owned_iter }, ref_ty);

                const loop_start = self.fun.next_index();

                const result_of_next = try self.compile_call("next", iter, null, &[_]mono.Expr{});
                if (!string.eql(result_of_next.ty.name, "Maybe")) {
                    try self.format_err("The iterator's next function returns {s}, not Maybe.\n", .{result_of_next.ty});
                    return error.CompileError;
                }
                const unpacked_ty = result_of_next.ty.args[0];

                // Will be replaced with a jump_if_variant none
                const jump_out = try self.fun.put(.{ .uninitialized = {} }, Ty.named("Never"));

                const unpacked = try self.fun.put(.{ .get_enum_value = .{
                    .of = result_of_next,
                    .variant = "some",
                    .ty = unpacked_ty,
                } }, unpacked_ty);
                // TODO: Create inner var env
                // const inner_self.var_env = self.var_env.clone();
                try self.var_env.put(for_.iter_var, .{ .index = unpacked, .ty = unpacked_ty });

                _ = try self.compile_expr(for_.expr.*);
                _ = try self.fun.put(.{ .jump = .{ .target = loop_start } }, Ty.named("Never"));

                const after_loop = self.fun.next_index();
                self.fun.body.items[jump_out] = .{ .jump_if_variant = .{
                    .condition = result_of_next,
                    .variant = "none",
                    .target = after_loop,
                } };
                {
                    const scope = self.breakable_scopes.pop();
                    for (scope.breaks.items) |b|
                        self.fun.body.items[b] = .{ .jump = .{ .target = after_loop } };
                }
                {
                    const scope = self.continuable_scopes.pop();
                    for (scope.continues.items) |b| self.fun.body.items[b] = .{ .jump = .{ .target = loop_start } };
                }
                return self.compile_nothing_instance();
            },
            .return_ => |returned| {
                const compiled_arg = try self.compile_expr(returned.*);
                try self.new_returned_ty(compiled_arg.ty);
                return try self.fun.put_and_get_expr(.{ .return_ = compiled_arg }, Ty.named("Never"));
            },
            .ampersanded => |expr| {
                const amped = try self.compile_expr(expr.*);

                var args = ArrayList(Ty).init(self.alloc);
                try args.append(amped.ty);
                const ref_ty: Ty = .{ .name = "&", .args = args.items };
                try self.monomorphizer.compile_type(ref_ty);

                return try self.fun.put_and_get_expr(.{ .ref = amped }, ref_ty);
            },
            .try_ => |expr| {
                const tried = try self.compile_expr(expr.*);
                if (!string.eql(tried.ty.name, "Result")) {
                    try self.format_err("The try operator ? can only be used on Results.\n", .{});
                    return error.CompileError;
                }

                const return_ty = self.expected_return_ty;
                if (!string.eql(return_ty.name, "Result")) {
                    try self.format_err("The try operator ? can only be used in functions that return Result.\n", .{});
                    return error.CompileError;
                }

                // TODO: Ensure the error variants are equal.
                // if (tried_ty.args[1] != return_ty.args[1]) return CompileError;

                const ok_payload_ty = tried.ty.args[0];
                const error_payload_ty = tried.ty.args[1];

                const jump_if_ok = try self.fun.put(.{ .jump_if_variant = .{
                    .condition = tried,
                    .variant = "ok",
                    .target = 0,
                } }, Ty.named("Nothing"));

                const error_payload = try self.alloc.create(mono.Expr);
                error_payload.* = try self.fun.put_and_get_expr(.{ .get_enum_value = .{
                    .of = tried,
                    .variant = "error",
                    .ty = error_payload_ty,
                } }, error_payload_ty);
                const error_to_return = try self.fun.put_and_get_expr(.{ .variant_creation = .{
                    .enum_ty = self.expected_return_ty,
                    .variant = "error",
                    .value = error_payload,
                } }, self.expected_return_ty);
                _ = try self.fun.put(.{ .return_ = error_to_return }, Ty.named("Never"));

                const after_error_handling = self.fun.next_index();
                self.fun.body.items[jump_if_ok].jump_if_variant.target = after_error_handling;

                return try self.fun.put_and_get_expr(.{ .get_enum_value = .{
                    .of = tried,
                    .variant = "ok",
                    .ty = ok_payload_ty,
                } }, ok_payload_ty);
            },
            .body => |body| return try self.compile_body(body),
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
            .struct_ty = Ty.named("Nothing"),
            .fields = StringHashMap(mono.Expr).init(self.alloc),
        } }, Ty.named("Nothing"));
    }

    fn compile_call(self: *Self, name: Str, callee: ?mono.Expr, ty_args: ?[]const Ty, args: []const mono.Expr) !mono.Expr {
        var full_args = ArrayList(mono.Expr).init(self.alloc);
        if (callee) |c| try full_args.append(c);
        try full_args.appendSlice(args);

        var arg_tys = ArrayList(Ty).init(self.alloc);
        for (full_args.items) |arg| try arg_tys.append(arg.ty);

        // Because of auto-deref, we have to try looking for matching funs in a
        // loop. For example, if you call value.foo() on a value of type &T, we
        // first look for functions matching foo(&T). If none match, we try
        // dereferencing the value and looking for functions matching foo(T). If
        // we find one, the resulting expression is basically the same as
        // value.*.foo().
        var first_error: ?String = null;
        var called_fun: ?ast.Fun = null;
        var call_ty_env: ?TyEnv = null;
        while (true) {
            const lookup_solution = self.monomorphizer.lookup_fun(name, ty_args, arg_tys.items) catch |err| {
                if (err != error.CompileError) return err;
                if (first_error == null) first_error = self.monomorphizer.err;
                self.monomorphizer.err = String.init(self.alloc);

                if (callee != null and string.eql(arg_tys.items[0].name, "&")) {
                    // There is a callee and it's a reference. Dereference it.
                    const derefed_callee = try self.alloc.create(mono.Expr);
                    derefed_callee.* = full_args.items[0];
                    const deref_ty = arg_tys.items[0].args[0]; // trim &
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

            called_fun = lookup_solution.fun;
            call_ty_env = lookup_solution.ty_env;
            break;
        }

        // TODO: Make sure all type args are different.

        const fun_name = try FunMonomorphizer.compile(self.monomorphizer, called_fun.?, call_ty_env.?);
        const return_ty = try called_fun.?.returns.specialize(self.alloc, call_ty_env.?);
        try self.monomorphizer.compile_type(return_ty);

        return try self.fun.put_and_get_expr(.{ .call = .{ .fun = fun_name, .args = full_args.items } }, return_ty);
    }

    // Some calls and some names may be breaks. For example, `break(5)` and `break` both break.
    fn compile_break(self: *Self, expr: ast.Expr) !?mono.Expr {
        const arg: ?ast.Expr = break_arg: {
            switch (expr) {
                .name => |name| if (string.eql(name, "break"))
                    break :break_arg null
                else
                    return null,
                .call => |call| switch (call.callee.*) {
                    .name => |name| if (string.eql(name, "break")) {
                        if (call.args.len == 0) break :break_arg null;
                        if (call.args.len == 1) break :break_arg call.args[0];
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
            if (scope.result_ty) |expected_ty| if (!arg_ty.eql(expected_ty)) {
                try self.format_err("A previous break returned {s}, but this break returns {s}.\n", .{ expected_ty, arg_ty });
                return error.CompileError;
            };

            scope.result_ty = arg_ty;

            _ = try self.fun.put(.{ .assign = .{
                .to = .{ .ty = arg_ty, .kind = .{ .statement = result } },
                .value = compiled_arg,
            } }, Ty.named("Nothing"));
        } else if (arg) |_| {
            try self.format_err("Breaks in for can't take an argument.\n", .{});
            return error.CompileError;
        }

        const jump = try self.fun.put(.{ .uninitialized = {} }, Ty.named("Never")); // will be replaced by jump to after loop
        try scope.breaks.append(jump);
        return .{ .kind = .{ .statement = jump }, .ty = Ty.named("Never") };
    }

    // Some names may be continues.
    fn compile_continue(self: *Self, expr: ast.Expr) !?mono.Expr {
        switch (expr) {
            .name => |name| if (!string.eql(name, "continue")) return null,
            else => return null,
        }

        if (self.continuable_scopes.items.len == 0) {
            try self.format_err("continue outside of a loop", .{});
            return error.CompileError;
        }
        var scope = &self.continuable_scopes.items[self.continuable_scopes.items.len - 1];

        const jump = try self.fun.put(.{ .uninitialized = {} }, Ty.named("Never")); // will be replaced by jump to loop start
        try scope.continues.append(jump);
        return .{ .kind = .{ .statement = jump }, .ty = Ty.named("Never") };
    }
};
