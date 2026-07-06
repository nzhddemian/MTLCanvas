//
//  MetalDevice.swift
//  SparclesDemoApp
//
//  Created by Demian Nezhdanov on 20/07/2023.
//

import CoreImage
import Foundation
import MetalKit

private struct VertexData {
    let position: SIMD3<Float>
    let texCoord: SIMD2<Float>
}

public struct PrimitiveData {
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let indexCount: Int
}

private let defaultShaderURLString = "http://127.0.0.1:8080/MTLCanvas/MetalEngineModule/Metal/MetalEffect.metal"

private var shaderURLString: String {
    ProcessInfo.processInfo.environment["MTLCANVAS_SHADER_URL"] ?? defaultShaderURLString
}

public final class MetalDevice {
    public static let shared = MetalDevice()

    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    private(set) var defaultLibrary: MTLLibrary!
    private(set) var libraryRevision = 0
    private lazy var ciContext = CIContext(mtlDevice: device)

    private var shaderCheckTimer: Timer?
    private var lastShaderSource: String?
    private var lastReportedCompileFailureSource: String?

    // Full-screen quad used by the ping-pong draw passes.
    private static let quadVertices = [
        VertexData(position: SIMD3(-1.0, -1.0, 0.0), texCoord: SIMD2(0.0, 1.0)),
        VertexData(position: SIMD3( 1.0, -1.0, 0.0), texCoord: SIMD2(1.0, 1.0)),
        VertexData(position: SIMD3(-1.0,  1.0, 0.0), texCoord: SIMD2(0.0, 0.0)),
        VertexData(position: SIMD3( 1.0,  1.0, 0.0), texCoord: SIMD2(1.0, 0.0))
    ]

    private static let quadIndices: [UInt16] = [0, 1, 2, 2, 1, 3]

    deinit {
        shaderCheckTimer?.invalidate()
    }

    private init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("Metal is unavailable on this device")
        }

        self.device = device
        self.commandQueue = commandQueue

        loadInitialLibrary()
        setupShaderMonitoring()
    }

    private func loadInitialLibrary() {
        if let source = fetchShaderFromLocalhost(), installShaderLibrary(from: source, context: "initial localhost") {
            return
        }

        loadFrameworkLibrary()
    }

    private func loadFrameworkLibrary() {
        do {
            let frameworkBundle = Bundle(for: MetalDevice.self)
            defaultLibrary = try device.makeDefaultLibrary(bundle: frameworkBundle)
            libraryRevision += 1
        } catch {
            fatalError("Failed to load bundled Metal library: \(error)")
        }
    }

    @discardableResult
    private func installShaderLibrary(from source: String, context: String) -> Bool {
        do {
            defaultLibrary = try device.makeLibrary(source: source, options: nil)
            lastShaderSource = source
            lastReportedCompileFailureSource = nil
            libraryRevision += 1
            print("Loaded \(context) shader library, revision \(libraryRevision)")
            return true
        } catch {
            if lastReportedCompileFailureSource != source {
                print("Failed to compile \(context) shaders: \(error)")
                lastReportedCompileFailureSource = source
            }
            return false
        }
    }

    private func setupShaderMonitoring() {
        shaderCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForShaderChanges()
        }
    }

    private func fetchShaderFromLocalhost() -> String? {
        guard let url = URL(string: shaderURLString) else { return nil }

        let semaphore = DispatchSemaphore(value: 0)
        var result: String?

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            defer { semaphore.signal() }

            guard error == nil,
                  let data,
                  let source = String(data: data, encoding: .utf8) else {
                return
            }

            result = source
        }

        task.resume()
        _ = semaphore.wait(timeout: .now() + 1.0)
        return result
    }

    private func checkForShaderChanges() {
        guard let source = fetchShaderFromLocalhost(),
              source != lastShaderSource,
              source != lastReportedCompileFailureSource else {
            return
        }

        installShaderLibrary(from: source, context: "updated localhost")
    }

    public func newCommandBuffer() -> MTLCommandBuffer {
        commandQueue.makeCommandBuffer()!
    }

    public func makeLowPPlane() -> PrimitiveData {
        let vertexLength = MemoryLayout<VertexData>.stride * Self.quadVertices.count
        let indexLength = MemoryLayout<UInt16>.stride * Self.quadIndices.count

        guard let vertexBuffer = device.makeBuffer(
            length: vertexLength,
            options: []
        ) else {
            fatalError("Failed to create fullscreen quad vertex buffer")
        }

        guard let indexBuffer = device.makeBuffer(
            length: indexLength,
            options: []
        ) else {
            fatalError("Failed to create fullscreen quad index buffer")
        }

        _ = Self.quadVertices.withUnsafeBytes { vertexBytes in
            memcpy(vertexBuffer.contents(), vertexBytes.baseAddress!, vertexLength)
        }

        _ = Self.quadIndices.withUnsafeBytes { indexBytes in
            memcpy(indexBuffer.contents(), indexBytes.baseAddress!, indexLength)
        }

        return PrimitiveData(
            vertexBuffer: vertexBuffer,
            indexBuffer: indexBuffer,
            indexCount: Self.quadIndices.count
        )
    }

    public final class func texture(
        _ size: CGSize,
        pixelFormat: MTLPixelFormat = .bgra8Unorm
    ) -> MTLTexture? {
        let width = sanitizedTextureDimension(size.width)
        let height = sanitizedTextureDimension(size.height)

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )

        textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        return shared.device.makeTexture(descriptor: textureDescriptor)
    }

    public func ciImage(
        from texture: MTLTexture,
        colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    ) -> CIImage? {
        CIImage(
            mtlTexture: texture,
            options: [.colorSpace: colorSpace]
        )
    }

    // Core Image lets us read GPU-only draw textures without forcing shared storage.
    public func cgImage(
        from texture: MTLTexture,
        colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    ) -> CGImage? {
        guard let image = ciImage(from: texture, colorSpace: colorSpace) else {
            return nil
        }

        let bounds = CGRect(x: 0, y: 0, width: texture.width, height: texture.height)
        return ciContext.createCGImage(image, from: bounds, format: .BGRA8, colorSpace: colorSpace)
    }

    public final class func ciImage(
        from texture: MTLTexture,
        colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    ) -> CIImage? {
        shared.ciImage(from: texture, colorSpace: colorSpace)
    }

    public final class func cgImage(
        from texture: MTLTexture,
        colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    ) -> CGImage? {
        shared.cgImage(from: texture, colorSpace: colorSpace)
    }

    private static func sanitizedTextureDimension(_ value: CGFloat) -> Int {
        guard value.isFinite, value > 0 else { return 1 }
        return max(Int(value.rounded(.down)), 1)
    }
}
