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


