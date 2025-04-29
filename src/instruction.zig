const std = @import("std");
const Register = @import("register.zig").Register;

pub fn next(t: anytype, read: *const fn (@TypeOf(t)) ?u8) ?Op {
    if (read(t)) |byte| {
        return switch (byte) {
            0x00 => .nop,

            0x80 => Add.init(.b),
            0x81 => Add.init(.c),
            0x82 => Add.init(.d),
            0x83 => Add.init(.e),
            0x84 => Add.init(.h),
            0x85 => Add.init(.l),
            0x86 => Add.init(.ahl),
            0x87 => Add.init(.a),

            0x90 => Sub.init(.b),
            0x91 => Sub.init(.c),
            0x92 => Sub.init(.d),
            0x93 => Sub.init(.e),
            0x94 => Sub.init(.h),
            0x95 => Sub.init(.l),
            0x96 => Sub.init(.ahl),
            0x97 => Sub.init(.a),

            0xA0 => And.init(.b),
            0xA1 => And.init(.c),
            0xA2 => And.init(.d),
            0xA3 => And.init(.e),
            0xA4 => And.init(.h),
            0xA5 => And.init(.l),
            0xA6 => And.init(.ahl),
            0xA7 => And.init(.a),

            0xB0 => Or.init(.b),
            0xB1 => Or.init(.c),
            0xB2 => Or.init(.d),
            0xB3 => Or.init(.e),
            0xB4 => Or.init(.h),
            0xB5 => Or.init(.l),
            0xB6 => Or.init(.ahl),
            0xB7 => Or.init(.a),

            0xC6 => Add.init(.{ .d8 = read(t).? }),
            0xD6 => Sub.init(.{ .d8 = read(t).? }),
            0xE6 => And.init(.{ .d8 = read(t).? }),
            0xF6 => Or.init(.{ .d8 = read(t).? }),

            else => @panic("not implemented"),
        };
    } else {
        return null;
    }
}

/// Test utility
const Seq = struct {
    index: usize = 0,
    data: []const u8,

    fn read(self: *@This()) ?u8 {
        if (self.index >= self.data.len) {
            return null;
        } else {
            const value = self.data[self.index];
            self.index += 1;
            return value;
        }
    }
};

test "next" {
    var seq = Seq{ .data = &.{0} };
    try std.testing.expectEqual(
        .nop,
        next(&seq, Seq.read).?,
    );

    seq = Seq{ .data = &.{ 0xC6, 0x01 } };
    try std.testing.expectEqual(
        Add.init(.{ .d8 = 1 }),
        next(&seq, Seq.read).?,
    );
    try std.testing.expectEqual(
        null,
        next(&seq, Seq.read),
    );
}

pub const Op = union(enum) {
    // CPU control
    nop,
    stop,
    halt,
    di,
    ei,
    daa,
    scf,
    cpl,
    ccf,

    // 8bit arithmetic
    add: Add,
    sub: Sub,
    and_: And,
    or_: Or,

    // 8bit transfer
    ld: Load,

    // 16bit arithmetic

    // 16bit transfer

    // jump

    // call and reeturn

    // rotate shift

    // bit operation
};

pub const Add = struct {
    right: Operand,

    pub const Operand = union(enum) {
        a,
        b,
        c,
        d,
        e,
        h,
        l,
        ahl,
        d8: u8,
    };

    pub fn init(right: Operand) Op {
        return .{
            .add = .{ .right = right },
        };
    }
};

pub const Sub = struct {
    right: Operand,

    pub const Operand = union(enum) {
        a,
        b,
        c,
        d,
        e,
        h,
        l,
        ahl,
        d8: u8,
    };

    pub fn init(right: Operand) Op {
        return .{
            .sub = .{ .right = right },
        };
    }
};

pub const And = struct {
    right: Operand,

    pub const Operand = union(enum) {
        a,
        b,
        c,
        d,
        e,
        h,
        l,
        ahl,
        d8: u8,
    };

    pub fn init(right: Operand) Op {
        return .{
            .and_ = .{ .right = right },
        };
    }
};

pub const Or = struct {
    right: Operand,

    pub const Operand = union(enum) {
        a,
        b,
        c,
        d,
        e,
        h,
        l,
        ahl,
        d8: u8,
    };

    pub fn init(right: Operand) Op {
        return .{
            .or_ = .{ .right = right },
        };
    }
};

pub const Load = struct {
    left: Operand,
    right: Operand,

    pub const Operand = union(enum) {
        d8: u8,
        a8: u8,
        a16: u16,
        reg: Register,
        reg_address: Register,
        hl_incr_address,
        hl_decr_address,
    };
};
