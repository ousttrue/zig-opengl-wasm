const std = @import("std");
const c = @cImport({
    @cDefine("GLFW_INCLUDE_NONE", &.{});
    @cInclude("GLFW/glfw3.h");
});

extern fn ENGINE_init(p: *const anyopaque) callconv(.C) void;
extern fn ENGINE_render(width: c_int, height: c_int) callconv(.C) void;

pub fn main() anyerror!void {

    // Initialize the library
    std.debug.assert(c.glfwInit() == 1);
    defer c.glfwTerminate();

    // Create a windowed mode window and its OpenGL context
    const window = c.glfwCreateWindow(640, 480, "Hello World", null, null);
    std.debug.assert(window != null);
    defer c.glfwDestroyWindow(window);

    // Make the window's context current
    c.glfwMakeContextCurrent(window);
    ENGINE_init(c.glfwGetProcAddress);
    c.glfwSwapInterval(1);

    // Loop until the user closes the window
    while (c.glfwWindowShouldClose(window) == 0) {
        // Poll for and process events
        c.glfwPollEvents();

        var width: c_int = undefined;
        var height: c_int = undefined;
        c.glfwGetFramebufferSize(window, &width, &height);
        // ratio = width / (float) height;

        ENGINE_render(width, height);

        // Swap front and back buffers
        c.glfwSwapBuffers(window);
    }
}
