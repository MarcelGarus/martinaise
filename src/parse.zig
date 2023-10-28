const std = @import("std");
const ast = @import("ast.zig");

pub fn parse(alloc: std.mem.Allocator, code: []u8) ?ast.Program {
    // std.debug.print("Compiling code:\n{s}\n", .{code});
    // return ast.Program.builtin_type("hi");
    // unreachable;
    // return .{
    //     .name = code[0..10],
    //     .args = std.ArrayList(ast.Type).init(alloc)
    // };
    var parser = Parser { .code = code, .alloc = alloc };
    const program = parser.parse_program() catch {
        std.debug.print("Couldn't parse program.\n", .{});
        return null;
    };
    return program;
}

const Parser = struct {
    code: []u8,
    alloc: std.mem.Allocator,

    const Self = @This();

    fn consume_whitespace(self: *Self) void {
        var i: usize = 0;
        loop: while (i < self.code.len) : (i += 1) {
            switch (self.code[i]) {
                ' ', '\t', '\n' => {},
                else => break :loop,
            }
        }
        self.code = self.code[i..];
    }

    fn consume_prefix(self: *Self, prefix: []const u8) error{NoMatch}!void {
        if (self.code.len < prefix.len) {
            return error.NoMatch;
        }
        for (prefix, self.code[0..prefix.len]) |a, b| {
            if (a != b) {
                return error.NoMatch;
            }
        }
        self.code = self.code[prefix.len..];
    }
    // Also makes sure there's a whitespace following, so
    // `consume_keyword("fun")` doesn't match the code `funny`.
    fn consume_keyword(self: *Self, keyword: []const u8) error{NoMatch}!void {
        if (self.code.len < keyword.len) {
            return error.NoMatch;
        }
        for (keyword, self.code[0..keyword.len]) |a, b| {
            if (a != b) {
                return error.NoMatch;
            }
        }
        if (self.code.len > keyword.len) {
            switch (self.code[keyword.len]) {
                ' ', '\t', '\n' => {},
                else => return error.NoMatch,
            }
        }
        self.code = self.code[keyword.len..];
    }


    fn parse_program(self: *Self) !ast.Program {
        var declarations = std.ArrayList(ast.Declaration).init(self.alloc);
        var len = self.code.len;
        while (true) {
            self.consume_whitespace();

            parse_builtin_type: {
                const bt = self.parse_builtin_type() catch { break :parse_builtin_type; };
                try declarations.append(.{ .builtin_type = bt });
            }
            parse_struct: {
                const struct_ = self.parse_struct() catch { break :parse_struct; };
                try declarations.append(.{ .struct_ = struct_ });
            }
            parse_fun: {
                const fun = self.parse_fun() catch { break :parse_fun; };
                try declarations.append(.{ .fun = fun });
            }

            const new_len = self.code.len;
            if (new_len == len) {
                break; // Nothing more got parsed.
            } else {
                len = new_len;
            }
        }
        return .{ .declarations = declarations };
    }

    fn parse_name(self: *Self) error{NoMatch}!ast.Name {
        var i: usize = 0;
        loop: while (true) {
            switch (self.code[i]) {
                'A'...'Z', 'a'...'z' => i += 1,
                '0'...'9' => if (i == 0) {
                    break :loop;
                } else {
                    i += 1;
                },
                else => break :loop,
            }
        }
        if (i == 0) {
            return error.NoMatch;
        }
        const name = self.code[0..i];
        self.code = self.code[i..];
        return name;
    }

    fn parse_builtin_type(self: *Self) !ast.BuiltinType {
        try self.consume_keyword("builtinType");
        self.consume_whitespace();
        const name = self.parse_name() catch { return error.ExpectedNameOfBuiltinType; };
        return ast.BuiltinType { .name = name };
    }

    fn parse_type(self: *Self) !ast.Type {
        const name = try self.parse_name();
        self.consume_whitespace();

        var type_args = std.ArrayList(ast.Type).init(self.alloc);
        parse_type_args: {
            self.consume_prefix("[") catch { break :parse_type_args; };
            self.consume_whitespace();
            while (true) {
                const arg = self.parse_type() catch { return error.ExpectedTypeArgument; };
                try type_args.append(arg);
                self.consume_whitespace();
                self.consume_prefix(",") catch { break; };
                self.consume_whitespace();
            }
            self.consume_prefix("]") catch { return error.ExpectedClosingBracket; };
        }

        return .{ .name = name, .args = type_args };
    }

    fn parse_struct(self: *Self) !ast.Struct {
        try self.consume_keyword("struct");
        self.consume_whitespace();
        const name = self.parse_name() catch { return error.ExpectedNameOfStruct; };
        self.consume_whitespace();

        // TODO: parse types args
        var type_args = std.ArrayList(ast.Type).init(self.alloc);

        self.consume_prefix("{") catch { return error.ExpectedOpeningBrace; };
        self.consume_whitespace();

        var fields = std.ArrayList(ast.Field).init(self.alloc);
        while (true) {
            const field_name = self.parse_name() catch { break; };
            self.consume_whitespace();
            self.consume_prefix(":") catch { return error.ExpectedColon; };
            self.consume_whitespace();
            const field_type = try self.parse_type();
            try fields.append(.{ .name = field_name, .type_ = field_type });
            self.consume_prefix(",") catch { break; };
            self.consume_whitespace();
        }

        self.consume_prefix("}") catch { return error.ExpectedClosingBrace; };

        return ast.Struct { .name = name, .type_args = type_args, .fields = fields };
    }

    fn parse_fun(self: *Self) !ast.Fun {
        self.consume_keyword("fun") catch { return error.NoMatch; };
        self.consume_whitespace();
        const name = self.parse_name() catch { return error.ExpectedNameOfFunction; };
        self.consume_whitespace();

        // TODO: parse type args
        var type_args = std.ArrayList(ast.Type).init(self.alloc);

        var args = std.ArrayList(ast.Argument).init(self.alloc);
        self.consume_prefix("(") catch { return error.ExpectedOpeningParenthesis; };
        self.consume_whitespace();
        while (true) {
            const arg_name = self.parse_name() catch { break; };
            self.consume_whitespace();
            self.consume_prefix(":") catch { return error.ExpectedColon; };
            self.consume_whitespace();
            const arg_type = try self.parse_type();
            try args.append(.{ .name = arg_name, .type_ = arg_type });
            self.consume_prefix(",") catch { break; };
            self.consume_whitespace();
        }
        self.consume_prefix(")") catch { return error.ExpectedClosingParenthesis; };
        self.consume_whitespace();

        var return_type: ?ast.Type = null;
        parse_return_type: {
            self.consume_prefix(":") catch { break :parse_return_type; };
            self.consume_whitespace();
            return_type = self.parse_type() catch { return error.ExpectedReturnType; };
        }

        return .{
            .name = name,
            .type_args = type_args,
            .args = args,
            .return_type = return_type,
            .body = std.ArrayList(ast.Expression).init(self.alloc),
        };
    }
};

// fn Parsed(comptime T: type) type {
//     return struct {
//         code: []u8,
//         parsed: T,
//     };
// }







