const std = @import("std");
const ArrayList = std.ArrayList;
const FormatOptions = std.fmt.FormatOptions;

pub const Name = []const u8;

pub const Program = struct {
    defs: ArrayList(Def),

    pub fn format(self: @This(), comptime fmt: []const u8, options: FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        for (self.defs) |def| {
            try writer.print("{}\n", .{def});
        }
    }
};
pub const Def = union(enum) {
    builtin_ty: Name,
    struct_: Struct,
    enum_: Enum,
    fun: Fun,

    pub fn format(self: @This(), comptime fmt: []const u8, options: FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .builtin_ty => |name| try writer.print("builtinType {}", .{name}),
            .struct_ => |s| print_struct(s),
            .enum_ => |e| print_enum(e),
            .fun => |fun| print_fun(fun),
        }
    }
};

pub const Struct = struct {
    name: Name,
    ty_args: ArrayList(Name),
    fields: ArrayList(Field),

    pub fn format(self: @This(), comptime fmt: []const u8, options: FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        try writer.print("struct {s}", .{self.name});
        Ty.write_args(Name, writer, self.ty_args);

        const fields = self.fields.items;
        if (fields.len == 0) {
            try writer.print(" {{}}", .{});
        } else {
            try writer.print(" {{\n", .{});
            for (fields) |field| {
                try writer.print("  {s}: {},\n", .{field.name, field.ty});
            }
            try writer.print("}}", .{});
        }
    }
};
pub const Field = struct { name: Name, ty: Ty };

pub const Enum = struct {
    name: Name,
    ty_args: ArrayList(Name),
    variants: ArrayList(Variant),

    pub fn format(self: @This(), comptime fmt: []const u8, options: FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        try writer.print("enum {s}", .{self.name});
        Ty.write_args(Name, writer, self.ty_args);

        const variants = e.variants.items;
        if (variants.len == 0) {
            try writer.print(" {{}}", .{e.name});
        } else {
            try writer.print(" {{\n", .{e.name});
            for (variants) |variant| {
                try writer.print("  {s}", .{variant.name});
                if (variant.type_) |t| {
                    try writer.print(": {}", .{t});
                }
                try writer.print(",\n", .{});
            }
            try writer.print("}}", .{});
        }
    }
};
pub const Variant = struct { name: Name, type_: ?Ty };

pub const Fun = struct {
    name: Name,
    type_args: ArrayList(Ty),
    args: ArrayList(Argument),
    return_type: ?Ty,
    is_builtin: bool,
    body: Body,

    pub fn format(self: @This(), comptime fmt: []const u8, options: FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        try writer.print("enum {s}", .{self.name});
        Ty.write_args(Name, writer, self.ty_args);

        const variants = e.variants.items;
        if (variants.len == 0) {
            try writer.print(" {{}}", .{e.name});
        } else {
            try writer.print(" {{\n", .{e.name});
            for (variants) |variant| {
                try writer.print("  {s}", .{variant.name});
                if (variant.type_) |t| {
                    try writer.print(": {}", .{t});
                }
                try writer.print(",\n", .{});
            }
            try writer.print("}}", .{});
        }
    }
};
pub const Argument = struct { name: Name, type_: Ty };

pub const Body = ArrayList(Expression);
pub const Expression = union(enum) {
    num: i128,
    ref: Name,
    ty_arged: TyArged,
    call: Call,
    struct_construction: StructConstruction,
    member: Member,
    var_: Var,
    assign: Assign,
    if_: If,
    return_: *const Expression,
};
pub const TyArged = struct {
    arged: *const Expression,
    type_args: ArrayList(Ty),
};
pub const Call = struct {
    callee: *const Expression,
    args: ArrayList(Expression),
};
pub const StructConstruction = struct {
    type_: *const Expression,
    fields: ArrayList(ConstructionField),
};
pub const ConstructionField = struct {
    name: Name,
    value: Expression,
};
pub const Member = struct {
    of: *const Expression,
    name: Name,
};
pub const Var = struct {
    name: Name,
    type_: ?Ty,
    value: *Expression,
};
pub const Assign = struct {
    to: *Expression,
    value: *Expression,
};
pub const If = struct {
    condition: *const Expression,
    then: Body,
    else_: ?Body,
};

pub fn print(program: Program) void {
    const decls = program.def.items;
    for (decls) |decl| {
        print_definition(decl);
        std.debug.print("\n", .{});
    }
}
pub fn print_definition(declaration: Def) void {
    switch (declaration) {
        .builtin_type => |bt| print_builtin_type(bt),
        .struct_ => |s| print_struct(s),
        .enum_ => |e| print_enum(e),
        .fun => |fun| print_fun(fun),
    }
}
pub fn print_signature(declaration: Def) void {
    switch (declaration) {
        .builtin_type => |bt| std.debug.print("{s}", .{bt.name}),
        .struct_ => |s| {
            std.debug.print("{s}", .{s.name});
            print_type_args(s.type_args);
        },
        .enum_ => |e| {
            std.debug.print("{s}", .{e.name});
            print_type_args(e.type_args);
        },
        .fun => |fun| {
            std.debug.print("{s}", .{fun.name});
            print_type_args(fun.type_args);
            std.debug.print("(", .{});
            for (fun.args.items, 0..) |arg, i| {
                if (i > 0) {
                    std.debug.print(", ", .{});
                }
                print_type(arg.type_);
            }
            std.debug.print(")", .{});
        },
    }
}


fn print_enum(e: Enum) void {
    // TODO: print type args
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

    print_type_args(fun.type_args);

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
        .ty_arged => |ty_arged| {
            print_expression(indent, ty_arged.arged.*);
            print_type_args(ty_arged.type_args);
        },
        .call => |call| print_call(indent, call),
        .member => |member| print_member(indent, member),
        .var_ => |var_| print_var(indent, var_),
        .assign => |assign| print_assign(indent, assign),
        .if_ => |if_| print_if(indent, if_),
        .struct_construction => |struct_construction| print_struct_construction(indent, struct_construction),
        .return_ => |returned| {
            std.debug.print("return ", .{});
            print_expression(indent, returned.*);
        },
    }
}
fn print_call(indent: usize, call: Call) void {
    print_expression(indent, call.callee.*);

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
    print_expression(indent, member.on.*);
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
fn print_assign(indent: usize, assign: Assign) void {
    print_expression(indent, assign.to.*);
    std.debug.print(" = ", .{});
    print_expression(indent, assign.value.*);
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
