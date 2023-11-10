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

pub const Name = []const u8;

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
    number: i128,
    reference: Name,
    call: Call,
    member: Member,
    var_: Var,
    if_: If,
    struct_construction: StructConstruction,
};
pub const Call = struct {
    callee: *const Expression,
    type_args: ArrayList(Type),
    args: ArrayList(Expression),
};
pub const Member = struct {
    callee: *const Expression,
    member: Name,
};
pub const Var = struct {
    name: Name,
    type_: ?Type,
    value: *Expression,
};
pub const If = struct {
    condition: *const Expression,
    then: Body,
    else_: ?Body,
};
pub const StructConstruction = struct {
    type_: *const Expression,
    fields: ArrayList(ConstructionField),
};
pub const ConstructionField = struct {
    name: Name,
    value: Expression,
};

pub fn print(program: Program) void {
    const decls = program.declarations.items;
    for (decls) |decl| {
        print_declaration(decl);
        std.debug.print("\n", .{});
    }
}
pub fn print_declaration(declaration: Declaration) void {
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

    std.debug.print(" ", .{});
    print_body(0, fun.body);
}
fn print_indent(indent: usize) void {
    for (0..indent) |_| {
        std.debug.print("  ", .{});
    }
}
fn print_body(indent: usize, body: Body) void {
    std.debug.print("{{\n", .{});
    for (body.items) |statement| {
        print_indent(indent + 1);
        print_expression(indent + 1, statement);
        std.debug.print("\n", .{});
    }
    print_indent(indent);
    std.debug.print("}}", .{});
}
fn print_expression(indent: usize, expression: Expression) void {
    switch (expression) {
        .number => |n| std.debug.print("{}", .{n}),
        .reference => |name| std.debug.print("{s}", .{name}),
        .call => |call| print_call(indent, call),
        .member => |member| print_member(indent, member),
        .var_ => |var_| print_var(indent, var_),
        .if_ => |if_| print_if(indent, if_),
        .struct_construction => |struct_construction| print_struct_construction(indent, struct_construction),
    }
}
fn print_call(indent: usize, call: Call) void {
    print_expression(indent, call.callee.*);

    const type_args = call.type_args.items;
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

    std.debug.print("(", .{});
    for (call.args.items, 0..) |arg, i| {
        if (i > 0) {
            std.debug.print(", ", .{});
        }
        print_expression(indent, arg);
    }
    std.debug.print(")", .{});
}
fn print_member(indent: usize, member: Member) void {
    print_expression(indent, member.callee.*);
    std.debug.print(".{s}", .{member.member});
}
fn print_var(indent: usize, var_: Var) void {
    std.debug.print("var {s}", .{var_.name});
    if (var_.type_) |t| {
        std.debug.print(": ", .{});
        print_type(t);
    }
    std.debug.print(" = ", .{});
    print_expression(indent, var_.value.*);
}
fn print_if(indent: usize, if_: If) void {
    std.debug.print("if ", .{});
    print_expression(indent, if_.condition.*);
    std.debug.print(" ", .{});
    print_body(indent, if_.then);
    if (if_.else_) |e| {
        std.debug.print(" else ", .{});
        print_body(indent, e);
    }
}
fn print_struct_construction(indent: usize, struct_construction: StructConstruction) void {
    print_expression(indent, struct_construction.type_.*);
    std.debug.print(".{{", .{});
    for (struct_construction.fields.items) |field| {
        std.debug.print("\n", .{});
        print_indent(indent + 1);
        std.debug.print("{s} = ", .{field.name});
        print_expression(indent + 1, field.value);
        std.debug.print(",", .{});
    }
    std.debug.print("\n", .{});
    print_indent(indent);
    std.debug.print("}}", .{});
}
fn print_argument(arg: Argument) void {
    std.debug.print("{s}: ", .{arg.name});
    print_type(arg.type_);
}
