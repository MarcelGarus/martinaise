const std = @import("std");
const ArrayList = std.ArrayList; // TODO: Use slices everywhere instead
const StringArrayHashMap = std.StringArrayHashMap;
const StringHashMap = std.StringHashMap;
const Str = @import("string.zig").Str;

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
    num: i128,
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
};
pub const Call = struct { fun: Str, args: ArrayList(ExprIndex) };
pub const VariantCreation = struct { enum_ty: Str, variant: Str, value: ExprIndex };
pub const StructCreation = struct { struct_ty: Str, fields: StringHashMap(ExprIndex) };
pub const Member = struct { of: ExprIndex, name: Str };
pub const Assign = struct { to: ExprIndex, value: ExprIndex };
pub const Jump = struct { target: ExprIndex };
pub const JumpIf = struct { condition: ExprIndex, target: ExprIndex };
pub const JumpIfVariant = struct { condition: ExprIndex, variant: Str, target: ExprIndex };
pub const GetEnumValue = struct { of: ExprIndex, variant: Str, ty: Str };

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
        .variant_creation => |vc| {
            try writer.print("{s}.{s}", .{vc.enum_ty, vc.variant});
            try writer.print("(_{})", .{vc.value});
        },
        .struct_creation => |sc| {
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
        .jump => |jump| try writer.print("jump to _{}", .{jump.target}),
        // TODO: remove in favor of jump_if_variant
        .jump_if => |jump| try writer.print("if _{}, jump to _{}", .{jump.condition, jump.target}),
        .jump_if_variant => |jump| try writer.print("if _{} is {s}, jump to _{}", .{jump.condition, jump.variant, jump.target}),
        .get_enum_value => |gev| try writer.print("get value of _{}", .{gev.of}),
        .return_ => |r| try writer.print("return _{d}", .{r}),
    }
}
