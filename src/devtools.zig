//
//     conditionally disable code
//
pub const developer_build: bool = false;
pub const show_timings: bool = false; //developer_build;

//
//     returns the smallest integer type that can hold `cap`
//
pub fn Int(cap: u16) type { // same as std.math.IntFittingRange, but with fewer arguments and less code
    return switch (cap) { // compatible with zig 0.13.0
        0...7 => u3,
        8...15 => u4,
        16...31 => u5,
        32...63 => u6,
        64...127 => u7,
        128...255 => u8,
        else => unreachable,
    };
    //return @Type(.{ // not compatible with zig 0.13.0
    //    .int = .{
    //        .signedness = .unsigned,
    //        .bits = 16 - @clz(cap),
    //    },
    //});
}

// turns 34 into "34". assumes the number will have 2 digits.
pub fn numberAsString(comptime int: u8) [2]u8 {
    return .{
        @divFloor(int, 10) + '0',
        (int % 10) + '0',
    };
}

// log10 that rounds down and doesn't need a float
pub fn log10(int: u8) comptime_int {
    switch (int) {
        0...9 => return 1,
        10...99 => return 2,
        else => unreachable, // feel free to change this
    }
}

// ===================
// performance testing
// ===================

var start_timestamp: usize = undefined;

pub fn startTiming() void {
    start_timestamp = rdtsc();
}

const output = @import("output.zig");
pub fn printTime(context_string: []const u8) void {
    const cycles = rdtsc() - start_timestamp;
    output.print("{s}{d: >7.2} {c}s\n", .{ context_string, @as(f64, @floatFromInt(cycles)) / cycles_per_microsecond, 230 });
    // i can't get measurements to be more specific than 1/100th of a microsecond
}

const cycles_per_microsecond = 3.8 * 1000; // for a 3.8GHz cpu

inline fn rdtsc() usize { // returns cycles. accurate to about 10 cycles.
    var a: u32 = undefined;
    var b: u32 = undefined;
    asm volatile ("rdtscp"
        : [a] "={edx}" (a),
          [b] "={eax}" (b),
        :
        : "ecx"
    );
    return (@as(u64, a) << 32) | b;
}

// =================
// Structs of Arrays (deprecated)
// =================

pub inline fn SOA(comptime T: type, comptime capacity: u8) SOA_Type(T, capacity) {
    const return_struct: SOA_Type(T, capacity) = undefined;
    return return_struct;
}

inline fn SOA_Type(comptime T: type, comptime capacity: u8) type {
    const fields = @typeInfo(T).@"struct".fields;
    var struct_fields: [1 + fields.len * 2]@import("std").builtin.Type.StructField = undefined;

    struct_fields[0] = .{
        .name = "len",
        .type = u8,
        .default_value = &@as(u8, 0),
        .is_comptime = false,
        .alignment = @alignOf(u8),
    };

    var length = 1;
    inline for (fields) |field| {
        struct_fields[length] = .{
            .name = field.name ++ "_array",
            .type = [capacity]field.type,
            .default_value = null,
            .is_comptime = field.is_comptime,
            .alignment = @alignOf([capacity]field.type),
        };
        struct_fields[length + 1] = .{
            .name = field.name ++ "_slice",
            .type = []field.type,
            .default_value = null, // i want to be able to set the default, but i don't know how. &@as(?T, null)
            .is_comptime = false,
            .alignment = @alignOf([]field.type),
        };

        length += 2;
    }

    return @Type(.{ .@"struct" = .{
        .layout = .auto,
        .fields = &struct_fields,
        .decls = &.{},
        .is_tuple = false,
    } });
}
