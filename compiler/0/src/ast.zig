const std = @import("std");
const ArrayList = std.ArrayList;
const StringArrayHashMap = std.StringArrayHashMap;
const Str = @import("string.zig").Str;
const Ty = @import("ty.zig").Ty;
const numbers = @import("numbers.zig");

pub const Program = []const Def;
pub const Def = union(enum) {
    builtin_ty: Str,
    struct_: Struct,
    enum_: Enum,
    fun: Fun,
};

pub const Struct = struct {
    name: Str,
    ty_args: []const Str,
    fields: StringArrayHashMap(Ty),
};

pub const Enum = struct {
    name: Str,
    ty_args: []const Str,
    variants: StringArrayHashMap(Ty),
};

pub const Fun = struct {
    name: Str,
    ty_args: []const Str,
    args: StringArrayHashMap(Ty),
    returns: Ty,
    is_builtin: bool,
    body: Body,
};

pub const Body = []const Expr;
pub const Expr = union(enum) {
    int: Int, // 0_u64
    string: Str, // "foo"
    name: Str, // foo
    ty_arged: TyArged, // ...[T]
    call: Call, // ...(arg)
    struct_creation: StructCreation, // Foo { a = ... }
    enum_creation: EnumCreation, // Maybe.some(5)
    member: Member, // foo.bar
    var_: Var, // var foo = ...
    assign: Assign, // foo = ...
    switch_: Switch, // switch foo case a ... case b(bar) ...
    orelse_: Orelse, // a orelse b
    loop: *const Expr, // loop ...
    for_: For, // for a in b do ...
    return_: *const Expr, // return ...
    ampersanded: *const Expr, // &...
    try_: *const Expr, // ...?
    body: Body,
};
pub const Int = struct { value: i128, signedness: numbers.Signedness, bits: numbers.Bits };
pub const TyArged = struct { arged: *const Expr, ty_args: []const Ty };
pub const Call = struct { callee: *const Expr, args: []const Expr };
pub const StructCreation = struct { ty: Ty, fields: []const StructCreationField };
pub const StructCreationField = struct { name: Str, value: Expr };
pub const EnumCreation = struct { ty: Ty, variant: Str, arg: ?*const Expr };
pub const Member = struct { of: *const Expr, name: Str };
pub const Var = struct { name: Str, value: *Expr };
pub const Assign = struct { to: *Expr, value: *Expr };
pub const Switch = struct { value: *const Expr, cases: []const Case, default: ?*const Expr };
pub const Orelse = struct { primary: *const Expr, alternative: *const Expr };
pub const Case = struct { variant: Str, binding: ?Str, then: *const Expr };
pub const For = struct { iter_var: Str, iter: *const Expr, expr: *const Expr };

