import MetalKit
import SwiftUI

struct ColdLaunchView: View {
    let onFinish: () -> Void
    @Environment(\.colorScheme) private var scheme
    @State private var startedAt = CACurrentMediaTime()
    @State private var fading = false

    var body: some View {
        GeometryReader { geometry in
            let size: CGFloat = geometry.size.width < 375 ? 224 : 248
            ZStack {
                Theme.canvas(scheme)
                CrownMeshView(startedAt: startedAt, onUnavailable: onFinish)
                    .frame(width: size, height: size)
                    .offset(y: -12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .opacity(fading ? 0 : 1)
        .accessibilityHidden(true)
        .task {
            do {
                try await Task.sleep(for: .seconds(max(0, 2.05 - (CACurrentMediaTime() - startedAt))))
                try Task.checkCancellation()
                withAnimation(.linear(duration: 0.35)) { fading = true }
                try await Task.sleep(for: .seconds(max(0, 2.4 - (CACurrentMediaTime() - startedAt))))
                try Task.checkCancellation()
                onFinish()
            } catch { }
        }
    }
}

private struct CrownMeshView: UIViewRepresentable {
    let startedAt: CFTimeInterval
    let onUnavailable: () -> Void

    func makeCoordinator() -> Renderer { Renderer(startedAt: startedAt) }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.isOpaque = false
        view.backgroundColor = .clear
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.preferredFramesPerSecond = 60
        view.isPaused = true
        let coordinator = context.coordinator
        coordinator.preparation = Task { @MainActor [weak view, weak coordinator] in
            let resources = await Task.detached(priority: .userInitiated) { MeshResources.prepare() }.value
            guard !Task.isCancelled, let view, let coordinator else { return }
            guard let resources else { onUnavailable(); return }
            coordinator.resources = resources
            view.device = resources.device
            view.delegate = coordinator
            view.isPaused = false
        }
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    static func dismantleUIView(_ uiView: MTKView, coordinator: Renderer) {
        coordinator.preparation?.cancel()
        uiView.isPaused = true
        uiView.delegate = nil
    }

    final class Renderer: NSObject, MTKViewDelegate {
        let startedAt: CFTimeInterval
        var resources: MeshResources?
        var preparation: Task<Void, Never>?

        init(startedAt: CFTimeInterval) { self.startedAt = startedAt }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let resources, let drawable = view.currentDrawable,
                  let pass = view.currentRenderPassDescriptor, let buffer = resources.queue.makeCommandBuffer(),
                  let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }

            let elapsed = Float((CACurrentMediaTime() - startedAt) * 1000)
            let growth = smooth((elapsed - 80) / 1280)
            encoder.setRenderPipelineState(resources.pipeline)
            encoder.setVertexBuffer(resources.vertices, offset: 0, index: 0)
            encoder.setFragmentTexture(resources.texture, index: 0)
            for layer in 0..<3 {
                let bloom = layer == 0 ? 1 : smooth((elapsed - (layer == 1 ? 1430 : 1510)) / 310)
                var timing = SIMD4(elapsed, growth, bloom, Float(layer))
                encoder.setVertexBytes(&timing, length: MemoryLayout.size(ofValue: timing), index: 1)
                encoder.setFragmentBytes(&timing, length: MemoryLayout.size(ofValue: timing), index: 0)
                encoder.drawIndexedPrimitives(type: .triangle, indexCount: resources.indexCount, indexType: .uint16,
                                              indexBuffer: resources.indices, indexBufferOffset: 0)
            }
            encoder.endEncoding()
            buffer.present(drawable)
            buffer.commit()
        }

        private func smooth(_ value: Float) -> Float {
            let x = max(0, min(value, 1))
            return x * x * (3 - 2 * x)
        }
    }
}

/// Immutable GPU resources created on a background task before being handed to the renderer.
private struct MeshResources: @unchecked Sendable {
    let device: MTLDevice
    let queue: MTLCommandQueue
    let pipeline: MTLRenderPipelineState
    let texture: MTLTexture
    let vertices: MTLBuffer
    let indices: MTLBuffer
    let indexCount: Int

    static func prepare() -> MeshResources? {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue(),
              let url = Bundle.main.url(forResource: "CrownMesh.metal", withExtension: "txt"),
              let source = try? String(contentsOf: url, encoding: .utf8),
              let library = try? device.makeLibrary(source: source, options: nil),
              let texture = logoTexture(device) else { return nil }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "crownVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "crownFragment")
        let color = descriptor.colorAttachments[0]!
        color.pixelFormat = .bgra8Unorm
        color.isBlendingEnabled = true
        color.sourceRGBBlendFactor = .sourceAlpha
        color.destinationRGBBlendFactor = .oneMinusSourceAlpha
        color.sourceAlphaBlendFactor = .one
        color.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        guard let pipeline = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }

        let slices = 256
        let rings = 18
        var positions: [SIMD2<Float>] = []
        var triangles: [UInt16] = []
        for ring in 0...rings {
            let radius = Float(ring) / Float(rings) * 725
            for slice in 0...slices {
                let angle = Float.pi / 2 + Float(slice) / Float(slices) * 2 * Float.pi
                positions.append((512 + SIMD2(cos(angle), sin(angle)) * radius) / 1024)
                guard ring < rings, slice < slices else { continue }
                let a = UInt16(ring * (slices + 1) + slice)
                let b = a + UInt16(slices + 1)
                triangles.append(contentsOf: [a, b, a + 1, a + 1, b, b + 1])
            }
        }
        guard let vertices = device.makeBuffer(bytes: positions, length: positions.count * MemoryLayout<SIMD2<Float>>.stride),
              let indices = device.makeBuffer(bytes: triangles, length: triangles.count * MemoryLayout<UInt16>.stride) else { return nil }
        return MeshResources(device: device, queue: queue, pipeline: pipeline, texture: texture, vertices: vertices,
                             indices: indices, indexCount: triangles.count)
    }

    /// Remove only connected near-white background pixels, keeping enclosed white petals.
    private static func logoTexture(_ device: MTLDevice) -> MTLTexture? {
        let size = 1024
        let pixelCount = size * size
        guard let image = UIImage(named: "ActualLogoSource")?.cgImage,
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                                      bytesPerRow: size * 4, space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue),
              let pixels = context.data?.assumingMemoryBound(to: UInt8.self) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
        var visited = [Bool](repeating: false, count: pixelCount)
        var queue = [Int]()
        queue.reserveCapacity(pixelCount)
        func visit(_ index: Int) {
            guard index >= 0, index < pixelCount, !visited[index] else { return }
            visited[index] = true
            let pixel = pixels.advanced(by: index * 4)
            let low = min(pixel[0], pixel[1], pixel[2])
            let high = max(pixel[0], pixel[1], pixel[2])
            guard low >= 239, high - low <= 15 else { return }
            pixel[3] = 0
            queue.append(index)
        }
        visit(512 * size + 512)
        for i in 0..<size {
            visit(i)
            visit((size - 1) * size + i)
            visit(i * size)
            visit(i * size + size - 1)
        }
        var head = 0
        while head < queue.count {
            let index = queue[head]
            head += 1
            if index % size > 0 { visit(index - 1) }
            if index % size < size - 1 { visit(index + 1) }
            visit(index - size)
            visit(index + size)
        }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: size, height: size, mipmapped: false)
        descriptor.usage = .shaderRead
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        texture.replace(region: MTLRegionMake2D(0, 0, size, size), mipmapLevel: 0, withBytes: pixels, bytesPerRow: size * 4)
        return texture
    }
}
