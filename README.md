# zig-opengl-wasm

sample

## その1: GLFW window を glClear

<https://www.glfw.org/documentation.html>

を移植する。

```
$ mkdir zig-opengl-wasm # project-root
$ cd zig-opengl-wasm
zig-opengl-wasm$ mkdir desktop
zig-opengl-wasm$ cd desktop
zig-opengl-wasm/desktop $ zig init-exe
```

### GLFW を dll build する

```
zig-opengl-wasm/desktop$ git submodule add https://github.com/glfw/glfw.git
zig-opengl-wasm/desktop$ cd glfw
zig-opengl-wasm/desktop/glfw$ git switch -C Branch_3.3.8 3.3.8 
zig-opengl-wasm/desktop/glfw$ cd ..
zig-opengl-wasm/desktop$ cmake -B build -S glfw -DBUILD_SHARED_LIBS=ON
zig-opengl-wasm/desktop$ cmake --build build
```

> `static build` だとなんか不可解なエラーが出て解決できなかったので切り離しています。

`build/src/Debug/glfw3.dll`
`build/src/Debug/glfw3dll.lib`

### zig から glfw3.dll を使う


```zig:build.zig
// exe.install の前に追加

// glfw
exe.linkLibC();
exe.addIncludePath("glfw/include");    
exe.addLibraryPath("build/src/Debug");
exe.linkSystemLibrary("glfw3dll");
```

最初の一歩。dll の関数呼び出し実験。

```zig:main.zig
const std = @import("std");
const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    std.debug.assert(c.glfwInit() != 0);
    defer c.glfwTerminate();
}
```

```.vscode/launch.json
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "desktop",
            "type": "cppvsdbg",
            "request": "launch",
            "program": "${workspaceFolder}/zig-out/bin/desktop",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [
                {
                    "name": "PATH",
                    "value": "${workspaceFolder}\\build\\src\\Debug;${env:PATH}"
                }
            ],
            "console": "integratedTerminal"
        }
    ]
}
```

動作確認成功。

### glClear まで

<https://www.glfw.org/documentation.html>

を移植。

```zig:main.zig
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
```

追加。

```zig:build.zig
exe.linkSystemLibrary("OpenGL32");
```

実行。黒い glfw Window が出れば成功。

## その2: glsl で triangle

<https://www.glfw.org/docs/latest/quick_guide.html#quick_example>

を移植する。

```zig:main.zig
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
```

```zig:build.zig
// exe.linkSystemLibrary("OpenGL32");
// glad
exe.addIncludePath("glfw/deps");
exe.addCSourceFile("glfw/deps/glad_gl.c", &.{});
```

実行。三角形が出れば成功。

## その3: wasm 化準備

以下のように Engine 部分を `dll / wasm` なライブラリとする。

```
  +---------+
  |Engine   |同じ zig ソースから dll と wasm にビルドする
  +---------+
  ^         ^
  |dll      |wasm
+-------+ +-------+
|Desktop| |Browser|
|GLFW   | |WebGL  |
+-------+ +-------+
```

`OpenGL + glad` をライブラリとして切り離す。

```
zig-opengl-wasm$ mkdir engin
zig-opengl-wasm$ cd engin
zig-opengl-wasm/desktop $ zig init-lib
```

## その4: wasm 化実装

