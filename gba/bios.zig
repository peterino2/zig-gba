const std = @import("std");

pub const RamResetFlags = packed struct(u8) {
    clearEwRam: bool = false,
    clearIwram: bool = false,
    clearPalette: bool = false,
    clearVRAM: bool = false,
    clearOAM: bool = false,
    resetSIORegisters: bool = false,
    resetSoundRegisters: bool = false,
    resetOtherRegisters: bool = false,

    const Self = @This();

    pub const All = Self{
        .clearEwRam = true,
        .clearIwram = true,
        .clearPalette = true,
        .clearVRAM = true,
        .clearOAM = true,
        .resetSIORegisters = true,
        .resetSoundRegisters = true,
        .resetOtherRegisters = true,
    };
};

inline fn getSystemCallAssemblyCode(comptime call: u8) []const u8 {
    var buffer: [64]u8 = undefined;
    return std.fmt.bufPrint(buffer[0..], "swi {}", .{call}) catch unreachable;
}

pub inline fn systemCall1(comptime call: u8, param0: u32) void {
    const assembly = comptime getSystemCallAssemblyCode(call);

    asm volatile (assembly
        :
        : [param0] "{r0}" (param0),
        : "r0"
    );
}

pub inline fn registerRamReset(flags: RamResetFlags) void {
    systemCall1(0x01, @as(u8, @bitCast(flags)));
}

pub inline fn registerRamResetAll() void {
    asm volatile (
        \\.arm
        \\mov r0, #255
        \\swi 0x01
    );
}
