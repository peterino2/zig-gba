//! Example ported from: http://www.loirak.com/gameboy/gbatutor.php
//!
//! sample program to display pcx, and get key input
//!
//! NOTE: this program only draw the image on 1 of the video buffers, it also doesn't
//!       perform any synchronization with the display which causes artifacts.
//!
const gba = @import("gba");
const mem = gba.mem;
const ops = gba.ops;
const gfx = gba.gfx;
const input = gba.input;
const mode3 = gba.mode3;

const ppic = @import("display/ppic.zig");

// NOTE: this is required unless we find a solution for: https://github.com/ziglang/zig/issues/8508
comptime {
    _ = gba.start;
}

// NOTE: I'd like to export this in header.zig but when I export it that way
//       it says it requires the struct to be 'extern'
//       https://github.com/ziglang/zig/issues/8501
export const _ linksection(".gbaheader") = gba.Header.init("DISPLAY", "AFSE", "00", 0);

fn PlotPixel(x: u8, y: u8, c: u16) void {
    //mode4.video[gfx.pixelIndex(x, y)] = c;
    //mode4.video[y*120+x] = c;
    mem.video16[@as(u16, @intCast(y)) * 120 + x] = c;
}

fn clampInc(comptime T: type, val: T, max: T) T {
    return if (val == max) val else val + 1;
}
fn clampDec(comptime T: type, val: T, min: T) T {
    return if (val == min) val else val - 1;
}

fn vsync() void {
    while (mem.reg_vcount.* >= 160) {} // wait till VDraw
    while (mem.reg_vcount.* < 160) {} // wait till VBlank
}

pub fn main() noreturn {
    mem.reg_dispcnt_l.* = gfx.DisplayControl{
        .mode = .mode4,
        .backgroundLayer2 = .show,
    };

    // copy palette
    // NOTE: the following should also be able to copy the palette
    ops.memcpy16(mem.bg_palette, &ppic.palette, ppic.palette.len * @sizeOf(u16));
    {
        var loop: u16 = 0;
        if (ppic.palette.len != 256) @compileError("palette unexpected len");
        while (loop < ppic.palette.len) : (loop += 1) {
            mem.bg_palette[loop] = ppic.palette[loop];
        }
    }

    // clear screen, and draw a blue background
    {
        var x: u8 = 0;
        while (x < gfx.width) : (x += 1) {
            var y: u8 = 0;
            while (y < gfx.height) : (y += 1) {
                mode3.video[gfx.pixelIndex(x, y)] = gfx.toRgb16(0, 0, 5);
            }
        }
    }

    //   // TODO: u8?
    const blockX: u8 = 50; // give our block a start position
    const blockY: u8 = 50;

    while (true) { // run forever
        // process input
        // if (0 == (mem.reg_p1.* & input.Key.up)) // they pushed up
        //     blockY = clampDec(u8, blockY, 0); // subtract from y (move up)
        // if (0 == (mem.reg_p1.* & input.Key.down))
        //     blockY = clampInc(u8, blockY, gba.gfx.height - 1);
        // if (0 == (mem.reg_p1.* & input.Key.left))
        //     blockX = clampDec(u8, blockX, 0);
        // if (0 == (mem.reg_p1.* & input.Key.right))
        //     blockX = clampInc(u8, blockX, gba.gfx.width - 1);

        //       // draw the picture
        //       // NOTE: the following should also draw the picture
        // ops.memcpy16(mem.video16, &ppic.data, ppic.data.len * @sizeOf(u16));
        {
            var y: u8 = 0;
            while (y < 160) : (y += 1) {
                var x: u8 = 0;
                while (x < 120) : (x += 1) {
                    PlotPixel(x, y, ppic.data[y * 120 + x]);
                }
            }
        }

        // draw the box being controlled by the player
        PlotPixel(blockX, blockY, (75 << 8) + 75);
        PlotPixel(blockX + 1, blockY, (75 << 8) + 75);
        PlotPixel(blockX, blockY + 1, (75 << 8) + 75);
        PlotPixel(blockX + 1, blockY + 1, (75 << 8) + 75);
    }
} //
