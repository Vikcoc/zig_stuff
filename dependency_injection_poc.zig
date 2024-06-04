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

const Container = struct {
    comptime services: std.AutoHashMap(type, std.builtin.Type.Fn) = .{},
    pub fn addFactory(comptime this: *Container, comptime function: anytype) *Container {
        const tp = this.services.getKey(@TypeOf(function).Fn.return_type.?);
        if (tp != null)
            @compileLog("Cannot insert 2 factory methods for the same type: {s}", .{@typeName(tp.?)});

        inline for (@typeInfo(@TypeOf(function)).Fn.params) |param| {
            const ptp = this.services.getKey(param.type.?);
            if (ptp == null)
                @compileLog("Cannot generate type {s}", .{@typeName(param.type.?)});
        }
        this.services.addOne(function);
        return this;
    }
    pub fn inject(comptime this: *Container, comptime function: anytype) @typeInfo(@TypeOf(function)).Fn.return_type.? {
        const tp = @typeInfo(@TypeOf(function));
        comptime var argt: [tp.Fn.params.len]type = undefined;
        inline for (tp.Fn.params, 0..) |param, index| {
            const ptp = this.services.getKey(param.type.?);
            if (ptp == null)
                @compileLog("Cannot generate type {s}", .{@typeName(param.type.?)});
            argt[index] = param.type.?;
        }
        const tptp = std.meta.Tuple(argt[0..]);
        const fields = @typeInfo(tptp).Struct.fields;
        const y: tptp = undefined;
        inline for (fields) |field| {
            const fun = this.services[field.type];
            @field(y, field.name) = this.inject(fun);
        }

        return @call(std.builtin.CallModifier.auto, function, y);
    }
};

pub fn main() void {
    comptime var cont: Container = .{};
    cont.addFactory(fn () Tst{return .{}});
    cont.addFactory(fn () Tst{return 20});
    std.debug.print("This is returned {d}\n", .{cont.inject(extraReturn)});
    cont.inject(extra);
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
