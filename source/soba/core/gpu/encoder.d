module soba.core.gpu.encoder;
import soba.core.gpu;
import bindbc.wgpu;
import std.string;
import inmath;

class SbGFXEncoder {
private:
    const(char)* name;
    SbGFXContext ctx;

    WGPUCommandEncoder encoder;
    WGPURenderPassEncoder pass;

    bool recording = false;
    bool recordingPass = false;
    
    // ENCODER STATE
    vec4 clearColor;
    rect viewport;
    rect scissorRect;

public:
    this(SbGFXContext ctx, string name) {
        this.name = name.toStringz;
        this.ctx = ctx;
    }

    /**
        Gets the encoder's clearing color
    */
    vec4 getClearColor() {
        return clearColor;
    }

    /**
        Sets the encoder's clearing color
    */
    void setClearColor(vec4 clearColor) {
        this.clearColor = clearColor;
    }

    /**
        Gets the encoder's viewport
    */
    rect getViewport() {
        return viewport;
    }

    /**
        Sets the encoder's viewport
    */
    void setViewport(rect viewport) {
        this.viewport = viewport;
    }

    /**
        Gets the encoder's scissor rectangle
    */
    rect getScissor() {
        return scissorRect;
    }

    /**
        Sets the encoder's scissor rectangle
    */
    void setScissor(rect scissorRect) {
        this.scissorRect = scissorRect;
    }

    /**
        Begins a frame
    */
    void beginFrame() {
        if (recording) return;
        recording = true;

        // Create a new command encoder (is invalidated every "finish")
        encoder = wgpuDeviceCreateCommandEncoder(ctx.getDevice(), new WGPUCommandEncoderDescriptor(null, this.name));
    }
    

    /**
        Begins rendering pass
    */
    void begin(SbGFXTextureView[] targets, bool clear=true, bool scissor=false) {
        if (recordingPass) return;
        recordingPass = true;
        
        // Scissor rect requires previous frame being loaded
        WGPULoadOp loadOp = clear ? WGPULoadOp.Clear : WGPULoadOp.Load;
        if (scissor) loadOp = WGPULoadOp.Load;


        // Setup render targets and clear state
        WGPURenderPassColorAttachment[] colorattachments;
        foreach(ref target; targets) {
            colorattachments ~= WGPURenderPassColorAttachment(
                target.currentView(),
                null,
                loadOp,
                WGPUStoreOp.Store,
                WGPUColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a)
            );
        }

        // Setup descriptor and instantiate pass
        WGPURenderPassDescriptor desc;
        desc.label = "Render Pass Encoder";
        desc.colorAttachmentCount = cast(int)targets.length;
        desc.colorAttachments = colorattachments.ptr;
        desc.timestampWriteCount = 0;

        pass = wgpuCommandEncoderBeginRenderPass(encoder, &desc);

        // Per-encode render state
        wgpuRenderPassEncoderSetViewport(pass, viewport.x, viewport.y, viewport.width, viewport.height, 0, 1);
        if (scissor) wgpuRenderPassEncoderSetScissorRect(
            pass, 
            cast(uint)scissorRect.x, 
            cast(uint)scissorRect.y, 
            cast(uint)scissorRect.width, 
            cast(uint)scissorRect.height
        );
    }

    /**
        Sets the pipeline
    */
    void setPipeline(SbGFXPipeline pipeline) {
        if (!recordingPass) return;
        wgpuRenderPassEncoderSetPipeline(pass, pipeline.getHandle());
    }

    /**
        Sets a vertex buffer
    */
    void setVertexBuffer(uint slot, SbGFXBufferBaseI buffer) {
        if (!recordingPass) return;
        if (!buffer) wgpuRenderPassEncoderSetVertexBuffer(pass, slot, null, 0, 0);
        else wgpuRenderPassEncoderSetVertexBuffer(pass, slot, buffer.getHandle(), 0, buffer.getSize());
    }

    /**
        Draws the current pipeline
    */
    void draw(uint vertices, uint instances, uint vertexOffset=0, uint instanceOffset=0) {
        if (!recordingPass) return;
        wgpuRenderPassEncoderDraw(pass, vertices, instances, vertexOffset, instanceOffset);
    }

    /**
        Draws the current pipeline indexed
    */
    void drawIndexed(uint indices, uint instances, uint indexOffset=0, uint instanceOffset=0, int baseVertex=0) {
        if (!recordingPass) return;
        wgpuRenderPassEncoderDrawIndexed(pass, indices, instances, indexOffset, baseVertex, instanceOffset);
    }

    /**
        Ends rendering pass
    */
    void end() {
        if (!recordingPass) return;
        recordingPass = false;
        
        // Remember to drop any needed textures
        wgpuRenderPassEncoderEnd(pass);
    }

    /**
        Ends a frame, finishes and submits the command buffer
    */
    void endFrame() {
        recording = false;
        WGPUCommandBuffer cmdbuffer = wgpuCommandEncoderFinish(encoder, new WGPUCommandBufferDescriptor(
            null,
            this.name
        ));
        wgpuQueueSubmit(ctx.getQueue(), 1, &cmdbuffer);
    }
}