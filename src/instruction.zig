const Register = @import("register.zig").Register;

pub const Instruction = enum(u8) {
    nop = 0x00,

    ld_a_8 = 0x3E,

    ld_a16_a = 0xEA,

    ld_a_a16 = 0xFA,

    add_a_b = 0x80,
    add_a_c = 0x81,
    add_a_d = 0x82,
    add_a_e = 0x83,
    add_a_h = 0x84,
    add_a_l = 0x85,
    add_a_hl = 0x86,
    add_a_a = 0x87,
    adc_a_b = 0x88,
    adc_a_c = 0x89,
    adc_a_d = 0x8A,
    adc_a_e = 0x8B,
    adc_a_h = 0x8C,
    adc_a_l = 0x8D,
    adc_a_hl = 0x8E,
    adc_a_a = 0x8F,

    sub_a_b = 0x90,
    sub_a_c = 0x91,
    sub_a_d = 0x92,
    sub_a_e = 0x93,
    sub_a_h = 0x94,
    sub_a_l = 0x95,
    sub_a_hl = 0x96,
    sub_a_a = 0x97,
    sbc_a_b = 0x98,
    sbc_a_c = 0x99,
    sbc_a_d = 0x9A,
    sbc_a_e = 0x9B,
    sbc_a_h = 0x9C,
    sbc_a_l = 0x9D,
    sbc_a_hl = 0x9E,
    sbc_a_a = 0x9F,
};

pub const Op = union(enum) {
    // CPU control
    nop: u0,
    stop: u0,
    halt: u0,
    di: u0,
    ei: u0,
    daa: u0,
    scf: u0,
    cpl: u0,
    ccf: u0,

    // 8bit arithmetic
    add: Add,
    sub: Sub,

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
        a: u0,
        b: u0,
        c: u0,
        d: u0,
        e: u0,
        h: u0,
        l: u0,
        ahl: u0,
        d8: u8,
    };
};

pub const Sub = struct {
    right: Operand,

    pub const Operand = union(enum) {
        a: u0,
        b: u0,
        c: u0,
        d: u0,
        e: u0,
        h: u0,
        l: u0,
        ahl: u0,
        d8: u8,
    };
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
        hl_high_address: u0,
        hl_low_address: u0,
    };
};
