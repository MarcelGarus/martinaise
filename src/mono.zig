const std = @import("std");
const ArrayList = std.ArrayList; // TODO: Use slices everywhere instead
const StringArrayHashMap = std.StringArrayHashMap;
const StringHashMap = std.StringHashMap;
const Str = @import("string.zig").Str;
const Ty = @import("ty.zig").Ty;
const numbers = @import("numbers.zig");

pub const Mono = struct {
    ty_defs: StringArrayHashMap(TyDef),
    funs: StringHashMap(Fun),
};

pub const TyDef = union(enum) {
    builtin_ty,
    struct_: Struct,
    enum_: Enum,
    fun,
};

pub const Struct = struct { fields: ArrayList(Field) };
pub const Field = struct { name: Str, ty: Str };

pub const Enum = struct { variants: ArrayList(Variant) };
pub const Variant = struct { name: Str, ty: Str };

pub const Fun = struct {
    ty_args: ArrayList(Str),
    arg_tys: ArrayList(Str),
    return_ty: Str,
    is_builtin: bool,
    body: ArrayList(Statement),
    tys: ArrayList(Str),

    const Self = @This();

    pub fn next_index(self: Self) StatementIndex {
        return self.body.items.len;
    }
    pub fn put(self: *Self, statement: Statement, ty: Str) !StatementIndex {
        const index = self.body.items.len;
        try self.body.append(statement);
        try self.tys.append(ty);
        return index;
    }
    pub fn put_and_get_expr(self: *Self, statement: Statement, ty: Str) !Expr {
        return .{ .kind = .{ .statement = try self.put(statement, ty) }, .ty = ty };
    }
};

pub const StatementIndex = usize;
pub const Statement = union(enum) {
    arg,
    expression: Expr,
    uninitialized,
    assign: Assign,
    int: Int,
    string: Str,
    call: Call,
    variant_creation: VariantCreation,
    struct_creation: StructCreation,
    jump: Jump,
    jump_if_variant: JumpIfVariant,
    get_enum_value: GetEnumValue,
    return_: Expr,
    ref: Expr,
};
pub const Assign = struct { to: Expr, value: Expr };
pub const Int = struct { value: i128, signedness: numbers.Signedness, bits: numbers.Bits };
pub const Call = struct { fun: Str, args: ArrayList(Expr) };
pub const VariantCreation = struct { enum_ty: Str, variant: Str, value: *const Expr };
pub const StructCreation = struct { struct_ty: Str, fields: StringHashMap(Expr) };
pub const Jump = struct { target: StatementIndex };
pub const JumpIfVariant = struct { condition: Expr, variant: Str, target: StatementIndex };
pub const GetEnumValue = struct { of: Expr, variant: Str, ty: Str };

pub const Expr = struct {
    ty: Str,
    kind: ExprKind,
};
pub const ExprKind = union(enum) {
    statement: StatementIndex,
    member: Member,
};
pub const Member = struct { of: *const Expr, name: Str };

pub fn print(writer: anytype, mono: Mono) !void {
    {
        try writer.print("Types:\n", .{});
        for (mono.ty_defs.keys()) |ty| {
            try writer.print("- {s}\n", .{ty});
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

fn print_fun(writer: anytype, name: Str, fun: Fun) !void {
    try writer.print("{s}\n", .{name});
    if (fun.is_builtin) {
        try writer.print("  <builtin>", .{});
        return;
    }
    for (fun.body.items, fun.tys.items, 0..) |statement, ty, i| {
        if (i > 0) {
            try writer.print("\n", .{});
        }
        try writer.print("  _{d} = ", .{i});
        try print_statement(writer, statement);
        try writer.print(": {s}", .{ty});
    }
}
fn print_statement(writer: anytype, statement: Statement) !void {
    switch (statement) {
        .arg => try writer.print("arg", .{}),
        .expression => |e| try print_expr(writer, e),
        .uninitialized => try writer.print("uninitialized", .{}),
        .int => |int| try writer.print("{d}{c}{d}", .{ int.value, int.signedness.to_char(), int.bits }),
        .string => |string| try writer.print("\"{s}\"", .{string}),
        .call => |call| {
            try writer.print("{s} called with (", .{call.fun});
            for (call.args.items, 0..) |arg, i| {
                if (i > 0) {
                    try writer.print(", ", .{});
                }
                try print_expr(writer, arg);
            }
            try writer.print(")", .{});
        },
        .variant_creation => |vc| {
            try writer.print("{s}.{s}(", .{ vc.enum_ty, vc.variant });
            try print_expr(writer, vc.value.*);
            try writer.print(")", .{});
        },
        .struct_creation => |sc| {
            try writer.print("{s}.{{", .{sc.struct_ty});
            var iter = sc.fields.iterator();
            while (iter.next()) |field| {
                try writer.print(" {s} = ", .{field.key_ptr.*});
                try print_expr(writer, field.value_ptr.*);
                try writer.print(",", .{});
            }
            try writer.print(" }}", .{});
        },
        .assign => |assign| {
            try print_expr(writer, assign.to);
            try writer.print(" set to ", .{});
            try print_expr(writer, assign.value);
        },
        .jump => |jump| try writer.print("jump to _{}", .{jump.target}),
        .jump_if_variant => |jump| {
            try writer.print("if ", .{});
            try print_expr(writer, jump.condition);
            try writer.print(" is {s}, jump to _{}", .{ jump.variant, jump.target });
        },
        .get_enum_value => |gev| {
            try writer.print("get {s} value of ", .{gev.variant});
            try print_expr(writer, gev.of);
        },
        .return_ => |r| {
            try writer.print("return ", .{});
            try print_expr(writer, r);
        },
        .ref => |expr| {
            try writer.print("&", .{});
            try print_expr(writer, expr);
        },
    }
}
fn print_expr(writer: anytype, expr: Expr) !void {
    switch (expr.kind) {
        .statement => |s| try writer.print("_{d}", .{s}),
        .member => |m| {
            try print_expr(writer, m.of.*);
            try writer.print(".{s}", .{m.name});
        },
    }
}