pub fn print(writer: anytype, program: Program) !void {
    for (program) |def| {
        try print_definition(writer, def);
        try writer.print("\n", .{});
    }
}
pub fn print_definition(writer: anytype, definition: Def) !void {
    switch (definition) {
        .builtin_ty => |name| try writer.print("builtinType {s}", .{name}),
        .struct_ => |s| {
            try writer.print("struct {s}", .{s.name});
            try Ty.print_args_of_strs(writer, s.ty_args);
            if (s.fields.count() == 0)
                try writer.print(" {{}}", .{})
            else {
                try writer.print(" {{\n", .{});
                var iter = s.fields.iterator();
                while (iter.next()) |field|
                    try writer.print("  {s}: {},\n", .{ field.key_ptr.*, field.value_ptr.* });
                try writer.print("}}", .{});
            }
        },
        .enum_ => |e| {
            try writer.print("enum {s}", .{e.name});
            try Ty.print_args_of_strs(writer, e.ty_args);
            if (e.variants.count() == 0)
                try writer.print(" {{}}", .{})
            else {
                try writer.print(" {{\n", .{});
                var iter = e.variants.iterator();
                while (iter.next()) |variant|
                    try writer.print("  {s}: {},\n", .{ variant.key_ptr.*, variant.value_ptr.* });
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
            try Ty.print_args_of_strs(writer, s.ty_args);
        },
        .enum_ => |e| {
            try writer.print("{s}", .{e.name});
            try Ty.print_args_of_strs(writer, e.ty_args);
        },
        .fun => |fun| {
            try writer.print("{s}", .{fun.name});
            try Ty.print_args_of_strs(writer, fun.ty_args);
            try writer.print("(", .{});
            var args = fun.args.iterator();
            for (0..fun.args.count()) |i| {
                const arg = args.next().?;
                if (i > 0) try writer.print(", ", .{});
                try writer.print("{}", .{arg.value_ptr.*});
            }
            try writer.print(")", .{});
        },
    }
}
pub fn print_fun(writer: anytype, fun: Fun) !void {
    try writer.print("fun {s}", .{fun.name});
    try Ty.print_args_of_strs(writer, fun.ty_args);

    try writer.print("(", .{});
    var args = fun.args.iterator();
    for (0..fun.args.count()) |i| {
        const arg = args.next().?;
        if (i > 0) try writer.print(", ", .{});
        try writer.print("{s}: {}", .{ arg.key_ptr.*, arg.value_ptr.* });
    }
    try writer.print("): {} ", .{fun.returns});
    if (fun.is_builtin)
        try writer.print("{{ ... }}", .{})
    else
        try print_body(writer, 0, fun.body);
}
fn print_indent(writer: anytype, indent: usize) !void {
    for (0..indent) |_| try writer.print("  ", .{});
}
fn print_body(writer: anytype, indent: usize, body: Body) !void {
    try writer.print("{{\n", .{});
    for (body) |statement| {
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
        .name => |name| try writer.print("{s}", .{name}),
        .ty_arged => |ty_arged| {
            try print_expr(writer, indent, ty_arged.arged.*);
            try Ty.print_args_of_tys(writer, ty_arged.ty_args);
        },
        .call => |call| {
            try print_expr(writer, indent, call.callee.*);
            try writer.print("(", .{});
            for (call.args, 0..) |arg, i| {
                if (i > 0) try writer.print(", ", .{});
                try print_expr(writer, indent, arg);
            }
            try writer.print(")", .{});
        },
        .struct_creation => |sc| {
            try writer.print("{}.{{", .{sc.ty});
            for (sc.fields) |field| {
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
        .enum_creation => |ec| {
            try writer.print("{}.{s}", .{ ec.ty, ec.variant });
            if (ec.arg) |arg| {
                try writer.print("(", .{});
                try print_expr(writer, indent, arg.*);
                try writer.print(")", .{});
            }
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
        .switch_ => |switch_| {
            try writer.print("switch ", .{});
            try print_expr(writer, indent, switch_.value.*);
            try writer.print(" {{\n", .{});
            for (switch_.cases) |case| {
                try print_indent(writer, indent);
                try writer.print("case {s}", .{case.variant});
                if (case.binding) |binding| try writer.print("({s})", .{binding});
                try writer.print(" ", .{});
                try print_expr(writer, indent + 1, case.then.*);
                try writer.print("\n", .{});
            }
            try print_indent(writer, indent);
            try writer.print("}}", .{});
        },
        .orelse_ => |orelse_| {
            try print_expr(writer, indent, orelse_.primary.*);
            try writer.print(" orelse ", .{});
            try print_expr(writer, indent, orelse_.alternative.*);
        },
        .loop => |body| {
            try writer.print("loop ", .{});
            try print_expr(writer, indent, body.*);
        },
        .for_ => |for_| {
            try writer.print("for {s} in ", .{for_.iter_var});
            try print_expr(writer, indent, for_.iter.*);
            try writer.print(" do ", .{});
            try print_expr(writer, indent, for_.expr.*);
        },
        .return_ => |returned| {
            try writer.print("return ", .{});
            try print_expr(writer, indent, returned.*);
        },
        .ampersanded => |e| {
            try writer.print("&", .{});
            try print_expr(writer, indent, e.*);
        },
        .try_ => |e| {
            try print_expr(writer, indent, e.*);
            try writer.print("?", .{});
        },
        .body => |b| try print_body(writer, indent, b),
    }
}
