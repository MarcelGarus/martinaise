const std = @import("std");
const ArrayList = std.ArrayList; // TODO: Use slices everywhere instead
const StringHashMap = std.StringHashMap;
const Name = @import("ty.zig").Name;

pub const Mono = struct {
    ty_defs: StringHashMap(TyDef),
    funs: StringHashMap(Fun),
};

pub const TyDef = union(enum) {
    builtin_ty,
    struct_: Struct,
    enum_: Enum,
    fun,
};

pub const Struct = struct { fields: ArrayList(Field) };
pub const Field = struct { name: Name, ty: Name };

pub const Enum = struct { variants: ArrayList(Variant) };
pub const Variant = struct { name: Name, ty: Name };

pub const Fun = struct {
    arg_tys: ArrayList(Name),
    return_ty: Name,
    is_builtin: bool,
    body: ArrayList(Expr),
    tys: ArrayList(Name),

    const Self = @This();

    pub fn put(self: *Self, expr: Expr, ty: Name) !void {
        try self.body.append(expr);
        try self.tys.append(ty);
    }
};
pub const ExprIndex = usize;
pub const Expr = union(enum) {
    arg,
    num: i128,
    call: Call,
    struct_construction: StructConstruction,
    member: Member,
    assign: Assign,
    return_: ExprIndex,
};
pub const Call = struct { fun: Name, args: ArrayList(ExprIndex) };
pub const Assign = struct { to: ExprIndex, value: ExprIndex };
pub const Member = struct { of: ExprIndex, name: Name };
pub const StructConstruction = struct { struct_ty: Name, fields: StringHashMap(ExprIndex) };

pub fn print(writer: anytype, mono: Mono) !void {
    {
        try writer.print("Types:\n", .{});
        var iter = mono.ty_defs.keyIterator();
        while (iter.next()) |ty| {
            try writer.print("- {s}\n", .{ty.*});
        }
    }
    {
        try writer.print("Funs:\n", .{});
        var iter = mono.funs.iterator();
        while (iter.next()) |fun| {
            try print_fun(writer, fun.key_ptr.*, fun.value_ptr.*);
            try writer.print("\n", .{});
        }
    }
}

fn print_fun(writer: anytype, name: Name, fun: Fun) !void {
    try writer.print("{s}\n", .{name});
    for (fun.body.items, fun.tys.items, 0..) |expr, ty, i| {
        if (i > 0) {
            try writer.print("\n", .{});
        }
        try writer.print("  _{d} = ", .{i});
        try print_expr(writer, expr);
        try writer.print(": {s}", .{ty});
    }
}

fn print_expr(writer: anytype, expr: Expr) !void {
    switch (expr) {
        .arg => try writer.print("arg", .{}),
        .num => |n| try writer.print("{d}", .{n}),
        .call => |call| {
            try writer.print("{s} called with (", .{call.fun});
            for (call.args.items, 0..) |arg, i| {
                if (i > 0) {
                    try writer.print(", ", .{});
                }
                try writer.print("_{d}", .{arg});
            }
            try writer.print(")", .{});
        },
        .struct_construction => |sc| {
            try writer.print("{s}.{{", .{sc.struct_ty});
            var iter = sc.fields.iterator();
            while (iter.next()) |field| {
                try writer.print("  {s} = _{},", .{field.key_ptr.*, field.value_ptr.*});
            }
            try writer.print("}}", .{});
        },
        .member => |m| try writer.print("_{d}.{s}", .{m.of, m.name}),
        .assign => |assign| {
            try writer.print("{} set to {}", .{assign.to, assign.value});
        },
        .return_ => |r| try writer.print("return _{d}", .{r}),
    }
}
