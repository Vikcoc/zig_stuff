const std = @import("std");
const Tst = struct {
    x: u10,
    y: u11,
    pub fn doSomething(this: Tst) void {
        _ = this;
        std.debug.print("I am a gummy bear\n", .{});
    }

    pub fn retVal(this: Tst) u32 {
        _ = this;
        return 445;
    }
};

pub fn main() void {
    std.debug.print("This is returned {d}\n", .{doInvoke(extraReturn)});
    doInvoke(extra);
}

pub fn doInvoke(comptime func: anytype) @typeInfo(@TypeOf(func)).Fn.return_type.? {
    const c = @typeInfo(@TypeOf(func));
    switch (c) {
        .Fn => {},
        inline else => @compileLog("Cannot"),
    }
    comptime var d: [c.Fn.params.len]type = undefined;

    inline for (c.Fn.params, 0..) |param, index| {
        d[index] = param.type.?;
    }

    const x = std.meta.Tuple(d[0..]);
    const y: x = undefined;

    return @call(std.builtin.CallModifier.auto, func, y);
}

pub fn extraReturn(val: Tst) u32 {
    return val.retVal();
}

pub fn extra(val: u16, val2: Tst) void {
    std.debug.print("ada {d} {d} {d}\n", .{ val, val2.x, val2.y });
}

pub fn extra2(val: u16) void {
    std.debug.print("ada2 {d}\n", .{val});
}

pub fn extra3(val: u16, val2: Tst) void {
    val2.doSomething();
    std.debug.print("ada3 {d} {d} {d}\n", .{ val, val2.x, val2.y });
}
