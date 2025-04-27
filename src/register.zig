pub const Register = enum {
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
