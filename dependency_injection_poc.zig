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

const DIContainer = struct {
    comptime head: type = undefined,
    comptime count: u64 = 0,
    pub fn addFactory(comptime this: *DIContainer, comptime func: anytype) DIContainer {
        const tp = @typeInfo(@TypeOf(func));
        switch (tp) {
            .Fn => {},
            inline else => @compileLog("Type {s} is not a function", .{@typeName(tp)}),
        }
        comptime var fact = this.head;
        comptime var satisfied = 0;
        inline for (0..this.count) |_| {
            inline for (tp.Fn.params) |param| {
                if (@typeInfo(@TypeOf(fact.fabricate)).Fn.return_type.? == param.type.?) {
                    satisfied += 1;
                }
            }
            fact = fact.next;
        }

        if (satisfied < tp.Fn.params.len) {
            @compileLog("Cannot create type {s}", .{tp.Fn.return_type.?});
        }

        fact = this.head;
        inline for (0..this.count) |_| {
            if (@typeInfo(@TypeOf(fact.fabricate)).Fn.return_type.? == tp.Fn.return_type.?)
                @compileLog("Type {s} is already injected", .{tp.Fn.return_type.?});
        }

        const ntp = struct { next: type = this.head, fabricate: @TypeOf(func) = func };
        this.head = ntp;

        return this;
    }
};

pub fn tstFactory() Tst {
    const x = Tst{ .x = 20, .y = 10 };
    return x;
}

pub fn main() void {
    comptime var cont: DIContainer = .{ .head = undefined, .count = 0 };
    _ = cont.addFactory(tstFactory);
    // std.debug.print("This is returned {d}\n", .{cont.inject(extraReturn)});
    // cont.inject(extra);
}

pub fn doInvoke(comptime func: anytype) @typeInfo(@TypeOf(func)).Fn.return_type.? {
    const c = @typeInfo(@TypeOf(func));
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
