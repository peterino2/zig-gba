const ops = @import("ops.zig");
const bios = @import("bios.zig");
const root = @import("root");

comptime {
    _ = @import("header.zig"); // This forces header.zig to be imported
    if (!@hasDecl(root, "_start")) {
        @export(_start, .{ .name = "_start", .section = ".gbamain" });
    }
}

extern var __bss_lma: u8;
extern var __bss_start__: u8;
extern var __bss_end__: u8;
extern var __data_lma: u8;
extern var __data_start__: u8;
extern var __data_end__: u8;

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//fn _start() callconv(.Naked) noreturn {
fn _start() callconv(.C) noreturn {
    // Assembly init code
    asm volatile (
        \\.arm
        \\.cpu arm7tdmi
        \\mov r0, #0x4000000
        \\str r0, [r0, #0x208]
        \\
        \\mov r0, #0x12
        \\msr cpsr, r0
        \\ldr sp, =__sp_irq
        \\mov r0, #0x1f
        \\msr cpsr, r0
        \\ldr sp, =__sp_usr
        \\add r0, pc, #1
        \\bx r0
    );

    bios.registerRamReset(bios.RamResetFlags.All);

    // Clear .bss
    const bss_ptr: [*]u8 = @ptrCast(&__bss_start__);
    const bss_len = @intFromPtr(&__bss_end__) - @intFromPtr(&__bss_start__);
    @memset(bss_ptr[0 .. bss_len], 0);

    // Copy .data section to EWRAM
    const data_ptr: [*]u8 = @ptrCast(&__data_start__);
    const data_lma_ptr: [*]u8 = @ptrCast(&__data_lma);
    const data_len = @intFromPtr(&__data_end__) - @intFromPtr(&__data_start__);
    @memcpy(data_ptr[0 .. data_len], data_lma_ptr);

    if (@typeInfo(@TypeOf(root.main)).Fn.return_type != noreturn)
        @compileError("expected return type of main to be 'noreturn'");

    @call(.always_inline, root.main, .{});
}
