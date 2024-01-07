const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const run_step = b.step("run", "Run the demo");

    // executables =========================================================================
    var exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    b.getInstallStep().dependOn(&b.addInstallArtifact(exe, .{ .dest_dir = .{ .override = .{ .custom = "../bin" } } }).step);

    run_step.dependOn(&run_cmd.step);

    const wavez_mod_dep = b.dependency("wavez", .{ // as declared in build.zig.zon
        .target = target,
        .optimize = optimize,
    });

    const wavez_mod = wavez_mod_dep.module("wavez_import_name"); // as declared in build.zig of dependency

    exe.root_module.addImport("wavez_import_name", wavez_mod); // name to use when importing

}
