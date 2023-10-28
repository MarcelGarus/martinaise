const std = @import("std");
const ArrayList = std.ArrayList;

pub const Program = struct {
    declarations: ArrayList(Declaration),
};
pub const Declaration = union(enum) {
    builtin_type: Name,
    struct_: Struct,
    enum_: Enum,
    fun: Fun,
};

pub const Name = []u8;

pub const Type = struct {
    name: Name,
    arguments: ArrayList(Type),
};

pub const Struct = struct {
    name: Type,
    fields: []Field,
};
pub const Field = struct {
    name: Name,
    type_: Type,
};

pub const Enum = struct {
    name: Type,
    variants: []Variant,
};
pub const Variant = struct {
    name: Name,
    type_: ?Type,
};

pub const Fun = struct {
    name: Name,
    type_arguments: ArrayList(Type),
    arguments: ArrayList(Argument),
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
    arguments: ArrayList(Expression),
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
fn print_name(name: Name) void {
    std.debug.print("{s}", .{name});
}
fn print_declaration(declaration: Declaration) void {
    switch (declaration) {
        .builtin_type => |bt| {
            std.debug.print("builtinType ", .{});
            print_name(bt);
        },
        .struct_ => std.debug.print("struct", .{}),
        .enum_ => std.debug.print("enum", .{}),
        .fun => |fun| print_fun(fun),
    }
}
fn print_type(type_: Type) void {
    std.debug.print("{s}", .{type_.name});
    const args = type_.arguments.items;
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
fn print_fun(fun: Fun) void {
    std.debug.print("fun ", .{});
    print_name(fun.name);

    const type_args = fun.type_arguments.items;
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

    const args = fun.arguments.items;
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
    print_name(arg.name);
    std.debug.print(": ", .{});
    print_type(arg.type_);
}
