const std = @import("std");
const Alloc = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.HashMap;
const ArrayHashMap = std.ArrayHashMap;
const StringHashMap = std.StringHashMap;
const string = @import("string.zig");
const String = string.String;
const Str = string.Str;

/// A type such as `Int` or `Maybe[T]`.
pub const Ty = struct {
    name: Str,
    args: []const Ty,

    const Self = @This();

    pub fn named(name: Str) Self {
        return .{ .name = name, .args = &[_]Ty{} };
    }

    pub fn format(
        self: Self,
        comptime fmt: Str,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("{s}", .{self.name});
        if (string.eql(self.name, "&"))
            try self.args[0].format(fmt, options, writer)
        else
            try print_args_of_tys(writer, self.args);
    }

    pub fn print_args_of_tys(writer: anytype, args: ?[]const Ty) !void {
        try print_args(Ty, "{any}", writer, args);
    }
    pub fn print_args_of_strs(writer: anytype, args: ?[]const Str) !void {
        try print_args(Str, "{s}", writer, args);
    }
    fn print_args(comptime T: type, comptime fmt: []const u8, writer: anytype, args: ?[]const T) !void {
        if (args) |ty_args| if (ty_args.len > 0) {
            try writer.print("[", .{});
            for (ty_args, 0..) |arg, i| {
                if (i > 0) try writer.print(", ", .{});
                try writer.print(fmt, .{arg});
            }
            try writer.print("]", .{});
        };
    }

    pub fn specialize(self: Self, alloc: std.mem.Allocator, ty_env: StringHashMap(Ty)) !Self {
        if (ty_env.get(self.name)) |ty| {
            // TODO: Make sure generic types doesn't have parameters.
            return ty;
        }
        var mapped_args = ArrayList(Ty).init(alloc);
        for (self.args) |arg| try mapped_args.append(try arg.specialize(alloc, ty_env));
        return .{ .name = self.name, .args = mapped_args.items };
    }

    pub fn hash(self: Self) u32 {
        _ = self;

        return 0;
    }

    pub fn eql(self: Self, other: Self) bool {
        if (!string.eql(self.name, other.name)) return false;
        if (self.args.len != other.args.len) return false;
        for (self.args, other.args) |a, b| if (!a.eql(b)) return false;
        return true;
    }
};

pub fn TyArrayHashMap(comptime V: type) type {
    return ArrayHashMap(Ty, V, struct {
        pub fn hash(self: @This(), ty: Ty) u32 {
            _ = self;
            return ty.hash();
        }
        pub fn eql(self: @This(), a: Ty, b: Ty, b_index: usize) bool {
            _ = b_index;

            _ = self;
            return a.eql(b);
        }
    }, false);
}
pub fn TyHashMap(comptime V: type) type {
    return HashMap(Ty, V, struct {
        pub fn hash(self: @This(), ty: Ty) u64 {
            _ = self;
            return ty.hash();
        }
        pub fn eql(self: @This(), a: Ty, b: Ty) bool {
            _ = self;
            return a.eql(b);
        }
    }, 60);
}
