# zig-opengl-wasm

sample

## その1: GLFW window を glClear

<https://www.glfw.org/documentation.html>

を移植する。

```
$ mkdir zig-opengl-wasm # project-root
$ cd zig-opengl-wasm
zig-opengl-wasm$ mkdir desktop
$ cd desktop
zig-opengl-wasm/desktop $ zig init-exe
```

### GLFW を dll build する

```
$ git submodule add https://github.com/glfw/glfw.git
$ cmake -B build -S glfw -DBUILD_SHARED_LIBS=ON
$ cmake --build build
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



