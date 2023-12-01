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
    body: ArrayList(Expr),
    tys: ArrayList(Str),

    const Self = @This();

    pub fn next_index(self: Self) ExprIndex {
        return self.body.items.len;
    }
    pub fn put(self: *Self, expr: Expr, ty: Str) !ExprIndex {
        const index = self.body.items.len;
        try self.body.append(expr);
        try self.tys.append(ty);
        return index;
    }
};
pub const ExprIndex = usize;
pub const Expr = union(enum) {
    arg,
    uninitialized,
    int: Int,
    call: Call,
    variant_creation: VariantCreation,
    struct_creation: StructCreation,
    member: Member,
    assign: Assign,
    jump: Jump,
    jump_if: JumpIf,
    jump_if_variant: JumpIfVariant,
    get_enum_value: GetEnumValue,
    return_: ExprIndex,
    take_ref: ExprIndex,
};
pub const Int = struct { value: i128, signedness: numbers.Signedness, bits: numbers.Bits };
pub const Call = struct { fun: Str, args: ArrayList(ExprIndex) };
pub const VariantCreation = struct { enum_ty: Str, variant: Str, value: ExprIndex };
pub const StructCreation = struct { struct_ty: Str, fields: StringHashMap(ExprIndex) };
pub const Member = struct { of: ExprIndex, name: Str };
pub const Assign = struct { to: LeftExpr, value: ExprIndex };
pub const Jump = struct { target: ExprIndex };
pub const JumpIf = struct { condition: ExprIndex, target: ExprIndex };
pub const JumpIfVariant = struct { condition: ExprIndex, variant: Str, target: ExprIndex };
pub const GetEnumValue = struct { of: ExprIndex, variant: Str, ty: Str };

pub const LeftExpr = struct {
    ty: Str,
    kind: LeftExprKind,
};
pub const LeftExprKind = union(enum) {
    ref: ExprIndex,
    member: LeftMember,
    deref: *const LeftExpr,
};
pub const LeftMember = struct { of: *const LeftExpr, name: Str };

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
        .uninitialized => try writer.print("uninitialized", .{}),
        .int => |int| try writer.print("{d}{c}{d}", .{int.value, int.signedness.to_char(), int.bits}),
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
        .variant_creation => |vc| try writer.print("{s}.{s}(_{})", .{vc.enum_ty, vc.variant, vc.value}),
        .struct_creation => |sc| {
            try writer.print("{s}.{{", .{sc.struct_ty});
            var iter = sc.fields.iterator();
            while (iter.next()) |field| {
                try writer.print(" {s} = _{},", .{field.key_ptr.*, field.value_ptr.*});
            }
            try writer.print(" }}", .{});
        },
        .member => |m| try writer.print("_{d}.{s}", .{m.of, m.name}),
        .assign => |assign| try writer.print("_{} set to _{}", .{assign.to, assign.value}),
        .jump => |jump| try writer.print("jump to _{}", .{jump.target}),
        // TODO: remove in favor of jump_if_variant
        .jump_if => |jump| try writer.print("if _{}, jump to _{}", .{jump.condition, jump.target}),
        .jump_if_variant => |jump| try writer.print("if _{} is {s}, jump to _{}", .{jump.condition, jump.variant, jump.target}),
        .get_enum_value => |gev| try writer.print("get value of _{}", .{gev.of}),
        .return_ => |r| try writer.print("return _{d}", .{r}),
    }
}
