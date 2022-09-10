const std = @import("std");
const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    // Initialize the library
    std.debug.assert(c.glfwInit() == 1);
    defer c.glfwTerminate();

    // Create a windowed mode window and its OpenGL context
    const window = c.glfwCreateWindow(640, 480, "Hello World", null, null);
    defer c.glfwDestroyWindow(window);

    // Make the window's context current
    c.glfwMakeContextCurrent(window);

    // Loop until the user closes the window
    while (c.glfwWindowShouldClose(window) == 0) {
        // Render here
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // Swap front and back buffers
        c.glfwSwapBuffers(window);

        // Poll for and process events
        c.glfwPollEvents();
    }
}
