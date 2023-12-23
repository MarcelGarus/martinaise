const std = @import("std");
const format = std.fmt.format;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const ast = @import("ast.zig");
const string = @import("string.zig");
const String = string.String;
const Str = string.Str;
const Result = @import("result.zig").Result;
const Ty = @import("ty.zig").Ty;
const numbers = @import("numbers.zig");

pub fn parse(alloc: std.mem.Allocator, code: Str, stdlib_size: usize) !Result(ast.Program) {
    var parser = Parser{ .code = code, .alloc = alloc };
    var program = parser.parse_program() catch |err| {
        if (err == error.OutOfMemory) return err;

        var out_buf = String.init(alloc);
        const out = out_buf.writer();

        const error_offset = code.len - parser.code.len;

        var lines = ArrayList(Str).init(alloc);
        var current_line = String.init(alloc);
        var stdlib_lines: ?usize = null;
        var error_offset_in_line: ?usize = null;
        get_lines: for (code, 0..) |c, i| {
            if (i == stdlib_size) stdlib_lines = lines.items.len;
            if (i == error_offset) {
                error_offset_in_line = current_line.items.len;
                for (code[error_offset..]) |c_| switch (c_) {
                    '\n' => {
                        try lines.append(current_line.items);
                        break :get_lines;
                    },
                    else => try current_line.append(c_),
                };
            }
            switch (c) {
                '\n' => {
                    try lines.append(current_line.items);
                    current_line = String.init(alloc);
                },
                else => |a| try current_line.append(a),
            }
        }

        const num_lines_to_display = @min(lines.items.len, 4);
        const start_line = lines.items.len - num_lines_to_display + 1;
        for (lines.items[start_line..], start_line..) |line, line_number| {
            var number = line_number + 1;
            if (stdlib_lines) |stdlines| if (line_number > stdlines) {
                number -= stdlines + 1;
            };
            try format(out, "{d:4} | {s}\n", .{ number, line });
        }

        try format(out, "       ", .{});
        for (0..error_offset_in_line.?) |_|
            try format(out, " ", .{});
        try format(out, "^\n", .{});
        try format(out, " ", .{});
        for (0..error_offset_in_line.?) |_|
            try format(out, " ", .{});
        try format(out, "{}\n", .{err});

        return .{ .err = out_buf.items };
    };

    // Add builtins.

    { // struct &[T] { *: T }
        var ty_args = ArrayList(Str).init(alloc);
        try ty_args.append("T");
        const t: Ty = .{ .name = "T", .args = ArrayList(Ty).init(alloc) };
        var fields = ArrayList(ast.Field).init(alloc);
        try fields.append(.{ .name = "*", .ty = t });
        try program.defs.append(.{ .struct_ = .{ .name = "&", .ty_args = ty_args, .fields = fields } });
    }

    // Int stuff.
    for (numbers.all_int_configs()) |config| {
        try program.defs.append(.{ .builtin_ty = try numbers.int_ty_name(alloc, config) });
        const ty = try numbers.int_ty(alloc, config);

        var two_args = ArrayList(ast.Argument).init(alloc);
        try two_args.append(.{ .name = "a", .ty = ty });
        try two_args.append(.{ .name = "b", .ty = ty });

        program.add_builtin_fun(alloc, "add", null, two_args, ty);
        program.add_builtin_fun(alloc, "subtract", null, two_args, ty);
        program.add_builtin_fun(alloc, "multiply", null, two_args, ty);
        program.add_builtin_fun(alloc, "divide", null, two_args, ty);
        program.add_builtin_fun(alloc, "modulo", null, two_args, ty);
        program.add_builtin_fun(alloc, "compare_to", null, two_args, .{ .name = "Ordering", .args = ArrayList(Ty).init(alloc) });
        // program.add_builtin_fun(alloc, "shiftLeft", two_args, ty);
        // program.add_builtin_fun(alloc, "shiftRight", two_args, ty);
        // program.add_builtin_fun(alloc, "bitLength", two_args, ty);
        // program.add_builtin_fun(alloc, "and", two_args, ty);
        // program.add_builtin_fun(alloc, "or", two_args, ty);
        // program.add_builtin_fun(alloc, "xor", two_args, ty);

        // Conversion functions
        for (numbers.all_int_configs()) |target_config| {
            // if (config == target_config) {
            if (config.signedness == target_config.signedness and config.bits == target_config.bits) {
                continue;
            }

            var fun_name = ArrayList(u8).init(alloc);
            try std.fmt.format(fun_name.writer(), "to_{s}", .{try numbers.int_ty_name(alloc, target_config)});

            var args = ArrayList(ast.Argument).init(alloc);
            try args.append(.{ .name = "i", .ty = ty });

            program.add_builtin_fun(alloc, fun_name.items, null, args, try numbers.int_ty(alloc, target_config));
        }
    }

    return .{ .ok = program };
}

