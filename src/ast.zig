const std = @import("std");
const ArrayList = std.ArrayList;
const Str = @import("string.zig").Str;
const Ty = @import("ty.zig").Ty;
const numbers = @import("numbers.zig");

pub const Program = struct {
    defs: ArrayList(Def),

    pub fn add_builtin_fun(self: *@This(), alloc: std.mem.Allocator, name: Str, ty_args: ?ArrayList(Str), args: ArrayList(Argument), returns: Ty) void {
        self.defs.append(.{ .fun = .{
            .name = name,
            .ty_args = ty_args orelse ArrayList(Str).init(alloc),
            .args = args,
            .returns = returns,
            .is_builtin = true,
            .body = ArrayList(Expr).init(alloc),
        } }) catch return;
    }
};
pub const Def = union(enum) {
    builtin_ty: Str,
    struct_: Struct,
    enum_: Enum,
    fun: Fun,
};

pub const Struct = struct {
    name: Str,
    ty_args: ArrayList(Str),
    fields: ArrayList(Field),
};
pub const Field = struct { name: Str, ty: Ty };

pub const Enum = struct {
    name: Str,
    ty_args: ArrayList(Str),
    variants: ArrayList(Variant),
};
pub const Variant = struct { name: Str, ty: ?Ty };

pub const Fun = struct {
    name: Str,
    ty_args: ArrayList(Str),
    args: ArrayList(Argument),
    returns: ?Ty,
    is_builtin: bool,
    body: Body,
};
pub const Argument = struct { name: Str, ty: Ty };

pub const Body = ArrayList(Expr);
pub const Expr = union(enum) {
    int: Int, // 0_u64
    string: Str, // "foo"
    ref: Str, // foo
    ty_arged: TyArged, // ...[T]
    call: Call, // ...(arg)
    struct_creation: StructCreation, // Foo.{ a = ... }
    member: Member, // foo.bar
    var_: Var, // var foo = ...
    assign: Assign, // foo = ...
    if_: If, // if foo { ... }
    switch_: Switch, // switch foo { a { ... } b(bar) { ... } }
    loop: Body, // loop { ... }
    for_: For, // for a in b { ... }
    return_: *const Expr, // return ...
    ampersanded: *const Expr, // &...
    body: Body,
};
pub const Int = struct { value: i128, signedness: numbers.Signedness, bits: numbers.Bits };
pub const TyArged = struct { arged: *const Expr, ty_args: ArrayList(Ty) };
pub const Call = struct { callee: *const Expr, args: ArrayList(Expr) };
pub const StructCreation = struct { ty: *const Expr, fields: ArrayList(StructCreationField) };
pub const StructCreationField = struct { name: Str, value: Expr };
pub const Member = struct { of: *const Expr, name: Str };
pub const Var = struct { name: Str, value: *Expr };
pub const Assign = struct { to: *Expr, value: *Expr };
pub const If = struct { condition: *const Expr, then: *const Expr, else_: ?*const Expr };
pub const Switch = struct { value: *const Expr, cases: ArrayList(Case) };
pub const Case = struct { variant: Str, binding: ?Str, body: Body };
pub const For = struct { iter_var: Str, iter: *const Expr, body: Body };

