const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const wavez = b.addModule("wavez_import_name", .{
        .root_source_file = .{ .path = "src/wav_utils.zig" },
    });

    const wavez_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/wav_utils_test.zig" },
        .target = target,
        .optimize = optimize,
    });

    wavez_tests.root_module.addImport("wavez_import_name", wavez);

    const run_wavez_tests = b.addRunArtifact(wavez_tests);
    const test_step = b.step("test", "Run module tests");

    test_step.dependOn(&run_wavez_tests.step);
}
