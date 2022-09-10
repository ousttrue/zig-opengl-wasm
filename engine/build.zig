const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addSharedLibrary("engine", "src/main.zig", .unversioned);
    lib.setTarget(target);
    lib.setBuildMode(mode);

    if (target.cpu_arch != std.Target.Cpu.Arch.wasm32) {
        // glad
        lib.linkLibC();
        lib.addIncludePath("../desktop/glfw/deps");
        lib.addCSourceFile("../desktop/glfw/deps/glad_gl.c", &.{});
        lib.addCSourceFile("src/glad_placeholders.c", &.{});
    }

    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
