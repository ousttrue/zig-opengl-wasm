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

```zig:desktop/src/main.zig
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
```

`extern fn ENGINE_init(p: *const anyopaque) callconv(.C) void;`
`extern fn ENGINE_render(width: c_int, height: c_int) callconv(.C) void;`

を介して dll に分けた。

```zig:engine/src/main.zig
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
```

### openg gl 関数を extern 関数化

`@cImport` から OpenGL を読んでいる部分を、
自作の `extern` 関数に変更する。
Desktop 版では glad の関数を呼び出しをする c のソースから供給して、
WebGL 版では wasm 初期化の ImportObject 経由で canvas の WebGL 関数群を渡すための入れ物となる。

<https://docs.gl/>

などを参考に必要な関数をすべて用意する。

```zig
// こういうのすべて手で作った。
// emscripten などでは隠蔽されてよくわからなくなるところ
pub extern fn getString(name: GLenum) [*:0]const u8;
```

```c
// C の呼び出しラッパー
const GLubyte *getString(GLenum name) { return glad_glGetString(name); }
```

これをコンパイルして link すると extern の body として動作する。

```zig:build.zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addSharedLibrary("engine", "src/main.zig", .unversioned);
    lib.setTarget(target);
    lib.setBuildMode(mode);

    if (target.cpu_arch != std.Target.Cpu.Arch.wasm32) { // <- デスクトップのときだけ glad から供給する
        // glad
        lib.linkLibC();
        lib.addIncludePath("../desktop/glfw/deps");
        lib.addCSourceFile("../desktop/glfw/deps/glad_gl.c", &.{});
        lib.addCSourceFile("src/glad_placeholders.c", &.{}); // <- これ
    }

    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
```

## その４ wasm build と index.html から WebGL 関数の注入

```
engine$ zig build -Dtarget=wasm32-freestanding
```

で Wasm ビルドできる。 => `zig-out/lib/engine.wasm`

```zig:build.zig
    const target = b.standardTargetOptions(.{});
```

と `-Dtarget=` が連動している。
`wasm32-wasi` より `wasm32-freestanding` の方が空っぽなので ImportObject の用意が楽です。

### index.html

```html:index.html
<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8">
    <link rel="stylesheet" href="index.css">
    <script type="module" src="index.js"></script>
</head>

<body>
    <canvas id="gl"></canvas>
</body>

</html>
```

```css:index.css
html,
body {
    margin: 0;
    padding: 0;
    width: 100%;
    height: 100%;
    overflow: hidden;
}

canvas#gl {
    margin: 0;
    padding: 0;
    width: 100%;
    height: 100%;
}
```

### index.js とりあえず wasm 動かしてみる

```js:index.js
const importObject = {
    env: {

    },
};

// get
const response = await fetch('engine/zig-out/lib/engine.wasm')
// byte array
const buffer = await response.arrayBuffer();
// compile
const compiled = await WebAssembly.compile(buffer);
// instanciate env に webgl などを埋め込む
const instance = await WebAssembly.instantiate(compiled, importObject);
```

以下のエラーが出ます。

```
Uncaught LinkError: WebAssembly.instantiate(): Import #0 module="env" function="genBuffers" error: function import requires a callable
```

これは、 `wasm` 初期化時に import する関数を `importObject.env` に供給する必要があるという意味です。
ブラウザのデバッガで `compiled` 変数の import を見ると以下の関数が必要であることがわかります。
前節で定義した `extern` 関数郡です。

```js
[
    {
        "module": "env",
        "name": "genBuffers",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "bindBuffer",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "bufferData",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "createShader",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "shaderSource",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "compileShader",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "createProgram",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "attachShader",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "linkProgram",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "getUniformLocation",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "getAttribLocation",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "enableVertexAttribArray",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "vertexAttribPointer",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "viewport",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "clear",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "useProgram",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "uniformMatrix4fv",
        "kind": "function"
    },
    {
        "module": "env",
        "name": "drawArrays",
        "kind": "function"
    }
]
```

### importObject.env に webgl 関数を供給する

```js
```

### zig の logger 出力を browser の console に接続する

### chrome wasm デバッガー

### github action で wasm ビルドして github-pages で動かす
