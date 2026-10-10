const std = @import("std");
const print = std.debug.print;
const args = .{ "Hello", "World" };

pub fn main() void {
    print("{s}, {s}!", args);
}
