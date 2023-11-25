const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const Name = @import("ast.zig").Name;

pub const Mono = struct {
    types: StringHashMap(Type),
    funs: StringHashMap(Fun),
};

pub const Type = union(enum) {
    builtin_type,
    struct_: Struct,
    enum_: Enum,
    fun,
};

pub const Struct = struct {
    fields: ArrayList(Field),
};
pub const Field = struct {
    name: Name,
    type_: Name,
};

pub const Enum = struct {
    variants: ArrayList(Variant),
};
pub const Variant = struct {
    name: Name,
    type_: Name,
};

pub const Funs = struct {
    funs: StringHashMap(Fun),
};

pub const Fun = struct {
    arg_types: ArrayList(Name),
    return_type: Name,
    is_builtin: bool,
    expressions: ArrayList(Expression),
    types: ArrayList(Name),

    const Self = @This();

    pub fn put(self: *Self, expr: Expression, ty: Name) !void {
        try self.expressions.append(expr);
        try self.types.append(ty);
    }
};
pub const ExpressionIndex = usize;
pub const Expression = union(enum) {
    arg,
    number: i128,
    assign: Assign,
    call: Call,
    member: Member,
    struct_construction: StructConstruction,
    return_: ExpressionIndex,
};
pub const Assign = struct {
    to: ExpressionIndex,
    value: ExpressionIndex,
};
pub const Call = struct {
    fun: Name, // monomorphized function name
    args: ArrayList(ExpressionIndex),
};
pub const Member = struct {
    callee: ExpressionIndex,
    member: Name,
};
pub const StructConstruction = struct {
    struct_type: Name,
    fields: StringHashMap(ExpressionIndex),
};

pub fn print(mono: Mono) void {
    {
        std.debug.print("Types:\n", .{});
        var iter = mono.types.keyIterator();
        while (iter.next()) |ty| {
            std.debug.print("- {s}\n", .{ty.*});
        }
    }
    {
        std.debug.print("Funs:\n", .{});
        var iter = mono.funs.iterator();
        while (iter.next()) |fun| {
            print_fun(fun.key_ptr.*, fun.value_ptr.*);
            std.debug.print("\n", .{});
        }
    }
}

fn print_fun(name: Name, fun: Fun) void {
    std.debug.print("{s}\n", .{name});
    for (fun.expressions.items, fun.types.items, 0..) |expr, ty, i| {
        if (i > 0) {
            std.debug.print("\n", .{});
        }
        std.debug.print("  _{d} = ", .{i});
        print_expression(expr);
        std.debug.print(": {s}", .{ty});
    }
}

fn print_expression(expr: Expression) void {
    switch (expr) {
        .arg => std.debug.print("arg", .{}),
        .number => |n| std.debug.print("{d}", .{n}),
        .assign => |assign| {
            std.debug.print("{} set to {}", .{assign.to, assign.value});
        },
        .call => |call| {
            std.debug.print("{s} called with (", .{call.fun});
            for (call.args.items, 0..) |arg, i| {
                if (i > 0) {
                    std.debug.print(", ", .{});
                }
                std.debug.print("_{d}", .{arg});
            }
            std.debug.print(")", .{});
        },
        .struct_construction => |sc| {
            std.debug.print("{s}.{{", .{sc.struct_type});
            var iter = sc.fields.iterator();
            while (iter.next()) |field| {
                std.debug.print("  {s} = _{},", .{field.key_ptr.*, field.value_ptr.*});
            }
            std.debug.print("}}", .{});
        },
        .member => |m| std.debug.print("_{d}.{s}", .{m.callee, m.member}),
        .return_ => |r| std.debug.print("return _{d}", .{r}),
    }
}
