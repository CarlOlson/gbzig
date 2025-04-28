const std = @import("std");
const rl = @import("raylib");

const Register = @import("register.zig").Register;
const Instruction = @import("instruction.zig").T;

const clockHz = 2 ** 22;

const Flag = enum(u8) {
    z = 7, // zero
    n = 6, // subtraction
    h = 5, // half-carry
    c = 4, // carry

    pub fn mask(comptime self: @This()) u8 {
        return 1 << @intFromEnum(self);
    }
};

const FlagS = struct {
    zero: bool = false,
    subtract: bool = false,
    half_carry: bool = false,
    carry: bool = false,
};

const Cpu = struct {
    a: u8 = 0,
    b: u8 = 0,
    c: u8 = 0,
    d: u8 = 0,
    e: u8 = 0,
    f: u8 = 0,
    h: u8 = 0,
    l: u8 = 0,
    pc: u16 = 0, // program counter
    sp: u16 = 0, // stack pointer
    ir: u8 = 0, // instruction regiester
    ie: u8 = 0, // interrupt enable

    pub const Init = struct {
        a: u8 = 0,
        b: u8 = 0,
        c: u8 = 0,
        d: u8 = 0,
        e: u8 = 0,
        // f: u8 = 0,
        h: u8 = 0,
        l: u8 = 0,
        zero: bool = false,
        subtract: bool = false,
        half_carry: bool = false,
        carry: bool = false,
    };

    pub fn init(i: Init) @This() {
        var self: @This() = .{
            .a = i.a,
            .b = i.b,
            .c = i.c,
            .d = i.d,
            .e = i.e,
            .h = i.h,
            .l = i.l,
        };

        self.setFlag(.z, i.zero);
        self.setFlag(.n, i.subtract);
        self.setFlag(.h, i.half_carry);
        self.setFlag(.c, i.carry);

        return self;
    }

    pub fn reset(self: *@This()) void {
        self.a = 0;
        self.b = 0;
        self.c = 0;
        self.d = 0;
        self.e = 0;
        self.f = 0;
        self.h = 0;
        self.l = 0;
    }

    pub inline fn getFlag(self: *@This(), comptime flag: Flag) bool {
        return (self.f & flag.mask()) > 0;
    }

    /// Set a flag while retaining the value of others.
    pub inline fn setFlag(self: *@This(), comptime flag: Flag, value: bool) void {
        if (value) {
            self.f = self.f | flag.mask();
        } else {
            self.f = self.f & ~flag.mask();
        }
    }

    /// Set all flags at once.
    pub fn setFlags(self: *@This(), flags: FlagS) void {
        self.f =
            (if (flags.zero) Flag.z.mask() else 0) |
            (if (flags.subtract) Flag.n.mask() else 0) |
            (if (flags.half_carry) Flag.h.mask() else 0) |
            (if (flags.carry) Flag.c.mask() else 0);
    }

    pub inline fn get(self: *@This(), comptime reg: Register) Register.typeOf(reg) {
        return switch (reg) {
            .a => self.a,
            .b => self.b,
            .c => self.c,
            .d => self.d,
            .e => self.e,
            .f => self.f,
            .h => self.h,
            .l => self.l,
            .af => (@as(u16, self.a) << 8) | (@as(u16, self.f) & 0xF0),
            .bc => (@as(u16, self.b) << 8) | @as(u16, self.c),
            .de => (@as(u16, self.d) << 8) | @as(u16, self.e),
            .hl => (@as(u16, self.h) << 8) | @as(u16, self.l),
        };
    }

    pub inline fn set(self: *@This(), comptime reg: Register, value: Register.typeOf(reg)) void {
        switch (reg) {
            .a => self.a = value,
            .b => self.b = value,
            .c => self.c = value,
            .d => self.d = value,
            .e => self.e = value,
            .f => self.f = value,
            .h => self.h = value,
            .l => self.l = value,
            .af => {
                self.a = @intCast((value & 0xFF00) >> 8);
                self.f = @intCast(value & 0xF0);
            },
            .bc => {
                self.b = @intCast((value & 0xFF00) >> 8);
                self.c = @intCast(value & 0xFF);
            },
            .de => {
                self.d = @intCast((value & 0xFF00) >> 8);
                self.e = @intCast(value & 0xFF);
            },
            .hl => {
                self.h = @intCast((value & 0xFF00) >> 8);
                self.l = @intCast(value & 0xFF);
            },
        }
    }

    pub fn add(self: *@This(), value: u8) void {
        const reg = self.get(.a);
        const result, const overflow = @addWithOverflow(reg, value);

        self.set(.a, result);
        self.setFlags(.{
            .zero = result == 0,
            .subtract = false,
            .half_carry = (reg & 0xF) + (value & 0xF) > 0xF,
            .carry = overflow > 0,
        });
    }

    pub fn sub(self: *@This(), value: u8) void {
        const reg = self.get(.a);
        const result, const overflow = @subWithOverflow(reg, value);

        self.set(.a, result);
        self.setFlags(.{
            .zero = result == 0,
            .subtract = true,
            .half_carry = (reg & 0xF) < (value & 0xF),
            .carry = overflow > 0,
        });
    }

    pub fn execute(self: *@This(), instruction: Instruction) void {
        const dst = instruction.dst;
        const src = instruction.src;
        switch (instruction.op) {
            .add => {
                std.debug.assert(dst == .a);

                const value = switch (src) {
                    .a => self.get(.a),
                    .b => self.get(.b),
                    .c => self.get(.c),
                    .d => self.get(.d),
                    .e => self.get(.e),
                    .f => self.get(.f),
                    .h => self.get(.h),
                    .l => self.get(.l),
                    else => @panic("unimplemented"),
                };

                self.add(value);

                self.pc += 1;
            },
            .sub => {
                std.debug.assert(dst == .a);

                const value = switch (src) {
                    .a => self.get(.a),
                    .b => self.get(.b),
                    .c => self.get(.c),
                    .d => self.get(.d),
                    .e => self.get(.e),
                    .f => self.get(.f),
                    .h => self.get(.h),
                    .l => self.get(.l),
                    else => @panic("unimplemented"),
                };

                self.sub(value);

                self.pc += 1;
            },
            else => @panic("unimplemented"),
        }
    }
};

