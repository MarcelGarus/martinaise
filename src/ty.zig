const Alloc = std.mem.Allocator;

/// A type such as `Int` or `Maybe[T]`.
pub const Ty = struct {
    name: Name,
    args: ArrayList(Ty),

    // Type arguments to concrete types, for example `T` to `Int`.
    const TyEnv = StringHashMap(Ty);

    const Self = @This();

    fn specialize(self: Self, alloc: Alloc, ty_env: TyEnv) !Ty {
        if (ty_env.get(self.name)) |mapped| {
            if (self.args.items.len > 0) {
                return error.TypeArgumentCantHaveGenerics;
            }
            return mapped;
        }

        var mapped_args = ArrayList(Ty).init(alloc);
        for (self.args) |arg| {
            try mapped_args.append(self.specialize(alloc, ty_env));
        }
        return .{ .name = self.name, .args = mapped_args };
    }

    // Checks if `self` is assignable to `other` under the given type env.
    // Adds constraints to the type env.
    fn is_assignable_to(self: *Self, ty_env: *TyEnv, other: Ty) !bool {
        // Under ty env `{A: Int}`, is `A` assignable to `B`? Depends on whether
        // `Int` is assignable to `B`.
        if (ty_env.get(self.name)) |mapped| {
            if (self.args.items.len > 0) {
                return error.TypeArgumentCantHaveGenerics;
            }
            return mapped.is_assignable_to(ty_env, other);
        }

        // Under ty env `{A: Int}`, is `B` assignable to `A`? Depends on whether
        // `B` is assignable to `Int`.
        if (ty_env.get(other.name)) |mapped| {
            if (other.args.items.len > 0) {
                return error.TypeArgumentCantHaveGenerics;
            }
            return self.is_assignable_to(ty_env, mapped);
        }

        // With args now resolved, a types is assignable to another if the names
        // match and the arguments are assignable to the other one's.

        if (!std.mem.eql(u8, self.name, other.name)) {
            return false;
        }
        if (self.args.items.len != other.args.items.len) {
            return false;
        }
        for (self.args.items, other.args.items) |self_arg, other_arg| {
            if (!try self.type_unify(ty_env, self_arg, other_arg)) {
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
        try write_args(Ty, writer, self.args);
        // if (self.args) |args| {
        //     if (args.items.len > 0) {
        //         try writer.writeAll("[");
        //         for (args.items, 0..) |arg, i| {
        //             if (i > 0) {
        //                 try writer.writeAll(", ");
        //             }
        //             try writer.print("{}", arg);
        //         }
        //         try writer.writeAll("]");
        //     }
        // }
    }

    pub fn write_args(T: type, writer: anytype, args: ?ArrayList(T)) !void {
        if (args) |ty_args| {
            if (ty_args.items.len > 0) {
                writer.print("[", .{});
                for (ty_args.items, 0..) |arg, i| {
                    if (i > 0) {
                        writer.print(", ", .{});
                    }
                    writer.print("{}", .{arg});
                }
                writer.print("]", .{});
            }
        }
    }
};
