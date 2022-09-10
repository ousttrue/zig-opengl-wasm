const std = @import("std");
const c = @cImport({
    @cInclude("glad/gl.h");
    @cDefine("GLFW_INCLUDE_NONE", &.{});
    @cInclude("GLFW/glfw3.h");
});

const Vertex = std.meta.Tuple(&.{ f32, f32, f32, f32, f32 });
const vertices = [3]Vertex{
    .{ -0.6, -0.4, 1.0, 0.0, 0.0 },
    .{ 0.6, -0.4, 0.0, 1.0, 0.0 },
    .{ 0.0, 0.6, 0.0, 0.0, 1.0 },
};

const vertex_shader_text: [*:0]const u8 = @embedFile("./shader.vs");
const fragment_shader_text: [*:0]const u8 = @embedFile("./shader.fs");

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
    _ = c.gladLoadGL(c.glfwGetProcAddress);
    c.glfwSwapInterval(1);

    var vertex_buffer: c.GLuint = undefined;
    c.glGenBuffers(1, &vertex_buffer);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vertex_buffer);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    const vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertex_shader, 1, &vertex_shader_text, null);
    c.glCompileShader(vertex_shader);

    const fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragment_shader, 1, &fragment_shader_text, null);
    c.glCompileShader(fragment_shader);

    const program = c.glCreateProgram();
    c.glAttachShader(program, vertex_shader);
    c.glAttachShader(program, fragment_shader);
    c.glLinkProgram(program);

    const mvp_location = c.glGetUniformLocation(program, "MVP");
    const vpos_location = c.glGetAttribLocation(program, "vPos");
    const vcol_location = c.glGetAttribLocation(program, "vCol");

    c.glEnableVertexAttribArray(@intCast(c_uint, vpos_location));
    c.glVertexAttribPointer(@intCast(c_uint, vpos_location), 2, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), null);
    c.glEnableVertexAttribArray(@intCast(c_uint, vcol_location));
    c.glVertexAttribPointer(@intCast(c_uint, vcol_location), 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), @intToPtr(*anyopaque, @sizeOf(f32) * 2));

    // Loop until the user closes the window
    while (c.glfwWindowShouldClose(window) == 0) {
        var width: c_int = undefined;
        var height: c_int = undefined;
        c.glfwGetFramebufferSize(window, &width, &height);
        // ratio = width / (float) height;

        // Render here
        c.glViewport(0, 0, width, height);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        var mvp = [_]f32{
            1, 0, 0, 0, //
            0, 1, 0, 0, //
            0, 0, 1, 0, //
            0, 0, 0, 1, //
        };

        c.glUseProgram(program);
        c.glUniformMatrix4fv(mvp_location, 1, c.GL_FALSE, &mvp);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        // Swap front and back buffers
        c.glfwSwapBuffers(window);
        // Poll for and process events
        c.glfwPollEvents();
    }
}
