const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Ty = @import("ty.zig").Ty;
const string = @import("string.zig");
const Str = string.Str;

pub const Signedness = enum {
    signed,
    unsigned,

    pub fn to_char(self: @This()) u8 {
        switch (self) {
            .signed => return 'I',
            .unsigned => return 'U',
        }
    }
};
pub const Bits = u8;

pub const all_signednesses = [_]Signedness{ .signed, .unsigned };
pub const all_bits = [_]Bits{ 8, 16, 32, 64 };
pub const IntConfig = struct { signedness: Signedness, bits: Bits };
const num_ints = all_signednesses.len * all_bits.len;

pub fn all_int_configs() [num_ints]IntConfig {
    var configs: [num_ints]IntConfig = undefined;
    var i: usize = 0;

    inline for (all_signednesses) |signedness| inline for (all_bits) |bits| {
        configs[i] = .{ .signedness = signedness, .bits = bits };
        i += 1;
    };

    return configs;
}

pub fn int_ty_name(alloc: Allocator, config: IntConfig) !Str {
    return string.formata(alloc, "{c}{}", .{ config.signedness.to_char(), config.bits });
}
pub fn int_ty(alloc: Allocator, config: IntConfig) !Ty {
    return .{ .name = try int_ty_name(alloc, config), .args = &[_]Ty{} };
}
