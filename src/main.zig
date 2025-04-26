const std = @import("std");
const rl = @import("raylib");

const Register = enum {
    a,
    b,
    c,
    d,
    e,
    f,
    h,
    l,
    af,
    bc,
    de,
    hl,

    pub fn typeOf(comptime self: @This()) type {
        switch (self) {
            .af => return u16,
            .bc => return u16,
            .de => return u16,
            .hl => return u16,
            else => return u8,
        }
    }
};

const Flag = enum(u8) {
    z = 7, // zero
    n = 6, // subtraction
    h = 5, // half-carry
    c = 4, // carry

    pub fn mask(comptime self: @This()) u8 {
        return 1 << @intFromEnum(self);
    }
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

    pub inline fn getFlag(self: *@This(), comptime flag: Flag) bool {
        return (self.f & flag.mask()) > 0;
    }

    pub inline fn setFlag(self: *@This(), comptime flag: Flag, value: bool) void {
        if (value) {
            self.f = self.f | flag.mask();
        } else {
            self.f = self.f & ~flag.mask();
        }
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
            .af => (@as(u16, self.a) << 8) | @as(u16, self.f),
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
                self.f = @intCast(value & 0xFF);
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
};

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

    cpu.set(.af, 0x0102);
    try std.testing.expectEqual(0x01, cpu.get(.a));
    try std.testing.expectEqual(0x02, cpu.get(.f));

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
    cpu.set(.f, 2);
    cpu.set(.b, 3);
    cpu.set(.c, 4);
    cpu.set(.d, 5);
    cpu.set(.e, 6);
    cpu.set(.h, 7);
    cpu.set(.l, 8);

    try std.testing.expectEqual(0x0102, cpu.get(.af));
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
    var gameboy = Gameboy{};
    gameboy.cpu.set(.a, 0);

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
