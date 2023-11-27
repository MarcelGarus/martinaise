const std = @import("std");
const Alloc = std.mem.Allocator;
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;

pub const Name = []const u8;

/// A type such as `Int` or `Maybe[T]`.
pub const Ty = struct {
    name: Name,
    args: ArrayList(Ty),

    // Type arguments to concrete types, for example `T` to `Int`.
    const TyEnv = StringHashMap(Ty);

    const Self = @This();

    pub fn specialize(self: Self, alloc: Alloc, ty_env: TyEnv) !Ty {
        if (ty_env.get(self.name)) |mapped| {
            if (self.args.items.len > 0) {
                return error.TypeArgumentCantHaveGenerics;
            }
            return mapped;
        }

        var mapped_args = ArrayList(Ty).init(alloc);
        for (self.args) |arg| {
            try mapped_args.append(arg.specialize(alloc, ty_env));
        }
        return .{ .name = self.name, .args = mapped_args };
    }

    // Checks if `self` is assignable to `other` under the given type env.
    // Adds constraints to the type env.
    pub fn is_assignable_to(self: *const Self, ty_vars: StringHashMap(void), ty_env: *TyEnv, other: Ty) !bool {
        // std.debug.print("Is {} assignable to {}?\n", .{self.*, other});

        // Under ty env `{A: Int}`, is `A` assignable to `B`? Depends on whether
        // `Int` is assignable to `B`.
        if (ty_env.get(self.name)) |mapped| {
            if (self.args.items.len > 0) {
                return error.TypeArgumentCantHaveGenerics;
            }
            return mapped.is_assignable_to(ty_vars, ty_env, other);
        }

        // Under ty env `{A: Int}`, is `B` assignable to `A`? Depends on whether
        // `B` is assignable to `Int`.
        if (ty_env.get(other.name)) |mapped| {
            if (other.args.items.len > 0) {
                return error.TypeArgumentCantHaveGenerics;
            }
            return self.is_assignable_to(ty_vars, ty_env, mapped);
        }

        // With args now resolved, a type is assignable to another if the names
        // match and the arguments are assignable to the other one's.

        if (ty_vars.get(self.name)) |_| {
            try ty_env.put(self.name, other);
            return true;
        }

        if (ty_vars.get(other.name)) |_| {
            try ty_env.put(other.name, self.*);
            return true;
        }

        if (!std.mem.eql(u8, self.name, other.name)) {
            return false;
        }
        if (self.args.items.len != other.args.items.len) {
            return false;
        }
        for (self.args.items, other.args.items) |self_arg, other_arg| {
            if (!try self_arg.is_assignable_to(ty_vars, ty_env, other_arg)) {
                return false;
            }
        }
        return true;
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("{s}", .{self.name});
        try print_args_of_tys(writer, self.args);
    }

    pub fn print_args_of_tys(writer: anytype, args: ?ArrayList(Ty)) !void {
        try print_args(Ty, "{any}", writer, args);
    }
    pub fn print_args_of_names(writer: anytype, args: ?ArrayList(Name)) !void {
        try print_args(Name, "{s}", writer, args);
    }
    fn print_args(comptime T: type, comptime fmt: []const u8, writer: anytype, args: ?ArrayList(T)) !void {
        if (args) |ty_args| {
            if (ty_args.items.len > 0) {
                try writer.print("[", .{});
                for (ty_args.items, 0..) |arg, i| {
                    if (i > 0) {
                        try writer.print(", ", .{});
                    }
                    try writer.print(fmt, .{arg});
                }
                try writer.print("]", .{});
            }
        }
    }
};