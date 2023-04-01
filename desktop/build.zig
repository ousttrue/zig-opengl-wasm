const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "desktop",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = mode,
    });

    exe.linkLibC();
    // glfw
    exe.addIncludePath("glfw/include");
    if (target.isWindows()) {
        exe.addLibraryPath("build/src/Debug");
    } else {
        exe.addLibraryPath("build/src");
        exe.addCSourceFiles(&[_][]const u8{
            "glfw/src/context.c",
            "glfw/src/init.c",
            "glfw/src/input.c",
            "glfw/src/monitor.c",
            "glfw/src/vulkan.c",
            "glfw/src/window.c",
            // x11
            "glfw/src/x11_init.c",
            "glfw/src/x11_monitor.c",
            "glfw/src/x11_window.c",
            "glfw/src/xkb_unicode.c",
            "glfw/src/posix_time.c",
            "glfw/src/posix_thread.c",
            "glfw/src/glx_context.c",
            "glfw/src/egl_context.c",
            "glfw/src/osmesa_context.c",
            // linux
            "glfw/src/linux_joystick.c",
        }, &[_][]const u8{
            "-D_GLFW_X11=1",
        });
        exe.linkSystemLibrary("X11");
        exe.linkSystemLibrary("GL");
    }

    // engine
    exe.addLibraryPath("../engine/zig-out/lib");
    exe.linkSystemLibrary("engine");

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = mode,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
