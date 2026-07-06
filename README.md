# MTLCanvas

MTLCanvas - experimental iOS tool for quick Metal fragment shader development.
The goal is close to the `glsl-canvas` workflow in VS Code: edit a `.metal`
file on the Mac, see the result in `MTKView` almost immediately, and get
compiler errors without manually restarting the app.

## Current Workflow

1. Run the `MTLCanvas` scheme from Xcode.
2. The scheme Run pre-action starts the local shader server automatically.
3. Make sure the path matches `defaultShaderURLString` in `MetalDevice.swift`.

```swift
http://127.0.0.1:8080/WaveEffects/ChatGlowEffect.metal
```

4. Edit the shader source on the Mac.
5. The app polls the URL once per second, compiles the new source with
   `device.makeLibrary(source:options:)`, and recreates the render pipeline
   after successful compilation.
6. Stop the app from Xcode. The scheme Run post-action stops the shader server.
   If Xcode does not call the post-action, the server exits automatically after
   the debug idle timeout.

If compilation fails, the app keeps the last successfully built pipeline and
prints the error in the Xcode console.

## Shader Server

The server lifecycle is handled by:

```bash
scripts/dev-shader-server.sh
```

The Xcode scheme calls:

```bash
scripts/dev-shader-server.sh restart
scripts/dev-shader-server.sh stop
```

Defaults:

- host: `0.0.0.0`
- port: `8080`
- root: `SRCROOT`
- idle timeout: `300` seconds without HTTP requests
- pid file: `/tmp/mtlcanvas-shader-server-8080.pid`
- log file: `/tmp/mtlcanvas-shader-server-8080.log`

You can override the server settings in the scheme pre-action environment:

```bash
MTLCANVAS_SHADER_PORT=8080
MTLCANVAS_SHADER_HOST=0.0.0.0
MTLCANVAS_SHADER_ROOT=/path/to/shader/project
MTLCANVAS_SHADER_IDLE_TIMEOUT=300
```

The app can override the shader URL through launch environment:

```bash
MTLCANVAS_SHADER_URL=http://127.0.0.1:8080/WaveEffects/ChatGlowEffect.metal
```

## Localhost Notes

On iOS Simulator, `127.0.0.1` usually points to the Mac, so the current URL is
usable for simulator development.

On a physical iOS device, `127.0.0.1` points to the device itself, not the Mac.
Use the Mac local network IP instead, for example:

```swift
http://192.168.1.20:8080/WaveEffects/ChatGlowEffect.metal
```

If the Mac and iPhone both use Tailscale, the URL can use the Mac Tailscale IP:

```swift
http://100.x.y.z:8080/WaveEffects/ChatGlowEffect.metal
```

Plain HTTP on a device may also require an App Transport Security exception in
`Info.plist`, or a local HTTPS/proxy setup.

## Shader Entry Points

The current render pipeline expects these functions:

- `bg_vertex`
- `bg_second_fragment`

`Uniforms` must keep the same memory layout in Swift and Metal:

```metal
struct Uniforms {
    float u_time;
    float size;
    float2 u_mouse;
    float2 u_pmouse;
    float touchDistance;
    float2 dir;
    float2 resolution;
};
```

## What Is Implemented

- `MTKView` is embedded in SwiftUI through `UIViewRepresentable`.
- `MetalDevice` creates `MTLDevice`, `MTLCommandQueue`, the fallback bundled
  library, and the fullscreen quad buffers.
- Shader source can be loaded from localhost.
- A successfully compiled shader library gets a revision number.
- `MetalEffect` recreates `MTLRenderPipelineState` when the library revision
  changes.
- Compilation errors do not crash the app or replace the last working pipeline.
- `u_time` is updated in the draw loop.

## Recommended Improvements

1. Move the shader URL to app settings or launch arguments so switching files
   does not require Swift code changes.
2. Replace polling with a helper server using WebSocket or Server-Sent Events,
   so updates arrive immediately after saving the file.
3. Add a SwiftUI overlay for compiler errors instead of relying only on the
   Xcode console.
4. Show the last successful revision, compile time, and active shader source
   URL in the UI.
5. Support configurable entry points (`vertex`/`fragment`) and pixel format.
6. Add a small CLI/helper server that serves shader source, watches files, and
   returns diagnostics.
7. For physical devices, add Bonjour discovery or manual host/IP input for the
   Mac development server.
8. Separate runtime shader source from bundled fallback shader, so production
   builds do not depend on the dev server.

## Main Files

- `MetalDevice.swift` - Metal device, command queue, shader library loading,
  and localhost polling.
- `MetalEffect.swift` - textures, uniforms, and render pipeline state.
- `MetalRenderer.swift` - `MTKViewDelegate` and draw loop.
- `MetalContainer.swift` - SwiftUI bridge for `MTKView` and touch input.
- `MetalEffect.metal` - bundled fallback shader.
