const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "engine",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = mode,
    });

    if (target.cpu_arch == std.Target.Cpu.Arch.wasm32) {
        lib.rdynamic = true;
        lib.export_symbol_names = &[_][]const u8{
            "ENGINE_init",
            "ENGINE_render",
            "ENGINE_getGlobalInput",
        };
    } else {
        // glad
        lib.linkLibC();
        lib.addIncludePath("../desktop/glfw/deps");
        lib.addCSourceFile("../desktop/glfw/deps/glad_gl.c", &.{});
        lib.addCSourceFile("src/glad_placeholders.c", &.{});
    }

    lib.install();

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = mode,
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