const Parser = struct {
    code: Str,
    alloc: std.mem.Allocator,

    const Self = @This();

    fn consume_whitespace(self: *Self) void {
        var i: usize = 0;
        loop: while (i < self.code.len) : (i += 1) {
            switch (self.code[i]) {
                ' ', '\t', '\n' => {},
                '|' => while (i < self.code.len) : (i += 1) {
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

    fn consume_prefix(self: *Self, prefix: Str) ?void {
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
    fn consume_keyword(self: *Self, keyword: Str) ?void {
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
        var defs = ArrayList(ast.Def).init(self.alloc);
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

    fn parse_name(self: *Self) ?Str {
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

    fn parse_type(self: *Self) error{ OutOfMemory, ExpectedTypeArgument, ExpectedClosingBracket, ExpectedType }!?Ty {
        if (self.consume_prefix("&")) |_| {
            var args = ArrayList(Ty).init(self.alloc);
            try args.append(try self.parse_type() orelse return error.ExpectedType);
            return .{ .name = "&", .args = args };
        }

        const name = self.parse_name() orelse return null;
        self.consume_whitespace();
        const type_args = try self.parse_type_args() orelse ArrayList(Ty).init(self.alloc);
        return .{ .name = name, .args = type_args };
    }
    fn parse_type_args(self: *Self) !?ArrayList(Ty) {
        var type_args = ArrayList(Ty).init(self.alloc);
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
    fn parse_type_params(self: *Self) !?ArrayList(Str) {
        var type_params = ArrayList(Str).init(self.alloc);
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
        const type_args = try self.parse_type_params() orelse ArrayList(Str).init(self.alloc);
        self.consume_whitespace();
        self.consume_prefix("{") orelse return error.ExpectedOpeningBrace;
        self.consume_whitespace();

        var fields = ArrayList(ast.Field).init(self.alloc);
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

        self.consume_whitespace();
        self.consume_prefix("}") orelse return error.ExpectedClosingBrace;

        return ast.Struct{ .name = name, .ty_args = type_args, .fields = fields };
    }

    fn parse_enum(self: *Self) !?ast.Enum {
        self.consume_keyword("enum") orelse return null;
        self.consume_whitespace();
        const name = self.parse_name() orelse return error.ExpectedNameOfEnum;
        self.consume_whitespace();
        const type_args = try self.parse_type_params() orelse ArrayList(Str).init(self.alloc);
        self.consume_whitespace();
        self.consume_prefix("{") orelse return error.ExpectedOpeningBrace;
        self.consume_whitespace();

        var variants = ArrayList(ast.Variant).init(self.alloc);
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
        const type_args = try self.parse_type_params() orelse ArrayList(Str).init(self.alloc);
        self.consume_whitespace();
        var args = ArrayList(ast.Argument).init(self.alloc);
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

        var is_builtin = false;
        const body = get_body: {
            if (self.consume_prefix("{ ... }")) |_| {
                is_builtin = true;
                break :get_body ArrayList(ast.Expr).init(self.alloc);
            } else {
                break :get_body try self.parse_body() orelse return error.ExpectedBody;
            }
        };

        return .{
            .name = name,
            .ty_args = type_args,
            .args = args,
            .returns = return_type,
            .is_builtin = is_builtin,
            .body = body,
        };
    }

    fn parse_body(self: *Self) !?ast.Body {
        self.consume_prefix("{") orelse return null;

        var statements = ArrayList(ast.Expr).init(self.alloc);
        while (true) {
            self.consume_whitespace();

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
        ExpectedClosingParenthesis,
        OutOfMemory,
        ExpectedMemberOrConstructor,
        ExpectedCondition,
        ExpectedThen,
        ExpectedThenExpression,
        ExpectedElseExpression,
        ExpectedVariant,
        ExpectedCaseExpression,
        ExpectedColon,
        ExpectedTypeArgument,
        ExpectedClosingBracket,
        ExpectedNameOfVar,
        ExpectedTypeOfVar,
        ExpectedEquals,
        ExpectedValueOfVar,
        ExpectedStatementOrClosingBrace,
        ExpectedClosingBrace,
        ExpectedValueOfField,
        ExpectedExpression,
        ExpectedOpeningBrace,
        ExpectedBody,
        ExpectedBinding,
        ExpectedSignedness,
        ExpectedBits,
        InvalidBits,
        ExpectedUnderscore,
        ExpectedChar,
        ExpectedType,
        ExpectedDo,
        ExpectedLoopExpr,
        ExpectedAlternativeExpression,
        ExpectedIn,
        ExpectedIterationVariable,
        ExpectedIter,
    }!?ast.Expr {
        var expression: ?ast.Expr = null;

        if (try self.parse_var()) |var_| {
            expression = .{ .var_ = var_ };
        } else if (try self.parse_return()) |returned| {
            expression = .{ .return_ = returned };
        } else if (try self.parse_if()) |if_| {
            expression = .{ .if_ = if_ };
        } else if (try self.parse_switch()) |switch_| {
            expression = .{ .switch_ = switch_ };
        } else if (try self.parse_loop()) |loop| {
            const heaped = try self.alloc.create(ast.Expr);
            heaped.* = loop;
            expression = .{ .loop = heaped };
        } else if (try self.parse_for()) |for_| {
            expression = .{ .for_ = for_ };
        } else if (try self.parse_int()) |int| {
            expression = .{ .int = int };
        } else if (try self.parse_char()) |c| {
            expression = .{ .int = .{ .value = c, .signedness = .unsigned, .bits = 8 } };
        } else if (try self.parse_string()) |s| {
            expression = .{ .string = s };
        } else if (try self.parse_ampersanded()) |amp| {
            const heaped = try self.alloc.create(ast.Expr);
            heaped.* = amp;
            expression = .{ .ampersanded = heaped };
        } else if (self.parse_name()) |name| {
            expression = .{ .ref = name };
        } else if (try self.parse_body()) |body| {
            expression = .{ .body = body };
        }

        while (true) {
            self.consume_whitespace();

            if (expression) |expr| {
                if (try self.parse_expression_suffix_type_arged(expr)) |type_arged| {
                    expression = .{ .ty_arged = type_arged };
                    continue;
                }
                if (try self.parse_expression_suffix_assign(expr)) |assign| {
                    expression = .{ .assign = assign };
                    continue;
                }
                if (try self.parse_expression_suffix_call(expr)) |call| {
                    expression = .{ .call = call };
                    continue;
                }
                if (try self.parse_expression_suffix_member_or_constructor(expr)) |e| {
                    expression = e;
                    continue;
                }
                if (try self.parse_expression_suffix_orelse(expr)) |e| {
                    expression = .{ .orelse_ = e };
                    continue;
                }
            }

            break; // Nothing more got parsed.
        }

        return expression;
    }

    fn parse_int(self: *Self) !?ast.Int {
        const value = self.parse_digits() orelse return null;
        self.consume_prefix("_") orelse return .{
            .value = value,
            .signedness = .unsigned,
            .bits = 64,
        };
        const signedness: numbers.Signedness = sign: {
            if (self.consume_prefix("I")) |_| {
                break :sign .signed;
            }
            if (self.consume_prefix("U")) |_| {
                break :sign .unsigned;
            }
            return error.ExpectedSignedness;
        };
        const bits_ = self.parse_digits() orelse return error.ExpectedBits;
        const bits: numbers.Bits = @intCast(bits_);
        if (std.mem.count(u8, &numbers.all_bits, &[_]numbers.Bits{bits}) == 0) {
            return error.InvalidBits;
        }
        return .{ .value = value, .signedness = signedness, .bits = bits };
    }
    fn parse_digits(self: *Self) ?i128 {
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

    fn parse_char(self: *Self) !?u8 {
        self.consume_prefix("'") orelse return null;
        if (self.code.len == 0) return error.ExpectedChar;
        const c = self.code[0];
        self.code = self.code[1..];
        return c;
    }

    fn parse_string(self: *Self) !?Str {
        self.consume_prefix("\"") orelse return null;
        var i: usize = 0;
        while (self.code[i] != '\"') {
            i += 1;
        }
        const str = self.code[0..i];
        self.code = self.code[i + 1 ..];
        return str;
    }

    fn parse_ampersanded(self: *Self) !?ast.Expr {
        self.consume_prefix("&") orelse return null;
        const expr = try self.parse_expression() orelse return error.ExpectedExpression;
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

        var args = ArrayList(ast.Expr).init(self.alloc);
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
        if (self.consume_prefix("*")) |_| return .{ .member = .{ .of = heaped, .name = "*" } };
        if (self.consume_prefix("&")) |_| return .{ .ampersanded = heaped };
        if (self.parse_name()) |name| return .{ .member = .{ .of = heaped, .name = name } };
        if (self.consume_prefix("{")) |_| {
            self.consume_whitespace();

            var fields = ArrayList(ast.StructCreationField).init(self.alloc);
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

            return .{ .struct_creation = .{ .ty = heaped, .fields = fields } };
        }
        return error.ExpectedMemberOrConstructor;
    }

    fn parse_expression_suffix_orelse(self: *Self, current: ast.Expr) !?ast.Orelse {
        self.consume_keyword("orelse") orelse return null;
        self.consume_whitespace();

        const heaped = try self.alloc.create(ast.Expr);
        heaped.* = current;

        const alternative = try self.alloc.create(ast.Expr);
        alternative.* = try self.parse_expression() orelse return error.ExpectedAlternativeExpression;

        return .{ .primary = heaped, .alternative = alternative };
    }

    fn parse_var(self: *Self) !?ast.Var {
        self.consume_keyword("var") orelse return null;
        self.consume_whitespace();

        const name = self.parse_name() orelse return error.ExpectedNameOfVar;
        self.consume_whitespace();

        self.consume_prefix("=") orelse return error.ExpectedEquals;
        self.consume_whitespace();

        const value = try self.parse_expression() orelse return error.ExpectedValueOfVar;
        const heaped = try self.alloc.create(ast.Expr);
        heaped.* = value;

        return .{ .name = name, .value = heaped };
    }

    fn parse_return(self: *Self) !?*const ast.Expr {
        self.consume_keyword("return") orelse return null;
        self.consume_whitespace();

        const returned = try self.parse_expression() orelse return error.ExpectedExpression;
        const heaped = try self.alloc.create(ast.Expr);
        heaped.* = returned;

        return heaped;
    }

    fn parse_if(self: *Self) !?ast.If {
        self.consume_keyword("if") orelse return null;
        self.consume_whitespace();

        const condition = try self.alloc.create(ast.Expr);
        condition.* = try self.parse_expression() orelse return error.ExpectedCondition;
        self.consume_whitespace();

        self.consume_keyword("then") orelse return error.ExpectedThen;
        self.consume_whitespace();

        const then = try self.alloc.create(ast.Expr);
        then.* = try self.parse_expression() orelse return error.ExpectedThenExpression;
        self.consume_whitespace();

        var else_: ?*ast.Expr = null;
        if (self.consume_keyword("else")) |_| {
            self.consume_whitespace();
            else_ = try self.alloc.create(ast.Expr);
            else_.?.* = try self.parse_expression() orelse return error.ExpectedElseExpression;
        }

        return .{ .condition = condition, .then = then, .else_ = else_ };
    }

    fn parse_switch(self: *Self) !?ast.Switch {
        self.consume_keyword("switch") orelse return null;
        self.consume_whitespace();

        const value = try self.alloc.create(ast.Expr);
        value.* = try self.parse_expression() orelse return error.ExpectedExpression;
        self.consume_whitespace();

        var cases = ArrayList(ast.Case).init(self.alloc);
        while (true) {
            self.consume_keyword("case") orelse break;
            self.consume_whitespace();

            const variant = self.parse_name() orelse return error.ExpectedVariant;
            self.consume_whitespace();

            var binding: ?Str = null;
            if (self.consume_prefix("(")) |_| {
                self.consume_whitespace();
                binding = self.parse_name() orelse return error.ExpectedBinding;
                self.consume_whitespace();
                self.consume_prefix(")") orelse return error.ExpectedClosingParenthesis;
                self.consume_whitespace();
            }

            const then = try self.alloc.create(ast.Expr);
            then.* = try self.parse_expression() orelse return error.ExpectedCaseExpression;
            self.consume_whitespace();

            try cases.append(.{ .variant = variant, .binding = binding, .then = then });
        }

        return .{ .value = value, .cases = cases };
    }

    fn parse_loop(self: *Self) !?ast.Expr {
        self.consume_keyword("loop") orelse return null;
        self.consume_whitespace();
        return try self.parse_expression() orelse return error.ExpectedLoopExpr;
    }

    fn parse_for(self: *Self) !?ast.For {
        self.consume_keyword("for") orelse return null;
        self.consume_whitespace();
        const iter_var = self.parse_name() orelse return error.ExpectedIterationVariable;
        self.consume_whitespace();
        self.consume_keyword("in") orelse return error.ExpectedIn;
        self.consume_whitespace();
        const iter = try self.alloc.create(ast.Expr);
        iter.* = try self.parse_expression() orelse return error.ExpectedIter;
        self.consume_whitespace();
        self.consume_keyword("do") orelse return error.ExpectedDo;
        self.consume_whitespace();
        const expr = try self.alloc.create(ast.Expr);
        expr.* = try self.parse_expression() orelse return error.ExpectedLoopExpr;
        return .{ .iter_var = iter_var, .iter = iter, .expr = expr };
    }
};
