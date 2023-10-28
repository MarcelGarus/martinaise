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
    var parser = Parser{ .code = code, .alloc = alloc };
    // TODO: Handle OOM error differently
    const program = parser.parse_program() catch |err| {
        const offset = code.len - parser.code.len;

        var lines = std.ArrayList([]u8).init(alloc);
        var current_line = std.ArrayList(u8).init(alloc);
        for (code, 0..) |c, i| {
            if (offset == i) {
                break;
            }
            switch (c) {
                '\n' => {
                    lines.append(current_line.items) catch {
                        unreachable;
                    };
                    current_line = std.ArrayList(u8).init(alloc);
                },
                else => |a| current_line.append(a) catch {
                    unreachable;
                },
            }
        }
        const num_lines_to_display = 4;
        for (lines.items.len - num_lines_to_display + 1..lines.items.len) |number| {
            if (lines.items.len >= number) {
                std.debug.print("{d:4} | {s}\n", .{ number + 1, lines.items[number] });
            }
        }
        std.debug.print("{d:4} | {s}", .{ lines.items.len, current_line.items });
        for (code[offset..]) |c| {
            switch (c) {
                '\n' => break,
                else => std.debug.print("{c}", .{c}),
            }
        }
        std.debug.print("\n", .{});

        std.debug.print("       ", .{});
        for (0..current_line.items.len) |_| {
            std.debug.print(" ", .{});
        }
        std.debug.print("^\n", .{});
        std.debug.print(" ", .{});
        for (0..current_line.items.len) |_| {
            std.debug.print(" ", .{});
        }
        std.debug.print("{}\n", .{err});

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

    fn consume_prefix(self: *Self, prefix: []const u8) ?void {
        if (self.code.len < prefix.len) {
            return null;
        }
        for (prefix, self.code[0..prefix.len]) |a, b| {
            if (a != b) {
                return null;
            }
        }
        self.code = self.code[prefix.len..];
    }
    // Also makes sure there's a whitespace following, so
    // `consume_keyword("fun")` doesn't match the code `funny`.
    fn consume_keyword(self: *Self, keyword: []const u8) ?void {
        if (self.code.len < keyword.len) {
            return null;
        }
        for (keyword, self.code[0..keyword.len]) |a, b| {
            if (a != b) {
                return null;
            }
        }
        if (self.code.len > keyword.len) {
            switch (self.code[keyword.len]) {
                ' ', '\t', '\n' => {},
                else => return null,
            }
        }
        self.code = self.code[keyword.len..];
    }

    fn parse_program(self: *Self) !ast.Program {
        var declarations = std.ArrayList(ast.Declaration).init(self.alloc);
        var len = self.code.len;
        while (true) {
            self.consume_whitespace();

            if (try self.parse_builtin_type()) |bt| {
                try declarations.append(.{ .builtin_type = bt });
            }
            if (try self.parse_struct()) |s| {
                try declarations.append(.{ .struct_ = s });
            }
            if (try self.parse_enum()) |e| {
                try declarations.append(.{ .enum_ = e });
            }
            if (try self.parse_fun()) |fun| {
                try declarations.append(.{ .fun = fun });
            }

            const new_len = self.code.len;
            if (new_len == len) {
                break; // Nothing more got parsed.
            } else {
                len = new_len;
            }
        }
        if (len > 0) {
            return error.ExpectedDeclaration;
        }
        return .{ .declarations = declarations };
    }

    fn parse_name(self: *Self) ?ast.Name {
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
            return null;
        }
        const name = self.code[0..i];
        self.code = self.code[i..];
        return name;
    }

    fn parse_builtin_type(self: *Self) !?ast.BuiltinType {
        self.consume_keyword("builtinType") orelse return null;
        self.consume_whitespace();
        const name = self.parse_name() orelse return error.ExpectedNameOfBuiltinType;
        return ast.BuiltinType{ .name = name };
    }

    fn parse_type(self: *Self) !?ast.Type {
        const name = self.parse_name() orelse return null;
        self.consume_whitespace();

        var type_args = std.ArrayList(ast.Type).init(self.alloc);
        parse_type_args: {
            self.consume_prefix("[") orelse break :parse_type_args;
            self.consume_whitespace();
            while (true) {
                const arg = try self.parse_type() orelse return error.ExpectedTypeArgument;
                try type_args.append(arg);
                self.consume_whitespace();
                self.consume_prefix(",") orelse break;
                self.consume_whitespace();
            }
            self.consume_prefix("]") orelse return error.ExpectedClosingBracket;
        }

        return .{ .name = name, .args = type_args };
    }

    fn parse_struct(self: *Self) !?ast.Struct {
        self.consume_keyword("struct") orelse return null;
        self.consume_whitespace();
        const name = self.parse_name() orelse return error.ExpectedNameOfStruct;
        self.consume_whitespace();

        // TODO: parse type args
        var type_args = std.ArrayList(ast.Type).init(self.alloc);

        self.consume_prefix("{") orelse return error.ExpectedOpeningBrace;
        self.consume_whitespace();

        var fields = std.ArrayList(ast.Field).init(self.alloc);
        while (true) {
            const field_name = self.parse_name() orelse break;
            self.consume_whitespace();
            self.consume_prefix(":") orelse return error.ExpectedColon;
            self.consume_whitespace();
            const field_type = try self.parse_type() orelse {
                return error.ExpectedTypeOfField;
            };
            try fields.append(.{ .name = field_name, .type_ = field_type });
            self.consume_prefix(",") orelse break;
            self.consume_whitespace();
        }

        self.consume_prefix("}") orelse return error.ExpectedClosingBrace;

        return ast.Struct{ .name = name, .type_args = type_args, .fields = fields };
    }

    fn parse_enum(self: *Self) !?ast.Enum {
        self.consume_keyword("enum") orelse return null;
        self.consume_whitespace();
        const name = self.parse_name() orelse return error.ExpectedNameOfEnum;
        self.consume_whitespace();

        // TODO: parse type args
        var type_args = std.ArrayList(ast.Type).init(self.alloc);

        self.consume_prefix("{") orelse return error.ExpectedOpeningBrace;
        self.consume_whitespace();

        var variants = std.ArrayList(ast.Variant).init(self.alloc);
        while (true) {
            const variant_name = self.parse_name() orelse break;
            var variant_type: ?ast.Type = null;

            self.consume_whitespace();
            if (self.consume_prefix(":")) |_| {
                self.consume_whitespace();
                variant_type = try self.parse_type();
                self.consume_whitespace();
            }
            try variants.append(.{ .name = variant_name, .type_ = variant_type });
            self.consume_prefix(",") orelse break;
            self.consume_whitespace();
        }

        self.consume_prefix("}") orelse return error.ExpectedClosingBrace;

        return ast.Enum{ .name = name, .type_args = type_args, .variants = variants };
    }

    fn parse_fun(self: *Self) !?ast.Fun {
        self.consume_keyword("fun") orelse return null;
        self.consume_whitespace();
        const name = self.parse_name() orelse return error.ExpectedNameOfFunction;
        self.consume_whitespace();

        // TODO: parse type args
        var type_args = std.ArrayList(ast.Type).init(self.alloc);

        var args = std.ArrayList(ast.Argument).init(self.alloc);
        self.consume_prefix("(") orelse return error.ExpectedOpeningParenthesis;
        self.consume_whitespace();
        while (true) {
            const arg_name = self.parse_name() orelse break;
            self.consume_whitespace();
            self.consume_prefix(":") orelse return error.ExpectedColon;
            self.consume_whitespace();
            const arg_type = try self.parse_type() orelse {
                return error.ExpectedTypeOfArgument;
            };
            try args.append(.{ .name = arg_name, .type_ = arg_type });
            self.consume_prefix(",") orelse break;
            self.consume_whitespace();
        }
        self.consume_prefix(")") orelse return error.ExpectedClosingParenthesis;
        self.consume_whitespace();

        var return_type: ?ast.Type = null;
        parse_return_type: {
            self.consume_prefix(":") orelse break :parse_return_type;
            self.consume_whitespace();
            return_type = try self.parse_type() orelse return error.ExpectedReturnType;
        }

        const body = try self.parse_body() orelse return error.ExpectedBody;

        return .{
            .name = name,
            .type_args = type_args,
            .args = args,
            .return_type = return_type,
            .body = body,
        };
    }

    fn parse_body(self: *Self) !?ast.Body {
        self.consume_prefix("{") orelse return null;

        var statements = std.ArrayList(ast.Expression).init(self.alloc);
        var len = self.code.len;
        while (true) {
            self.consume_whitespace();

            if (try self.parse_var()) |var_| {
                try statements.append(.{ .var_ = var_ });
            }

            const new_len = self.code.len;
            if (new_len == len) {
                break; // Nothing more got parsed.
            } else {
                len = new_len;
            }
        }

        self.consume_prefix("}") orelse return error.ExpectedStatementOrClosingBrace;
        return statements;
    }

    fn parse_expression(self: *Self) !?ast.Expression {
        if (self.parse_number()) |number| {
            return .{ .number = number };
        }

        return null;
    }

    fn parse_number(self: *Self) ?i128 {
        var i: usize = 0;
        var num: i128 = 0;
        loop: while (true) {
            switch (self.code[i]) {
                '0'...'9' => {
                    num = num * 10 + (self.code[i] - '0');
                    i += 1;
                },
                else => break :loop,
            }
        }
        if (i == 0) {
            return null;
        }
        self.code = self.code[i..];
        return num;
    }

    fn parse_var(self: *Self) !?ast.Var {
        self.consume_keyword("var") orelse return null;
        self.consume_whitespace();

        const name = self.parse_name() orelse return error.ExpectedNameOfVar;
        self.consume_whitespace();

        self.consume_prefix(":") orelse return error.ExpectedColon;
        self.consume_whitespace();

        const type_ = try self.parse_type() orelse return error.ExpectedTypeOfVar;

        self.consume_whitespace();
        self.consume_prefix("=") orelse return error.ExpectedEquals;
        self.consume_whitespace();

        var value = try self.parse_expression() orelse return error.ExpectedValueOfVar;
        self.consume_prefix(";") orelse return error.ExpectedSemicolon;

        return .{ .name = name, .type_ = type_, .value = &value };
    }
};
