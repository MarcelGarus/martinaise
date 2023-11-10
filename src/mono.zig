const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const Name = @import("ast.zig").Name;

pub const Types = struct {
    // The keys are strings of concrete types such as "Maybe[U8]".
    types: StringHashMap(Type),

    const Self = @This();

    pub fn contains(self: *Self, name: Name) bool {
        for (self.types.items) |ty| {
            if (ty.name == name) {
                return true;
            }
        }
        return false;
    }
    pub fn put(self: *Self, name: Name, ty: Type) !void {
        std.debug.print("New type {s}.\n", .{name});
        try self.types.put(name, ty);
    }
};

pub const Type = union(enum) {
    builtin_type,
    struct_: Struct,
    enum_: Enum,
    fun,
};

pub const Struct = struct {
    fields: ArrayList(Field),
};
pub const Field = struct {
    name: Name,
    type_: Name,
};

pub const Enum = struct {
    variants: ArrayList(Variant),
};
pub const Variant = struct {
    name: Name,
    type_: Name,
};

pub const Funs = struct {
    funs: StringHashMap(Fun),
};

pub const Fun = struct {
    expressions: ArrayList(Expression),
    types: ArrayList(Type),
    // blocks: ArrayList(Block),
};
pub const ExpressionIndex = isize;
pub const Expression = union(enum) {
    number: i128,
    call: Call,
    member: Member,
    return_: ExpressionIndex,
};
pub const Call = struct {
    callee: Name, // monomorphized function name
    args: ArrayList(ExpressionIndex),
};
pub const Member = struct {
    callee: ExpressionIndex,
    member: Name,
};
