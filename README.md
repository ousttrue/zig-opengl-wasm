# zig-opengl-wasm

sample

- [zig で OpenGL、そして wasm](https://qiita.com/ousttrue/items/4802b61ba340dd7d89f3)

## 202304更新

- `zig-0.11.0-dev.2336`
- glfw を cmake でビルドせずに build.zig でコンパイルする
  - [x] Windows11
  - [x] Ubuntu22.04
  - [ ] WSL(動くがOpenGLの絵が出ない)
  - [x] wasm https://ousttrue.github.io/zig-opengl-wasm/

## desktop build

```
$ cd engine
engine$ zig build
engine$ cd ../desktop
dekstop$ zig build
```

### run

```
dekstop$ zig-out/bin/desktop
```

windows は `engine.dll` にパスを通す必要があります。

```
desktop$ cp ../engine/zig-out/lib/engine.dll zig-out/bin/
desktop$ zig-out/bin/desktop
```

## wasm build

```
$ cd engine
engine$ zig build -Dtarget=wasm32-freestanding
```

