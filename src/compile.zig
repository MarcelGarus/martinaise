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

    var monomorphizer = Monomorphizer {
        .alloc = alloc,
        .program = program,
        .types = types,
    };

    const main = try monomorphizer.lookup("main", ArrayList(Name).init(alloc), ArrayList(Name).init(alloc));
    const main_fun = switch (main) {
        .fun => |f| f,
        else => return error.MainIsNotAFunction,
    };

    try monomorphizer.compile_function(main_fun, ArrayList(Name).init(alloc));
}

const Monomorphizer = struct {
    alloc: std.mem.Allocator,
    program: ast.Program,
    types: mono.Types,

    const Self = @This();

    // Maps function or type parameter names to fully monomorphized types.
    const TypeEnv = StringHashMap(Name);

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

    fn compile_function(self: *Self, fun: ast.Fun, type_args: ArrayList(Name)) !void {
        // Make sure all type args are just simple names.
        var fun_type_args = ArrayList(Name).init(self.alloc);
        for (fun.type_args.items) |arg| {
            if (arg.args.items.len > 0) {
                return error.FunctionTypeArgsCannotHaveTypeArgs;
            }
            try fun_type_args.append(arg.name);
        }
        // TODO: Make sure all type arg names are different.

        // Maps types arguments to the concrete types.
        var type_env = TypeEnv.init(self.alloc);
        for (fun_type_args.items, type_args.items) |expected, given| {
            try type_env.putNoClobber(expected, given);
        }
        // Maps variables that are in scope to their concrete types.
        var value_env = TypeEnv.init(self.alloc);
        for (fun.args.items) |arg| {
            try value_env.put(
                arg.name,
                try self.compile_type(arg.type_, type_env)
            );
        }

        var mono_fun = mono.Fun {
            .expressions = ArrayList(mono.Expression).init(self.alloc),
            .types = ArrayList(Name).init(self.alloc),
            .labels = ArrayList(mono.Label).init(self.alloc),
        };
        for (fun.body.items) |expr| {
            _ = try self.compile_expression(&mono_fun, type_env, expr);
        }
    }

    fn compile_expression(
        self: *Self,
        fun: *mono.Fun,
        type_env: TypeEnv,
        expression: ast.Expression
    ) !mono.ExpressionIndex {
        std.debug.print("compiling {any}\n", .{expression});
        switch (expression) {
            .number => |n| try fun.put(.{ .number = n }, "U8"),
            .call => |call| {
                var args = ArrayList(mono.ExpressionIndex).init(self.alloc);
                // Calls of the form `something.name()` cause `something` to be
                // treated like an extra argument.
                switch (call.callee.*) {
                    .member => |member| {
                        try args.append(try self.compile_expression(fun, type_env, member.callee.*));
                    },
                    else => {},
                }
                for (call.args.items) |arg| {
                    try args.append(try self.compile_expression(fun, type_env, arg));
                }

                var arg_types = ArrayList(Name).init(self.alloc);
                for (args.items) |arg| {
                    try arg_types.append(fun.types.items[@intCast(arg)]);
                }

                var type_args: ?ArrayList(Name) = null;
                if (call.type_args) |ty_args| {
                    type_args = try self.compile_types(ty_args, type_env);
                }

                const called_fun = switch (call.callee.*) {
                    .reference => |name| try self.lookup(name, type_args, arg_types),
                    .member => |member| try self.lookup(member.member, type_args, arg_types),
                    else => return error.InvalidExpressionCalled,
                };
                _ = called_fun;

                try fun.put(.{ .call = .{ .fun = "", .args = args } }, "Nothing");
            },
            else => {
                @panic("expression not handled");
            }
        }
        const len: isize = @intCast(fun.expressions.items.len);
        return len - 1;
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
    // `{T: U8}` (resulting in `Maybe[U8]`). Also creates the needed specialized
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