test "cpu - sub" {
    {
        var cpu = Cpu.init(.{ .a = 2, .b = 1 });

        cpu.execute(.{ .op = .sub, .dst = .a, .src = .b });
        try std.testing.expectEqual(1, cpu.get(.a));
        try std.testing.expectEqual(true, cpu.getFlag(.n));
        try std.testing.expectEqual(false, cpu.getFlag(.z));

        cpu.execute(.{ .op = .sub, .dst = .a, .src = .b });
        try std.testing.expectEqual(0, cpu.get(.a));
        try std.testing.expectEqual(true, cpu.getFlag(.z));

        cpu.execute(.{ .op = .sub, .dst = .a, .src = .b });
        try std.testing.expectEqual(0xFF, cpu.get(.a));
        try std.testing.expectEqual(true, cpu.getFlag(.c));
        try std.testing.expectEqual(true, cpu.getFlag(.h));
    }
}

test "cpu - execute - add" {
    {
        var cpu = Cpu.init(.{ .a = 2, .b = 4, .subtract = true });
        cpu.execute(.{ .op = .add, .dst = .a, .src = .b });
        try std.testing.expectEqual(6, cpu.get(.a));
        try std.testing.expectEqual(false, cpu.getFlag(.n));
        try std.testing.expectEqual(false, cpu.getFlag(.z));
        try std.testing.expectEqual(false, cpu.getFlag(.c));
    }

    {
        var cpu = Cpu.init(.{ .a = 0xFF, .b = 1 });
        cpu.execute(.{ .op = .add, .dst = .a, .src = .b });
        try std.testing.expectEqual(0, cpu.get(.a));
        try std.testing.expectEqual(true, cpu.getFlag(.z));
        try std.testing.expectEqual(true, cpu.getFlag(.c));

        cpu.execute(.{ .op = .add, .dst = .a, .src = .b });
        try std.testing.expectEqual(1, cpu.get(.a));
        try std.testing.expectEqual(false, cpu.getFlag(.z));
        try std.testing.expectEqual(false, cpu.getFlag(.c));
    }

    {
        var cpu = Cpu.init(.{ .a = 0xF, .b = 1 });
        cpu.execute(.{ .op = .add, .dst = .a, .src = .b });
        try std.testing.expectEqual(0x10, cpu.get(.a));
        try std.testing.expectEqual(true, cpu.getFlag(.h));

        cpu.execute(.{ .op = .add, .dst = .a, .src = .b });
        try std.testing.expectEqual(0x11, cpu.get(.a));
        try std.testing.expectEqual(false, cpu.getFlag(.h));
    }
}

test "cpu - flags" {
    var cpu = Cpu{};

    cpu.setFlag(.c, true);
    cpu.setFlag(.z, true);
    try std.testing.expectEqual(true, cpu.getFlag(.c));
    try std.testing.expectEqual(true, cpu.getFlag(.z));

    cpu.setFlag(.c, false);
    try std.testing.expectEqual(false, cpu.getFlag(.c));
    try std.testing.expectEqual(true, cpu.getFlag(.z));
}

test "cpu - set u16 reg, get u8 regs" {
    var cpu = Cpu{};

    cpu.set(.af, 0x012F);
    try std.testing.expectEqual(0x01, cpu.get(.a));
    try std.testing.expectEqual(0x20, cpu.get(.f));

    cpu.set(.bc, 0x0304);
    try std.testing.expectEqual(0x03, cpu.get(.b));
    try std.testing.expectEqual(0x04, cpu.get(.c));

    cpu.set(.de, 0x0506);
    try std.testing.expectEqual(0x05, cpu.get(.d));
    try std.testing.expectEqual(0x06, cpu.get(.e));

    cpu.set(.hl, 0x0708);
    try std.testing.expectEqual(0x07, cpu.get(.h));
    try std.testing.expectEqual(0x08, cpu.get(.l));
}

test "cpu - set u8 regs, get u16 reg" {
    var cpu = Cpu{};

    cpu.set(.a, 1);
    cpu.set(.f, 0x2F);
    cpu.set(.b, 3);
    cpu.set(.c, 4);
    cpu.set(.d, 5);
    cpu.set(.e, 6);
    cpu.set(.h, 7);
    cpu.set(.l, 8);

    try std.testing.expectEqual(0x0120, cpu.get(.af));
    try std.testing.expectEqual(0x0304, cpu.get(.bc));
    try std.testing.expectEqual(0x0506, cpu.get(.de));
    try std.testing.expectEqual(0x0708, cpu.get(.hl));
}

const Gameboy = struct {
    cpu: Cpu = .{},
    memory: [0xFFFF]u8 = std.mem.zeroes([0xFFFF]u8),

    pub const width = 160;
    pub const height = 144;
};

pub fn main() anyerror!void {
    var gameboy = Gameboy.init();
    gameboy.reset();

    const screenWidth = Gameboy.width * 4;
    const screenHeight = Gameboy.height * 4;

    rl.initWindow(screenWidth, screenHeight, "Gameboy");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
    }
}