pub fn print(writer: anytype, program: Program) !void {
    for (program.defs.items) |def| {
        try print_definition(writer, def);
        try writer.print("\n", .{});
    }
}
pub fn print_definition(writer: anytype, definition: Def) !void {
    switch (definition) {
        .builtin_ty => |name| try writer.print("builtinType {s}", .{name}),
        .struct_ => |s| {
            try writer.print("struct {s}", .{s.name});
            try Ty.print_args_of_strs(writer, s.ty_args.items);
            const fields = s.fields.items;
            if (fields.len == 0) {
                try writer.print(" {{}}", .{});
            } else {
                try writer.print(" {{\n", .{});
                for (fields) |field| {
                    try writer.print("  {s}: {},\n", .{ field.name, field.ty });
                }
                try writer.print("}}", .{});
            }
        },
        .enum_ => |e| {
            try writer.print("enum {s}", .{e.name});
            try Ty.print_args_of_strs(writer, e.ty_args.items);
            const variants = e.variants.items;
            if (variants.len == 0) {
                try writer.print(" {{}}", .{});
            } else {
                try writer.print(" {{\n", .{});
                for (variants) |variant| {
                    try writer.print("  {s}", .{variant.name});
                    if (variant.ty) |ty| {
                        try writer.print(": {}", .{ty});
                    }
                    try writer.print(",\n", .{});
                }
                try writer.print("}}", .{});
            }
        },
        .fun => |fun| try print_fun(writer, fun),
    }
}
pub fn print_signature(writer: anytype, definition: Def) !void {
    switch (definition) {
        .builtin_ty => |bt| try writer.print("{s}", .{bt}),
        .struct_ => |s| {
            try writer.print("{s}", .{s.name});
            try Ty.print_args_of_strs(writer, s.ty_args.items);
        },
        .enum_ => |e| {
            try writer.print("{s}", .{e.name});
            try Ty.print_args_of_strs(writer, e.ty_args.items);
        },
        .fun => |fun| {
            try writer.print("{s}", .{fun.name});
            try Ty.print_args_of_strs(writer, fun.ty_args.items);
            try writer.print("(", .{});
            for (fun.args.items, 0..) |arg, i| {
                if (i > 0) {
                    try writer.print(", ", .{});
                }
                try writer.print("{}", .{arg.ty});
            }
            try writer.print(")", .{});
        },
    }
}
pub fn print_fun(writer: anytype, fun: Fun) !void {
    try writer.print("fun {s}", .{fun.name});
    try Ty.print_args_of_strs(writer, fun.ty_args.items);

    const args = fun.args.items;
    try writer.print("(", .{});
    for (args, 0..) |arg, i| {
        if (i > 0) {
            try writer.print(", ", .{});
        }
        try writer.print("{s}: {}", .{ arg.name, arg.ty });
    }
    try writer.print(")", .{});

    if (fun.returns) |ty| {
        try writer.print(": {}", .{ty});
    }

    try writer.print(" ", .{});
    if (fun.is_builtin) {
        try writer.print("{{ ... }}", .{});
    } else {
        try print_body(writer, 0, fun.body);
    }
}
fn print_indent(writer: anytype, indent: usize) !void {
    for (0..indent) |_| {
        try writer.print("  ", .{});
    }
}
fn print_body(writer: anytype, indent: usize, body: Body) !void {
    try writer.print("{{\n", .{});
    for (body.items) |statement| {
        try print_indent(writer, indent + 1);
        try print_expr(writer, indent + 1, statement);
        try writer.print("\n", .{});
    }
    try print_indent(writer, indent);
    try writer.print("}}", .{});
}
pub fn print_expr(writer: anytype, indent: usize, expr: Expr) error{
    OutOfMemory,
    AccessDenied,
    Unexpected,
    SystemResources,
    FileTooBig,
    NoSpaceLeft,
    DeviceBusy,
    WouldBlock,
    InputOutput,
    OperationAborted,
    BrokenPipe,
    ConnectionResetByPeer,
    DiskQuota,
    InvalidArgument,
    NotOpenForWriting,
    LockViolation,
}!void {
    switch (expr) {
        .int => |int| try writer.print("{d}{c}{d}", .{ int.value, int.signedness.to_char(), int.bits }),
        .string => |str| try writer.print("\"{s}\"", .{str}),
        .ref => |name| try writer.print("{s}", .{name}),
        .ty_arged => |ty_arged| {
            try print_expr(writer, indent, ty_arged.arged.*);
            try Ty.print_args_of_tys(writer, ty_arged.ty_args.items);
        },
        .call => |call| {
            try print_expr(writer, indent, call.callee.*);
            try writer.print("(", .{});
            for (call.args.items, 0..) |arg, i| {
                if (i > 0) {
                    try writer.print(", ", .{});
                }
                try print_expr(writer, indent, arg);
            }
            try writer.print(")", .{});
        },
        .struct_creation => |sc| {
            try print_expr(writer, indent, sc.ty.*);
            try writer.print(".{{", .{});
            for (sc.fields.items) |field| {
                try writer.print("\n", .{});
                try print_indent(writer, indent + 1);
                try writer.print("{s} = ", .{field.name});
                try print_expr(writer, indent + 1, field.value);
                try writer.print(",", .{});
            }
            try writer.print("\n", .{});
            try print_indent(writer, indent);
            try writer.print("}}", .{});
        },
        .member => |member| {
            try print_expr(writer, indent, member.of.*);
            try writer.print(".{s}", .{member.name});
        },
        .var_ => |v| {
            try writer.print("var {s}", .{v.name});
            try writer.print(" = ", .{});
            try print_expr(writer, indent, v.value.*);
        },
        .assign => |assign| {
            try print_expr(writer, indent, assign.to.*);
            try writer.print(" = ", .{});
            try print_expr(writer, indent, assign.value.*);
        },
        .if_ => |if_| {
            try writer.print("if ", .{});
            try print_expr(writer, indent, if_.condition.*);
            try writer.print(" ", .{});
            try print_expr(writer, indent, if_.then.*);
            if (if_.else_) |e| {
                try writer.print(" else ", .{});
                try print_expr(writer, indent, e.*);
            }
        },
        .switch_ => |switch_| {
            try writer.print("switch ", .{});
            try print_expr(writer, indent, switch_.value.*);
            try writer.print(" {{\n", .{});
            for (switch_.cases.items) |case| {
                try print_indent(writer, indent + 1);
                try writer.print("{s}", .{case.variant});
                if (case.binding) |binding| {
                    try writer.print("({s})", .{binding});
                }
                try writer.print(" ", .{});
                try print_body(writer, indent + 1, case.body);
                try writer.print("\n", .{});
            }
            try print_indent(writer, indent);
            try writer.print("}}", .{});
        },
        .loop => |body| {
            try writer.print("loop ", .{});
            try print_body(writer, indent, body);
        },
        .for_ => |for_| {
            try writer.print("for {s} in ", .{for_.iter_var});
            try print_expr(writer, indent, for_.iter.*);
            try writer.print(" ", .{});
            try print_body(writer, indent, for_.body);
        },
        .return_ => |returned| {
            try writer.print("return ", .{});
            try print_expr(writer, indent, returned.*);
        },
        .ampersanded => |e| {
            try writer.print("&", .{});
            try print_expr(writer, indent, e.*);
        },
        .body => |b| try print_body(writer, indent, b),
    }
}
