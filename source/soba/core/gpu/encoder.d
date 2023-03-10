module soba.core.gpu.encoder;
import soba.core.gpu;
import bindbc.wgpu;
import std.string;
import inmath;
import std.exception;

class SbGFXEncoder {
private:
    const(char)* name;
    SbGFXContext ctx;

    WGPUCommandEncoder encoder;
    WGPURenderPassEncoder pass;
    SbGFXSurface surface;

    bool recording = false;
    bool recordingPass = false;
    
    // ENCODER STATE
    vec4 clearColor = vec4(0, 0, 0, 1);
    rect scissorRect = rect(0, 0, 640, 480);
    bool viewportSet = false;
    rect viewport = rect(0, 0, 640, 480);

public:
    this(SbGFXContext ctx, SbGFXSurface surface, string name) {
        this.name = name.toStringz;
        this.ctx = ctx;
        this.surface = surface;

        this.scissorRect = rect(0, 0, surface.width, surface.height);
        this.viewport = rect(0, 0, surface.width, surface.height);
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
        viewportSet = true;
        this.viewport = viewport;
    }

    /**
        Clears the encoder's viewport
    */
    void clearViewport() {
        this.viewportSet = false;
        this.viewport = rect.init;
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
        if (viewportSet) wgpuRenderPassEncoderSetViewport(
            pass, 
            viewport.x, 
            viewport.y, 
            viewport.width, 
            viewport.height, 
            0, 
            1
        );

        // Handle scissor test
        if (!scissor) {
            wgpuRenderPassEncoderSetScissorRect(
                pass, 
                cast(uint)scissorRect.x, 
                cast(uint)scissorRect.y, 
                surface.width, 
                surface.height
            );
        } else {
            wgpuRenderPassEncoderSetScissorRect(
                pass, 
                cast(uint)scissorRect.x, 
                cast(uint)scissorRect.y, 
                clamp(cast(uint)scissorRect.width, 0, surface.width), 
                clamp(cast(uint)scissorRect.height, 0, surface.height)
            );
        }
    }

    /**
        Sets the pipeline
    */
    void setPipeline(SbGFXPipeline pipeline) {
        if (!recordingPass) return;
        if (!pipeline.isReady) pipeline.finalize();
        wgpuRenderPassEncoderSetPipeline(pass, pipeline.getHandle());
        wgpuRenderPassEncoderSetBindGroup(pass, 0, pipeline.getBindGroupHandle(), 0, null);
    }

    /**
        Sets a vertex buffer
    */
    void setVertexBuffer(uint slot, SbGFXBufferBaseI buffer) {
        if (!recordingPass) return;
        
        if (!buffer) wgpuRenderPassEncoderSetVertexBuffer(pass, slot, null, 0, 0);
        else {
            enforce(buffer.getType() == SbGFXBufferType.Vertex, "Invalid buffer type!");
            wgpuRenderPassEncoderSetVertexBuffer(pass, slot, buffer.getHandle(), 0, buffer.getSize());
        }
    }

    /**
        Sets the index buffer
    */
    void setIndexBuffer(SbGFXBufferBaseI buffer) {
        if (!recordingPass) return;
        
        if (!buffer) wgpuRenderPassEncoderSetIndexBuffer(pass, null, WGPUIndexFormat.Undefined, 0, 0);
        else {
            enforce(buffer.getType() == SbGFXBufferType.Index, "Invalid buffer type!");
            wgpuRenderPassEncoderSetIndexBuffer(pass, buffer.getHandle(), WGPUIndexFormat.Uint32, 0, buffer.getSize());
        }
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