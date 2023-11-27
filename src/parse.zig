const std = @import("std");
const ast = @import("ast.zig");
const ArrayList = std.ArrayList;
const Name = @import("ty.zig").Name;
const Ty = @import("ty.zig").Ty;
const utils = @import("utils.zig");

pub fn parse(alloc: std.mem.Allocator, code: []u8) !?ast.Program {
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

    { // addressOf[T](T): U64
        const t: Ty = .{ .name = "T", .args = ArrayList(Ty).init(alloc) };
        const u64_: Ty = .{ .name = "U64", .args = ArrayList(Ty).init(alloc) };
        var ty_args = ArrayList(Name).init(alloc);
        try ty_args.append("T");
        var args = ArrayList(ast.Argument).init(alloc);
        try args.append(.{ .name = "a", .ty = t});
        program.add_builtin_fun(alloc, "addressOf", ty_args, args, u64_);
    }

    // Int stuff.
    for (utils.all_int_configs()) |config| {
        try program.defs.append(.{ .builtin_ty = try utils.int_ty_name(alloc, config) });
        const ty = try utils.int_ty(alloc, config);

        var two_args = ArrayList(ast.Argument).init(alloc);
        try two_args.append(.{ .name = "a", .ty = ty});
        try two_args.append(.{ .name = "b", .ty = ty});

        program.add_builtin_fun(alloc, "add", null, two_args, ty);
        // program.add_builtin_fun(alloc, "subtract", two_args, ty);
        // program.add_builtin_fun(alloc, "multiply", two_args, ty);
        // program.add_builtin_fun(alloc, "divide", two_args, ty);
        // program.add_builtin_fun(alloc, "modulo", two_args, ty);
        // program.add_builtin_fun(alloc, "compareTo", two_args, ty);
        // program.add_builtin_fun(alloc, "shiftLeft", two_args, ty);
        // program.add_builtin_fun(alloc, "shiftRight", two_args, ty);
        // program.add_builtin_fun(alloc, "bitLength", two_args, ty);
        // program.add_builtin_fun(alloc, "and", two_args, ty);
        // program.add_builtin_fun(alloc, "or", two_args, ty);
        // program.add_builtin_fun(alloc, "xor", two_args, ty);

        // Conversion functions
        for (utils.all_int_configs()) |target_config| {
            // if (config == target_config) {
            if (config.signedness == target_config.signedness and config.bits == target_config.bits) {
                continue;
            }

            var fun_name = ArrayList(u8).init(alloc);
            try std.fmt.format(fun_name.writer(), "to{s}", .{try utils.int_ty_name(alloc, target_config)});

            var args = ArrayList(ast.Argument).init(alloc);
            try args.append(.{ .name = "i", .ty = ty });

            program.add_builtin_fun(alloc, fun_name.items, null, args, try utils.int_ty(alloc, target_config));
        }
    }

    { // print(U8)
        const u8_ = .{ .name = "U8", .args = ArrayList(Ty).init(alloc) };
        const nothing = .{ .name = "Nothing", .args = ArrayList(Ty).init(alloc) };
        var args = ArrayList(ast.Argument).init(alloc);
        try args.append(.{ .name = "c", .ty = u8_});
        program.add_builtin_fun(alloc, "print", null, args, nothing);
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
        var defs = std.ArrayList(ast.Def).init(self.alloc);
        while (true) {
            self.consume_whitespace();

            if (try self.parse_struct()) |s| {
                try defs.append(.{ .struct_ = s });
                continue;
            }
            if (try self.parse_enum()) |e| {
                try defs.append(.{ .enum_ = e });
                continue;
            }
            if (try self.parse_fun()) |fun| {
                try defs.append(.{ .fun = fun });
                continue;
            }

            break; // Nothing more got parsed.
        }
        self.consume_whitespace();
        if (self.code.len > 0) {
            return error.ExpectedDefinition;
        }
        return .{ .defs = defs };
    }

    fn parse_name(self: *Self) ?Name {
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
    }!?Ty {
        const name = self.parse_name() orelse return null;
        self.consume_whitespace();
        const type_args = try self.parse_type_args() orelse ArrayList(Ty).init(self.alloc);
        return .{ .name = name, .args = type_args };
    }
    fn parse_type_args(self: *Self) !?std.ArrayList(Ty) {
        var type_args = std.ArrayList(Ty).init(self.alloc);
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
    fn parse_type_params(self: *Self) !?std.ArrayList(Name) {
        var type_params = std.ArrayList(Name).init(self.alloc);
        self.consume_prefix("[") orelse return null;
        self.consume_whitespace();
        while (true) {
            const arg = self.parse_name() orelse return error.ExpectedTypeArgument;
            try type_params.append(arg);
            self.consume_whitespace();
            self.consume_prefix(",") orelse break;
            self.consume_whitespace();
        }
        self.consume_prefix("]") orelse return error.ExpectedClosingBracket;
        return type_params;
    }

    fn parse_struct(self: *Self) !?ast.Struct {
        self.consume_keyword("struct") orelse return null;
        self.consume_whitespace();
        const name = self.parse_name() orelse return error.ExpectedNameOfStruct;
        self.consume_whitespace();
        const type_args = try self.parse_type_params() orelse ArrayList(Name).init(self.alloc);
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
            try fields.append(.{ .name = field_name, .ty = field_type });
            self.consume_prefix(",") orelse break;
            self.consume_whitespace();
        }

        self.consume_prefix("}") orelse return error.ExpectedClosingBrace;

        return ast.Struct{ .name = name, .ty_args = type_args, .fields = fields };
    }

    fn parse_enum(self: *Self) !?ast.Enum {
        self.consume_keyword("enum") orelse return null;
        self.consume_whitespace();
        const name = self.parse_name() orelse return error.ExpectedNameOfEnum;
        self.consume_whitespace();
        const type_args = try self.parse_type_params() orelse ArrayList(Name).init(self.alloc);
        self.consume_whitespace();
        self.consume_prefix("{") orelse return error.ExpectedOpeningBrace;
        self.consume_whitespace();

        var variants = std.ArrayList(ast.Variant).init(self.alloc);
        while (true) {
            const variant_name = self.parse_name() orelse break;
            var variant_type: ?Ty = null;

            self.consume_whitespace();
            if (self.consume_prefix(":")) |_| {
                self.consume_whitespace();
                variant_type = try self.parse_type();
                self.consume_whitespace();
            }
            try variants.append(.{ .name = variant_name, .ty = variant_type });
            self.consume_prefix(",") orelse break;
            self.consume_whitespace();
        }

        self.consume_prefix("}") orelse return error.ExpectedClosingBrace;

        return ast.Enum{ .name = name, .ty_args = type_args, .variants = variants };
    }

    fn parse_fun(self: *Self) !?ast.Fun {
        self.consume_keyword("fun") orelse return null;
        self.consume_whitespace();
        const name = self.parse_name() orelse return error.ExpectedNameOfFunction;
        self.consume_whitespace();
        const type_args = try self.parse_type_params() orelse ArrayList(Name).init(self.alloc);
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
            try args.append(.{ .name = arg_name, .ty = arg_type });
            self.consume_prefix(",") orelse break;
            self.consume_whitespace();
        }
        self.consume_prefix(")") orelse return error.ExpectedClosingParenthesis;
        self.consume_whitespace();

        var return_type: ?Ty = null;
        parse_return_type: {
            self.consume_prefix(":") orelse break :parse_return_type;
            self.consume_whitespace();
            return_type = try self.parse_type() orelse return error.ExpectedReturnType;
        }

        self.consume_whitespace();
        const body = try self.parse_body() orelse return error.ExpectedBody;

        return .{
            .name = name,
            .ty_args = type_args,
            .args = args,
            .returns = return_type,
            .is_builtin = false,
            .body = body,
        };
    }

    fn parse_body(self: *Self) !?ast.Body {
        self.consume_prefix("{") orelse return null;

        var statements = std.ArrayList(ast.Expr).init(self.alloc);
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
    }!?ast.Expr {
        var expression: ?ast.Expr = null;
        
        if (try self.parse_if()) |if_| {
            expression = .{ .if_ = if_ };
        } else if (self.parse_number()) |number| {
            expression = .{ .num = number };
        } else if (self.parse_name()) |name| {
            expression = .{ .ref = name };
        } else if (try self.parse_parenthesized()) |expr| {
            expression = expr;
        }

        while (true) {
            self.consume_whitespace();

            if (expression) |expr| {
                if (try self.parse_expression_suffix_type_arged(expr)) |type_arged| {
                    expression = .{ .ty_arged = type_arged };
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

    fn parse_parenthesized(self: *Self) !?ast.Expr {
        self.consume_prefix("(") orelse return null;
        const expr = try self.parse_expression() orelse return error.ExpectedExpression;
        self.consume_prefix(")") orelse return error.ExpectedClosingParenthesis;
        return expr;
    }

    fn parse_expression_suffix_type_arged(self: *Self, current: ast.Expr) !?ast.TyArged {
        const type_args = try self.parse_type_args() orelse return null;

        const heaped = try self.alloc.create(ast.Expr);
        heaped.* = current;

        return .{ .arged = heaped, .ty_args = type_args };
    }

    fn parse_expression_suffix_assign(self: *Self, current: ast.Expr) !?ast.Assign {
        self.consume_prefix("=") orelse return null;
        self.consume_whitespace();
        const value = try self.parse_expression() orelse return error.ExpectedExpression;

        const heaped_to = try self.alloc.create(ast.Expr);
        heaped_to.* = current;
        const heaped_value = try self.alloc.create(ast.Expr);
        heaped_value.* = value;

        return .{ .to = heaped_to, .value = heaped_value };
    }

    fn parse_expression_suffix_call(self: *Self, current: ast.Expr) !?ast.Call {
        self.consume_prefix("(") orelse return null;

        const heaped = try self.alloc.create(ast.Expr);
        heaped.* = current;

        var args = std.ArrayList(ast.Expr).init(self.alloc);
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

    fn parse_expression_suffix_member_or_constructor(self: *Self, current: ast.Expr) !?ast.Expr {
        self.consume_prefix(".") orelse return null;

        const heaped = try self.alloc.create(ast.Expr);
        heaped.* = current;
        
        self.consume_whitespace();
        if (self.parse_name()) |name| {
            return .{ .member = .{ .of = heaped, .name = name }};
        } else if (self.consume_prefix("{")) |_| {
            self.consume_whitespace();

            var fields = std.ArrayList(ast.ConstructionField).init(self.alloc);
            while (true) {
                const name = self.parse_name() orelse break;
                self.consume_whitespace();
                self.consume_prefix("=") orelse return error.ExpectedEquals;
                self.consume_whitespace();
                const value = try self.parse_expression() orelse return error.ExpectedValueOfField;
                try fields.append(.{ .name = name, .value = value });
                self.consume_whitespace();
                self.consume_prefix(",") orelse break;
                self.consume_whitespace();
            }
            self.consume_prefix("}") orelse return error.ExpectedClosingBrace;

            return .{
                .struct_construction = .{ .ty = heaped, .fields = fields }
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

        const ty = try self.parse_type() orelse return error.ExpectedTypeOfVar;

        self.consume_whitespace();
        self.consume_prefix("=") orelse return error.ExpectedEquals;
        self.consume_whitespace();

        var value = try self.parse_expression() orelse return error.ExpectedValueOfVar;
        const heaped = try self.alloc.create(ast.Expr);
        heaped.* = value;

        return .{ .name = name, .ty = ty, .value = heaped };
    }

    fn parse_return(self: *Self) !?*const ast.Expr {
        self.consume_keyword("return") orelse return null;
        self.consume_whitespace();

        var returned = try self.parse_expression() orelse return error.ExpectedExpression;
        const heaped = try self.alloc.create(ast.Expr);
        heaped.* = returned;

        return heaped;
    }

    fn parse_if(self: *Self) !?ast.If {
        self.consume_keyword("if") orelse return null;
        self.consume_whitespace();

        const condition = try self.parse_expression() orelse return error.ExpectedCondition;
        self.consume_whitespace();
        const heaped = try self.alloc.create(ast.Expr);
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
