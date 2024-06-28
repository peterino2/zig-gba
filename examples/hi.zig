//! Example ported from: http://www.loirak.com/gameboy/gbatutor.php
//!
//! Gameboy Advance Tutorial - Loirak Developmen
//!
const gba = @import("gba");
const mem = gba.mem;
const gfx = gba.gfx;
const mode3 = gba.mode3;

const input = gba.input;
const ops = gba.ops;
const ppic = @import("display/ppic.zig");
const tile_4bpp = [8]u32;
const tile_block = [512]tile_4bpp;
const obj_attrs = packed struct {
    attr0: u16,
    attr1: u16,
    attr2: u16,
    pad: u16,
};

fn clampInc(comptime T: type, val: T, max: T) T {
    return if (val == max) val else val + 1;
}
fn clampDec(comptime T: type, val: T, min: T) T {
    return if (val == min) val else val - 1;
}
export const oam_mem: [*]volatile obj_attrs = @ptrCast(@alignCast(mem.oam));
export const tile_mem: [*]volatile tile_block = @ptrCast(@alignCast(mem.video16));

// NOTE: this is required unless we find a solution for: https://github.com/ziglang/zig/issues/8508
comptime {
    _ = gba.start;
}

// NOTE: I'd like to export this in header.zig but when I export it that way
//       it says it requires the struct to be 'extern'
//       https://github.com/ziglang/zig/issues/8501
export const _ linksection(".gbaheader") = gba.Header.init("HI", "AFSE", "00", 0);

pub fn main() noreturn {
    mem.reg_dispcnt_l.* = gfx.DisplayControl{
        .mode = .mode3,
        .backgroundLayer2 = .show,
    };

    // comment this out and you'll see this rom being placed at 0x0200_0000
    ops.memcpy16(mem.bg_palette, &ppic.palette, ppic.palette.len * @sizeOf(u16));

    // move this one into the while loop and we'll get kicked into reset mode.
    // can't investigate much more without a debugger
    {
        var x: u8 = 0;
        while (x < gfx.width) : (x += 1) {
            var y: u8 = 0;
            while (y < gfx.height) : (y += 1) {
                mode3.video[gfx.pixelIndex(x, y)] = gfx.toRgb16(0, 0, 15);
            }
        }
    }
    while (true) {
        {
            var x: u8 = 20;
            while (x <= 60) : (x += 15) {
                var y: u8 = 30;
                while (y < 50) : (y += 1) {
                    mode3.video[gfx.pixelIndex(x, y)] = gfx.toRgb16(31, 31, 31);
                }
            }
        }
        {
            var x: u8 = 20;
            while (x <= 35) : (x += 1) {
                mode3.video[gfx.pixelIndex(x, 40)] = gfx.toRgb16(31, 31, 31);
            }
        }

        gfx.vsync();
    } // loop forever
}
