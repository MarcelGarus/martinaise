const std = @import("std");
const ast = @import("ast.zig");
const ArrayList = std.ArrayList;

pub fn parse(alloc: std.mem.Allocator, code: []u8) ?ast.Program {
    var parser = Parser{ .code = code, .alloc = alloc };
    // TODO: Handle OOM error differently
    var program = parser.parse_program() catch |err| {
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
        const num_lines_to_display = @min(lines.items.len, 4);
        for (lines.items.len - num_lines_to_display + 1..lines.items.len) |number| {
            if (lines.items.len >= number) {
                std.debug.print("{d:4} | {s}\n", .{ number + 1, lines.items[number] });
            }
        }
        std.debug.print("{d:4} | {s}", .{ lines.items.len + 1, current_line.items });
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

    // Add builtins.
    program.declarations.append(.{ .builtin_type = .{ .name = "Nothing" } }) catch return null;
    program.declarations.append(.{ .builtin_type = .{ .name = "Never" } }) catch return null;
    program.declarations.append(.{ .builtin_type = .{ .name = "Int" } }) catch return null;
    { // Bool
        var variants = ArrayList(ast.Variant).init(alloc);
        variants.append(.{ .name = "true", .type_ = null }) catch return null;
        variants.append(.{ .name = "false", .type_ = null }) catch return null;
        program.declarations.append(.{ .enum_ = .{
            .name = "Bool",
            .type_args = ArrayList(ast.Type).init(alloc),
            .variants = variants,
        } }) catch return null;
    }
    { // add(Int, Int)
        const int = .{ .name = "Int", .args = ArrayList(ast.Type).init(alloc) };
        var args = ArrayList(ast.Argument).init(alloc);
        args.append(.{ .name = "a", .type_ = int}) catch return null;
        args.append(.{ .name = "b", .type_ = int}) catch return null;
        program.declarations.append(.{ .fun = .{
            .name = "add",
            .type_args = ArrayList(ast.Type).init(alloc),
            .args = args,
            .return_type = int,
            .is_builtin = true,
            .body = ArrayList(ast.Expression).init(alloc),

        } }) catch return null;
    }

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
                '#' => while (i < self.code.len) : (i += 1) {
                    if (self.code[i] == '\n') {
                        break;
                    }
                },
                else => break :loop,
            }
        }
        if (i >= self.code.len) {
            i = self.code.len;
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
        while (true) {
            self.consume_whitespace();

            if (try self.parse_struct()) |s| {
                try declarations.append(.{ .struct_ = s });
                continue;
            }
            if (try self.parse_enum()) |e| {
                try declarations.append(.{ .enum_ = e });
                continue;
            }
            if (try self.parse_fun()) |fun| {
                try declarations.append(.{ .fun = fun });
                continue;
            }

            break; // Nothing more got parsed.
        }
        self.consume_whitespace();
        if (self.code.len > 0) {
            return error.ExpectedDeclaration;
        }
        return .{ .declarations = declarations };
    }

    fn parse_name(self: *Self) ?ast.Name {
        var i: usize = 0;
        loop: while (true) {
            switch (self.code[i]) {
                'A'...'Z', 'a'...'z', '_' => i += 1,
                '@' => if (i == 0) {
                    i += 1;
                } else {
                    break :loop;
                },
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

    fn parse_type(self: *Self) error{
        OutOfMemory, ExpectedTypeArgument, ExpectedClosingBracket
    }!?ast.Type {
        const name = self.parse_name() orelse return null;
        self.consume_whitespace();
        const type_args = try self.parse_type_args() orelse ArrayList(ast.Type).init(self.alloc);
        return .{ .name = name, .args = type_args };
    }
    fn parse_type_args(self: *Self) !?std.ArrayList(ast.Type) {
        var type_args = std.ArrayList(ast.Type).init(self.alloc);
        self.consume_prefix("[") orelse return null;
        self.consume_whitespace();
        while (true) {
            const arg = try self.parse_type() orelse return error.ExpectedTypeArgument;
            try type_args.append(arg);
            self.consume_whitespace();
            self.consume_prefix(",") orelse break;
            self.consume_whitespace();
        }
        self.consume_prefix("]") orelse return error.ExpectedClosingBracket;
        return type_args;
    }

    fn parse_struct(self: *Self) !?ast.Struct {
        self.consume_keyword("struct") orelse return null;
        self.consume_whitespace();
        const name = self.parse_name() orelse return error.ExpectedNameOfStruct;
        self.consume_whitespace();
        const type_args = try self.parse_type_args() orelse ArrayList(ast.Type).init(self.alloc);
        self.consume_whitespace();
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
        const type_args = try self.parse_type_args() orelse ArrayList(ast.Type).init(self.alloc);
        self.consume_whitespace();
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
        const type_args = try self.parse_type_args() orelse ArrayList(ast.Type).init(self.alloc);
        self.consume_whitespace();
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

        self.consume_whitespace();
        const body = try self.parse_body() orelse return error.ExpectedBody;

        return .{
            .name = name,
            .type_args = type_args,
            .args = args,
            .return_type = return_type,
            .is_builtin = false,
            .body = body,
        };
    }

    fn parse_body(self: *Self) !?ast.Body {
        self.consume_prefix("{") orelse return null;

        var statements = std.ArrayList(ast.Expression).init(self.alloc);
        while (true) {
            self.consume_whitespace();

            if (try self.parse_var()) |var_| {
                try statements.append(.{ .var_ = var_ });
                continue;
            }
            if (try self.parse_return()) |returned| {
                try statements.append(.{ .return_ = returned });
                continue;
            }
            if (try self.parse_expression()) |expr| {
                try statements.append(expr);
                continue;
            }

            break; // Nothing more got parsed.
        }

        self.consume_prefix("}") orelse return error.ExpectedStatementOrClosingBrace;
        return statements;
    }

    fn parse_expression(self: *Self) error{
        ExpectedClosingParenthesis, OutOfMemory, ExpectedMemberOrConstructor,
        ExpectedCondition, ExpectedThenBody, ExpectedElseBody, ExpectedColon,
        ExpectedTypeArgument, ExpectedClosingBracket, ExpectedNameOfVar,
        ExpectedTypeOfVar, ExpectedEquals, ExpectedValueOfVar,
        ExpectedStatementOrClosingBrace, ExpectedClosingBrace,
        ExpectedValueOfField, ExpectedExpression
    }!?ast.Expression {
        var expression: ?ast.Expression = null;
        
        if (try self.parse_if()) |if_| {
            expression = .{ .if_ = if_ };
        } else if (self.parse_number()) |number| {
            expression = .{ .number = number };
        } else if (self.parse_name()) |name| {
            expression = .{ .reference = name };
        } else if (try self.parse_parenthesized()) |expr| {
            expression = expr;
        }

        while (true) {
            self.consume_whitespace();

            if (expression) |expr| {
                if (try self.parse_expression_suffix_type_arged(expr)) |type_arged| {
                    expression = .{ .type_arged = type_arged };
                    continue;
                }
            }

            if (expression) |expr| {
                if (try self.parse_expression_suffix_assign(expr)) |assign| {
                    expression = .{ .assign = assign };
                    continue;
                }
            }

            if (expression) |expr| {
                if (try self.parse_expression_suffix_call(expr)) |call| {
                    expression = .{ .call = call };
                    continue;
                }
            }
            if (expression) |expr| {
                if (try self.parse_expression_suffix_member_or_constructor(expr)) |e| {
                    expression = e;
                    continue;
                }
            }

            break; // Nothing more got parsed.
        }

        return expression;
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

    fn parse_parenthesized(self: *Self) !?ast.Expression {
        self.consume_prefix("(") orelse return null;
        const expr = try self.parse_expression() orelse return error.ExpectedExpression;
        self.consume_prefix(")") orelse return error.ExpectedClosingParenthesis;
        return expr;
    }

    fn parse_expression_suffix_type_arged(self: *Self, current: ast.Expression) !?ast.TypeArged {
        const type_args = try self.parse_type_args() orelse return null;

        const heaped = try self.alloc.create(ast.Expression);
        heaped.* = current;

        return .{ .arged = heaped, .type_args = type_args };
    }

    fn parse_expression_suffix_assign(self: *Self, current: ast.Expression) !?ast.Assign {
        self.consume_prefix("=") orelse return null;
        self.consume_whitespace();
        const value = try self.parse_expression() orelse return error.ExpectedExpression;

        const heaped_to = try self.alloc.create(ast.Expression);
        heaped_to.* = current;
        const heaped_value = try self.alloc.create(ast.Expression);
        heaped_value.* = value;

        return .{ .to = heaped_to, .value = heaped_value };
    }

    fn parse_expression_suffix_call(self: *Self, current: ast.Expression) !?ast.Call {
        self.consume_prefix("(") orelse return null;

        const heaped = try self.alloc.create(ast.Expression);
        heaped.* = current;

        var args = std.ArrayList(ast.Expression).init(self.alloc);
        self.consume_whitespace();
        while (true) {
            const arg = try self.parse_expression() orelse break;
            self.consume_whitespace();
            try args.append(arg);
            self.consume_prefix(",") orelse break;
            self.consume_whitespace();
        }
        self.consume_prefix(")") orelse return error.ExpectedClosingParenthesis;

        return .{ .callee = heaped, .args = args };
    }

    fn parse_expression_suffix_member_or_constructor(self: *Self, current: ast.Expression) !?ast.Expression {
        self.consume_prefix(".") orelse return null;

        const heaped = try self.alloc.create(ast.Expression);
        heaped.* = current;
        
        self.consume_whitespace();
        if (self.parse_name()) |name| {
            return .{ .member = .{ .on = heaped, .member = name }};
        } else if (self.consume_prefix("{")) |_| {
            self.consume_whitespace();

            var fields = std.ArrayList(ast.ConstructionField).init(self.alloc);
            while (true) {
                const name = self.parse_name() orelse break;
                self.consume_whitespace();
                self.consume_prefix("=") orelse return error.ExpectedEquals;
                self.consume_whitespace();
                const value = try self.parse_expression() orelse return error.ExpectedValueOfField;
                try fields.append(.{
                    .name = name,
                    .value = value,
                });
                self.consume_whitespace();
                self.consume_prefix(",") orelse break;
                self.consume_whitespace();
            }
            self.consume_prefix("}") orelse return error.ExpectedClosingBrace;

            return .{
                .struct_construction = .{
                    .type_ = heaped,
                    .fields = fields,
                }
            };
        } else return error.ExpectedMemberOrConstructor;
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
        const heaped = try self.alloc.create(ast.Expression);
        heaped.* = value;

        return .{ .name = name, .type_ = type_, .value = heaped };
    }

    fn parse_return(self: *Self) !?*const ast.Expression {
        self.consume_keyword("return") orelse return null;
        self.consume_whitespace();

        var returned = try self.parse_expression() orelse return error.ExpectedExpression;
        const heaped = try self.alloc.create(ast.Expression);
        heaped.* = returned;

        return heaped;
    }

    fn parse_if(self: *Self) !?ast.If {
        self.consume_keyword("if") orelse return null;
        self.consume_whitespace();

        const condition = try self.parse_expression() orelse return error.ExpectedCondition;
        self.consume_whitespace();
        const heaped = try self.alloc.create(ast.Expression);
        heaped.* = condition;

        const then = try self.parse_body() orelse return error.ExpectedThenBody;
        self.consume_whitespace();

        var else_: ?ast.Body = null;
        if (self.consume_keyword("else")) |_| {
            self.consume_whitespace();
            else_ = try self.parse_body() orelse return error.ExpectedElseBody;
        }

        return .{ .condition = heaped, .then = then, .else_ = else_ };
    }
};
