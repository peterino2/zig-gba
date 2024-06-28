const std = @import("std");
const Build = std.Build;

const gbabuild = @import("gbabuild.zig");

pub fn build(b: *Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const gba_mod = b.addModule("gba", .{
        .root_source_file = b.path("gba.zig"),
    });
    const gba_target = b.resolveTargetQuery(gbabuild.target_query);

    _ = addGbaExe(b, gba_target, optimize, gba_mod, "hi");
    _ = addGbaExe(b, gba_target, optimize, gba_mod, "display");
    //_ = addGbaExe(b, gba_target, optimize, gba_mod, "pong");
    _ = addGbaExe(b, gba_target, optimize, gba_mod, "pongbetter");
}

fn addGbaExe(
    b: *Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
    gba_mod: *std.Build.Module,
    comptime name: []const u8,
) void {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path("examples/" ++ name ++ ".zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("gba", gba_mod);
    exe.setLinkerScriptPath(b.path("gba.ld"));

    const objcopy_step = exe.addObjCopy(.{
        .format = .bin,
    });

    const install_bin_step = b.addInstallBinFile(objcopy_step.getOutputSource(), b.fmt("{s}.gba", .{name}));
    install_bin_step.step.dependOn(&objcopy_step.step);

    b.default_step.dependOn(&install_bin_step.step);

    b.installArtifact(exe);
    //exe.installRaw(name ++ ".gba");
    //return exe;
}
