const std = @import("std");
const c = @cImport({
    @cInclude("glad/gl.h");
});

const Vertex = std.meta.Tuple(&.{ f32, f32, f32, f32, f32 });
const vertices = [3]Vertex{
    .{ -0.6, -0.4, 1.0, 0.0, 0.0 },
    .{ 0.6, -0.4, 0.0, 1.0, 0.0 },
    .{ 0.0, 0.6, 0.0, 0.0, 1.0 },
};

const vertex_shader_text: [*:0]const u8 = @embedFile("./shader.vs");
const fragment_shader_text: [*:0]const u8 = @embedFile("./shader.fs");

var program: u32 = undefined;
var mvp_location: c_int = undefined;

export fn ENGINE_init(p: *anyopaque) callconv(.C) void {
    _ = c.gladLoadGL(@ptrCast(?*const fn([*c]const u8) callconv(.C) ?*const fn() callconv(.C) void, p));

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

    program = c.glCreateProgram();
    c.glAttachShader(program, vertex_shader);
    c.glAttachShader(program, fragment_shader);
    c.glLinkProgram(program);

    mvp_location = c.glGetUniformLocation(program, "MVP");
    const vpos_location = c.glGetAttribLocation(program, "vPos");
    const vcol_location = c.glGetAttribLocation(program, "vCol");

    c.glEnableVertexAttribArray(@intCast(c_uint, vpos_location));
    c.glVertexAttribPointer(@intCast(c_uint, vpos_location), 2, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), null);
    c.glEnableVertexAttribArray(@intCast(c_uint, vcol_location));
    c.glVertexAttribPointer(@intCast(c_uint, vcol_location), 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), @intToPtr(*anyopaque, @sizeOf(f32) * 2));
}

export fn ENGINE_render(width: c_int, height: c_int) callconv(.C) void {
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
}
