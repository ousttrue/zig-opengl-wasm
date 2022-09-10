const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addSharedLibrary("engine", "src/main.zig", .unversioned);
    lib.setBuildMode(mode);

    lib.linkLibC();
    // glad
    lib.addIncludePath("../desktop/glfw/deps");
    lib.addCSourceFile("../desktop/glfw/deps/glad_gl.c", &.{});

    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
