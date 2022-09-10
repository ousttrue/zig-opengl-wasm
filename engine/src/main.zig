const std = @import("std");
const builtin = @import("builtin");
const gl = @import("./gl.zig");

const Vertex = std.meta.Tuple(&.{ f32, f32, f32, f32, f32 });
const vertices = [3]Vertex{
    .{ -0.6, -0.4, 1.0, 0.0, 0.0 },
    .{ 0.6, -0.4, 0.0, 1.0, 0.0 },
    .{ 0.0, 0.6, 0.0, 0.0, 1.0 },
};

const vertex_shader_text: [*:0]const u8 = @embedFile("./shader.vs");
const fragment_shader_text: [*:0]const u8 = @embedFile("./shader.fs");

var program: u32 = undefined;
var mvp_location: c_uint = undefined;

// init OpenGL by glad
const GLADloadproc = fn ([*c]const u8) callconv(.C) ?*anyopaque;
pub extern fn gladLoadGL(*const GLADloadproc) c_int;
pub fn loadproc(ptr: *const anyopaque) void {
    if (builtin.target.cpu.arch != .wasm32) {
        _ = gladLoadGL(@ptrCast(*const GLADloadproc, ptr));
    }
}

export fn ENGINE_init(p: *const anyopaque) callconv(.C) void {
    loadproc(p);

    var vertex_buffer: gl.GLuint = undefined;
    gl.genBuffers(1, &vertex_buffer);
    gl.bindBuffer(gl.GL_ARRAY_BUFFER, vertex_buffer);
    gl.bufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.GL_STATIC_DRAW);

    const vertex_shader = gl.createShader(gl.GL_VERTEX_SHADER);
    gl.shaderSource(vertex_shader, 1, &vertex_shader_text);
    gl.compileShader(vertex_shader);

    const fragment_shader = gl.createShader(gl.GL_FRAGMENT_SHADER);
    gl.shaderSource(fragment_shader, 1, &fragment_shader_text);
    gl.compileShader(fragment_shader);

    program = gl.createProgram();
    gl.attachShader(program, vertex_shader);
    gl.attachShader(program, fragment_shader);
    gl.linkProgram(program);

    mvp_location = gl.getUniformLocation(program, "MVP");
    const vpos_location = gl.getAttribLocation(program, "vPos");
    const vcol_location = gl.getAttribLocation(program, "vCol");

    gl.enableVertexAttribArray(@intCast(c_uint, vpos_location));
    gl.vertexAttribPointer(@intCast(c_uint, vpos_location), 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), 0);
    gl.enableVertexAttribArray(@intCast(c_uint, vcol_location));
    gl.vertexAttribPointer(@intCast(c_uint, vcol_location), 3, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @sizeOf(f32) * 2);
}

export fn ENGINE_render(width: c_int, height: c_int) callconv(.C) void {
    // Render here
    gl.viewport(0, 0, width, height);
    gl.clear(gl.GL_COLOR_BUFFER_BIT);

    var mvp = [_]f32{
        1, 0, 0, 0, //
        0, 1, 0, 0, //
        0, 0, 1, 0, //
        0, 0, 0, 1, //
    };

    gl.useProgram(program);
    gl.uniformMatrix4fv(mvp_location, 1, gl.GL_FALSE, &mvp[0]);
    gl.drawArrays(gl.GL_TRIANGLES, 0, 3);
}
