const std = @import("std");
const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    std.debug.assert(c.glfwInit() != 0);
    defer c.glfwTerminate();
}
