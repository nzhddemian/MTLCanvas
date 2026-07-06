# MTLCanvas

MTLCanvas is an experimental iOS app for rapid Metal shader development. It is
intended to provide a workflow similar to shader playground tools: edit a
`.metal` file on your Mac, keep the app running in Simulator or on a device, and
see the canvas update after the shader recompiles.

The project is currently a development prototype, not a packaged editor.

## Features

- SwiftUI app hosting an `MTKView`.
- Runtime loading of Metal shader source over HTTP.
- Automatic local shader server for Xcode debug runs.
- Polling-based shader reload while the app is running.
- Runtime `MTLLibrary` compilation with `device.makeLibrary(source:options:)`.
- Render pipeline recreation after a successfully compiled shader revision.
- Fallback to the bundled Metal library when the development server is not
  available.
- Failed shader compiles keep the last working pipeline alive.

## Requirements

- macOS with Xcode.
- iOS Simulator or an iOS device.
- Python 3 available at `/usr/bin/python3`.
- Metal-capable runtime.

The project currently targets the SDK/deployment settings stored in the Xcode
project. Adjust those locally if your Xcode installation uses different SDKs.

## Quick Start

1. Open the project in Xcode.
2. Select the `MTLCanvas` scheme.
3. Run the app.
4. Edit the shader file served by `defaultShaderURLString` in
   `MetalDevice.swift`.
5. Watch the Xcode console for reload messages:

```text
Loaded updated localhost shader library, revision 2
Reloaded Metal pipeline for shader library revision 2
```

By default, the app reads:

```text
http://127.0.0.1:8080/MTLCanvas/MetalEngineModule/Metal/MetalEffect.metal
```

## Development Shader Server

The Xcode Run scheme starts a local HTTP server before launching the app and
tries to stop it when the app stops.

Server scripts:

```bash
scripts/dev-shader-server.sh
scripts/dev_shader_server.py
```

Useful manual commands:

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

Server settings can be changed with environment variables:

```bash
MTLCANVAS_SHADER_PORT=8080
MTLCANVAS_SHADER_HOST=0.0.0.0
MTLCANVAS_SHADER_ROOT=/path/to/shader/project
MTLCANVAS_SHADER_IDLE_TIMEOUT=300
```

The app shader URL can be changed with:

```bash
MTLCANVAS_SHADER_URL=http://127.0.0.1:8080/path/to/file.metal
```

## Simulator and Device URLs

For iOS Simulator, `127.0.0.1` points to the Mac, so this usually works:

```text
http://127.0.0.1:8080/MTLCanvas/MetalEngineModule/Metal/MetalEffect.metal
```

For a physical iOS device, `127.0.0.1` points to the device itself. Use an IP
address that reaches your Mac from the device:

```text
http://192.168.1.20:8080/MTLCanvas/MetalEngineModule/Metal/MetalEffect.metal
```

If both Mac and iPhone are connected through a private network such as Tailscale,
you can use the Mac private network IP:

```text
http://100.x.y.z:8080/MTLCanvas/MetalEngineModule/Metal/MetalEffect.metal
```

Plain HTTP on a real device may require an App Transport Security exception in
the app's Info.plist settings, or an HTTPS/proxy setup.

## Shader Contract

The current render pipeline expects these Metal entry points:

- `bg_vertex`
- `bg_second_fragment`

The Swift and Metal `Uniforms` layouts must stay in sync:

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

## Project Map

- `MTLCanvas/MetalEngineModule/Utils/MetalDevice.swift` - Metal device,
  command queue, shader loading, polling, and fallback library setup.
- `MTLCanvas/MetalEngineModule/Metal/MetalEffect.swift` - textures, uniforms,
  and render pipeline state.
- `MTLCanvas/MetalEngineModule/Metal/MetalRenderer.swift` - `MTKViewDelegate`
  draw loop.
- `MTLCanvas/MetalEngineModule/Metal/Views/MetalContainer.swift` - SwiftUI to
  UIKit bridge for `MTKView`.
- `MTLCanvas/MetalEngineModule/Metal/MetalEffect.metal` - bundled fallback
  shader and default live-edit target.
- `scripts/` - local development shader server.

## Troubleshooting

### The app logs `Could not connect to the server`

Check that the shader server is listening:

```bash
curl -I http://127.0.0.1:8080/
```

If needed, restart it:

```bash
scripts/dev-shader-server.sh restart
```

### The server is running but the shader does not load

Check the exact shader URL:

```bash
curl http://127.0.0.1:8080/MTLCanvas/MetalEngineModule/Metal/MetalEffect.metal
```

If this returns `404`, update `defaultShaderURLString` or set
`MTLCANVAS_SHADER_URL`.

### The shader changes but the image does not

Check the Xcode console for:

```text
Loaded updated localhost shader library
Reloaded Metal pipeline
```

If the shader compiles but the image does not visibly change, confirm that the
edited code is actually used by `bg_second_fragment`.

### A bad shader edit breaks compilation

The app should keep the previous working pipeline. Fix the Metal compiler error
shown in the Xcode console and save the file again.

## Security Notes

The development server is intended for local debugging. It serves files from the
configured root directory over HTTP and binds to `0.0.0.0` by default so a real
iOS device can reach it. Do not run it on an untrusted network without changing
the host binding or firewall rules.

For local-only Simulator development, set:

```bash
MTLCANVAS_SHADER_HOST=127.0.0.1
```

## Roadmap Ideas

- SwiftUI overlay for shader compiler diagnostics.
- File watching or WebSocket/SSE reload instead of polling.
- UI for selecting shader URL and entry points.
- Bonjour discovery for physical devices.
- Better separation between development-only server behavior and release builds.

## License

MIT. See [LICENSE](LICENSE).
