module soba.ssk.metal.ctx;
import soba.ssk.ctx;

import numem.all;
import inmath;
import metal;
import soba.ssk.metal.texture;

/**
    Metal context
*/
class SSKMetalContext : SSKContext {
@nogc:
private:
    MTLDevice device;
    MTLCommandQueue commandQueue;
    MTLCommandBuffer commandBuffer;
    MTLRenderCommandEncoder encoder;

    MTLRenderPipelineDescriptor pipelineStateDescriptor;
    MTLRenderPassDescriptor renderPassDescriptor;

    vec4 clearColor;
    recti scissor;
    recti viewport;

    CAMetalLayer targetLayer;
    CAMetalDrawable nextDrawable;

    weak_vector!SSKNode queue;

    // In/out
    MTLTexture source;
    MTLTexture target;

    MTLTexture getRenderTarget() {
        if (target) {
            return target;
        } else {
            nextDrawable = target.nextDrawable();
            return nextDrawable.texture;
        }
    }

    void flushRenderTarget() {
        if (!target) {
            commandBuffer.presentDrawable(nextDrawable);
            nextDrawable.release();
            nextDrawable = null;
        }
    }

    void renderOne(SSKNode node) {

    }

public:

    ~this() {
        pipelineStateDescriptor.release();
        renderPassDescriptor.release();
        commandQueue.release();
        device.release();
    }

    /**
        Constructs the metal context
    */
    this(CAMetalLayer target) {
        super(SSKContextType.metal);
        this.target = target;
        this.device = MTLCreateSystemDefaultDevice();
        this.commandQueue = device.newCommandQueue();
        this.renderPassDescriptor = MTLRenderPassDescriptor.renderPassDescriptor();
        this.pipelineStateDescriptor = MTLRenderPipelineDescriptor.ini;
    }

    override void* getHandle() { return cast(void*)device; }
    override void setViewport(recti viewport) { this.viewport = viewport; }
    override recti getViewport() { return viewport; }
    override void setClearColor(vec4 clearColor) { this.clearColor = clearColor; }
    override vec4 getClearColor() { return clearColor; }

    override
    void enqueue(SSKNode node) {
        queue.pushBack(node);
    }

    override
    void flush() {

        MTLTexture renderTarget = getRenderTarget();

        // Clear color
        renderPassDescriptor.colorAttachments[0].clearColor = 
            MTLClearColor(clearColor.x, clearColor.y, clearColor.z, clearColor.w);

        // Apply clear color
        renderPassDescriptor.colorAttachments[0].loadAction = 
            MTLLoadAction.Clear;
            
        // Draw target
        renderPassDescriptor.colorAttachments[0].texture = 
            renderTarget;

        // Encoder
        encoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor);
        encoder.setViewport(MTLViewport(viewport.x, viewport.y, viewport.width, viewport.height, 0, 1));
        encoder.setRenderPipelineState(pipelineStateDescriptor);

        

        this.flushRenderTarget();
        commandBuffer.commit();

        encoder.release();
        encoder = null;
    }

    override
    void await() {
        commandBuffer.waitUntilCompleted();
    }

    override
    void setSource(SSKTexture texture) {
        if (texture) {
            this.source = texture.getHandle();
        }
    }

    override
    void setTarget(SSKTexture texture) {
        if (texture) {
            this.target = texture.getHandle();
        } else {
            this.target = null;
        }
    }
}