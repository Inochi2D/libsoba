module soba.drawing.compositors.metal;
import soba.drawing.common;
import soba.drawing.surfaces;
import soba.drawing.surfaces.metal;
import soba.drawing.compositors;
import numem.all;
import metal;
import inmath;
import soba.core.window;

struct MetalUniformData {
    mat4 mat;
}

class SbMetalCompositor : SbCompositor {
@nogc nothrow:
private:
    MTLDevice device;
    MTLBuffer uniformBuffer;
    MTLCommandQueue queue;
    MTLCommandBuffer buffer;
    MTLRenderCommandEncoder encoder;
    MTLLibrary baseShader;
    MTLRenderPipelineState pipeline;
    CAMetalDrawable drawable;
    MTLRenderPassDescriptor pass;

    void initPipeline() {
        uniformBuffer = device.newBuffer(MetalUniformData.sizeof, MTLResourceOptions.StorageModeShared);

        MTLCompileOptions opt = MTLCompileOptions.alloc.ini();
        baseShader = device.newLibraryWithSource(import("shaders/fbdraw.metal").ns, opt);

        opt.release();

        MTLRenderPipelineDescriptor desc = MTLRenderPipelineDescriptor.alloc.initialize();
        desc.vertexFunction = baseShader.newFunctionWithName("vertex_main".ns);
        desc.fragmentFunction = baseShader.newFunctionWithName("fragment_main".ns);
		desc.colorAttachments[0].pixelFormat = backing.getLayer().pixelFormat;
        desc.colorAttachments[0].blendingEnabled = true;
        desc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.One;
        desc.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.One;
        desc.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.OneMinusSourceAlpha;
        desc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.OneMinusSourceAlpha;
        pipeline = device.newRenderPipelineStateWithDescriptor(desc);

        desc.release();

        pass = MTLRenderPassDescriptor.new_();
        pass.colorAttachments[0].loadAction = MTLLoadAction.Load;
        pass.colorAttachments[0].storeAction = MTLStoreAction.Store;

        queue = device.newCommandQueue();
    }

public:
    ~this() {
        pass.release();
    }

    this(SbBackingWindow backing, size_t width, size_t height) {
        super(backing);
        this.device = backing.getDevice();
        this.initPipeline();
        this.resize(width, height);
    }

    override
    void resize(size_t width, size_t height) {
        MetalUniformData* data = cast(MetalUniformData*)uniformBuffer.contents();
        data.mat = mat4.orthographic01(0, width, 0, height, 0, 100).transposed();
    }

    override
    void blitSurface(ref SbSurface surface, rect area) {
        if (SbMetalSurface mtls = cast(SbMetalSurface)surface) {
            encoder.setRenderPipelineState(pipeline);
            encoder.setVertexBuffer(mtls.getBuffer(), 0, 0);
            encoder.setVertexBuffer(uniformBuffer, 0, 1);
            encoder.setFragmentTexture(mtls.getTexture(), 0);
            encoder.drawPrimitives(MTLPrimitiveType.Triangle, 0, 6);
        }
    }

    override
    void beginFrame() {
        drawable = backing.getLayer().nextDrawable();
        buffer = queue.commandBuffer();
        
        pass.colorAttachments[0].texture = drawable.texture;
        encoder = buffer.renderCommandEncoderWithDescriptor(pass);
    }

    override
    void endFrame() {
        encoder.endEncoding();
        encoder.release();

        buffer.presentDrawable(drawable);
        buffer.commit();
        buffer.waitUntilCompleted();

        drawable.release();
        (cast(NSObject)buffer).release();
    }
}