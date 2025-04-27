const Register = @import("register.zig").Register;

pub const Instruction = enum(u8) {
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

pub const Op = enum {
    add,
    adc,
    sub,
    sbc,
};

pub const T = struct {
    op: Op,
    src: Register,
    dst: Register,
};
