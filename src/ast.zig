const std = @import("std");
const ArrayList = std.ArrayList;

pub const Program = struct {
    declarations: ArrayList(Declaration),
};
pub const Declaration = union(enum) {
    builtin_type: BuiltinType,
    struct_: Struct,
    enum_: Enum,
    fun: Fun,
};

pub const Name = []u8;

pub const BuiltinType = struct {
    name: Name,
};

pub const Type = struct {
    name: Name,
    args: ArrayList(Type),
};

pub const Struct = struct {
    name: Name,
    type_args: ArrayList(Type),
    fields: ArrayList(Field),
};
pub const Field = struct {
    name: Name,
    type_: Type,
};

pub const Enum = struct {
    name: Name,
    type_args: ArrayList(Type),
    variants: ArrayList(Variant),
};
pub const Variant = struct {
    name: Name,
    type_: ?Type,
};

pub const Fun = struct {
    name: Name,
    type_args: ArrayList(Type),
    args: ArrayList(Argument),
    return_type: ?Type,
    body: Body,
};
pub const Argument = struct {
    name: Name,
    type_: Type,
};
pub const Body = ArrayList(Expression);
pub const Expression = union(enum) {
    reference: Name,
    call: Call,
    var_: Var,
    if_: If,
};
pub const Call = struct {
    callee: *Expression,
    args: ArrayList(Expression),
};
pub const Var = struct {
    name: Name,
    type_: ?Type,
    value: *Expression,
};
pub const If = struct {
    condition: *Expression,
    then: Body,
    else_: Body,
};

pub fn print(program: Program) void {
    const decls = program.declarations.items;
    for (decls) |decl| {
        print_declaration(decl);
        std.debug.print("\n", .{});
    }
}
fn print_declaration(declaration: Declaration) void {
    switch (declaration) {
        .builtin_type => |bt| print_builtin_type(bt),
        .struct_ => |s| print_struct(s),
        .enum_ => |e| print_enum(e),
        .fun => |fun| print_fun(fun),
    }
}
fn print_builtin_type(bt: BuiltinType) void {
    std.debug.print("builtinType {s}", .{bt.name});
}
fn print_type(type_: Type) void {
    std.debug.print("{s}", .{type_.name});
    const args = type_.args.items;
    if (args.len > 0) {
        std.debug.print("[", .{});
        for (args, 0..) |arg, i| {
            print_type(arg);
            if (i < args.len - 1) {
                std.debug.print(", ", .{});
            }
        }
        std.debug.print("]", .{});
    }
}
fn print_struct(s: Struct) void {
    const fields = s.fields.items;
    if (fields.len == 0) {
        std.debug.print("struct {s} {{}}", .{s.name});
    } else {
        std.debug.print("struct {s} {{\n", .{s.name});
        for (fields) |field| {
            std.debug.print("  {s}: ", .{field.name});
            print_type(field.type_);
            std.debug.print(",\n", .{});
        }
        std.debug.print("}}", .{});
    }
}
fn print_enum(e: Enum) void {
    const variants = e.variants.items;
    if (variants.len == 0) {
        std.debug.print("enum {s} {{}}", .{e.name});
    } else {
        std.debug.print("enum {s} {{\n", .{e.name});
        for (variants) |variant| {
            std.debug.print("  {s}", .{variant.name});
            if (variant.type_) |t| {
                std.debug.print(": ", .{});
                print_type(t);
            }
            std.debug.print(",\n", .{});
        }
        std.debug.print("}}", .{});
    }
}
pub fn print_fun(fun: Fun) void {
    std.debug.print("fun {s}", .{fun.name});

    const type_args = fun.type_args.items;
    if (type_args.len > 0) {
        std.debug.print("[", .{});
        for (type_args, 0..) |arg, i| {
            print_type(arg);
            if (i < type_args.len - 1) {
                std.debug.print(", ", .{});
            }
        }
        std.debug.print("]", .{});
    }

    const args = fun.args.items;
    std.debug.print("(", .{});
    for (args, 0..) |arg, i| {
        print_argument(arg);
        if (i < args.len - 1) {
            std.debug.print(", ", .{});
        }
    }
    std.debug.print(")", .{});

    if (fun.return_type) |ty| {
        std.debug.print(": ", .{});
        print_type(ty);
    }

    std.debug.print(" {{ ... }}", .{});
}
fn print_argument(arg: Argument) void {
    std.debug.print("{s}: ", .{arg.name});
    print_type(arg.type_);
}
