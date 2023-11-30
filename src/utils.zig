const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Ty = @import("ty.zig").Ty;
const Name = @import("ty.zig").Name;

pub fn starts_with(buf: []const u8, prefix: []const u8) bool {
    return buf.len >= prefix.len and std.mem.eql(u8, buf[0..prefix.len], prefix);
}

pub fn cmpNames(context: void, a: []const u8, b: []const u8) bool {
    _ = context;
    switch (std.mem.order(u8, a, b)) {
        .lt => return true,
        else => return false,
    }
}

pub const Signedness = enum { signed, unsigned };

const all_signednesses = [_]Signedness{ .signed, .unsigned };
const all_bits = [_]u8{ 8, 16, 32, 64 };
pub const IntConfig = struct { signedness: Signedness, bits: u8 };
const num_ints = all_signednesses.len * all_bits.len;

pub fn all_int_configs() [num_ints]IntConfig {
    var configs: [num_ints]IntConfig = undefined;
    var i: usize = 0;

    inline for (all_signednesses) |signedness| {
        inline for (all_bits) |bits| {
            configs[i] = .{ .signedness = signedness, .bits = bits };
            i += 1;
        }
    }

    return configs;
}

pub fn int_ty_name(alloc: Allocator, config: IntConfig) !Name {
    var name = ArrayList(u8).init(alloc);
    const signedness_char: u8 = switch (config.signedness) {
        .signed => 'I',
        .unsigned => 'U',
    };
    try std.fmt.format(name.writer(), "{c}{}", .{signedness_char, config.bits});
    return name.items;
}
pub fn int_ty(alloc: Allocator, config: IntConfig) !Ty {
    return .{ .name = try int_ty_name(alloc, config), .args = ArrayList(Ty).init(alloc) };
}
