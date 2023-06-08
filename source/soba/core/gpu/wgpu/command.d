module soba.core.gpu.wgpu.command;
import soba.core.gpu.wgpu;
import soba.core.gpu.wgpu.surface;
import soba.core.gpu.wgpu.target;
import soba.core.gpu.wgpu.shader;
import soba.core.gpu.command;
import soba.core.gpu.target;
import soba.core.gpu.shader;
import bindbc.wgpu;
import inmath;

class SbWGPUCommandBuffer : SbGPUCommandBuffer {
private:
    SbWGPUContext context;
    SbWGPUSurface surface;

    // ENCODER
    bool recording = false;
    WGPUCommandEncoder encoder;

    // RENDER PASS
    bool passRecording = false;
    bool passScissor;
    SbWGPURenderTarget passTarget;
    SbWGPUShaderObject passBoundShader;
    WGPURenderPassEncoder renderpass;

public:
    this(SbWGPUContext context) {
        this.context = context;
        this.surface = surface;
    }

    override
    void beginFrame() {
        if (recording) return;
        recording = true;

        encoder = wgpuDeviceCreateCommandEncoder(context.getDevice(), new WGPUCommandEncoderDescriptor(null, "Encoder"));
    }

    /**
        Clears the render target

        NOTE: Can only be called outside of a renderpass
    */
    override
    void clear(SbGPURenderTarget target) {
        if (passRecording) return;
        
        // Setup render targets and clear state
        WGPURenderPassColorAttachment[] colors = [
            WGPURenderPassColorAttachment(
                (cast(SbWGPURenderTarget)target).getView(),
                null,
                WGPULoadOp.Clear,
                WGPUStoreOp.Store,
                WGPUColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a)
            )
        ];

        // Remember to drop any needed textures
        WGPURenderPassDescriptor desc;
        desc.label = "Renderpass";
        desc.colorAttachmentCount = 1;
        desc.colorAttachments = colors.ptr;
        desc.timestampWriteCount = 0;

        renderpass = wgpuCommandEncoderBeginRenderPass(encoder, &desc);
        wgpuRenderPassEncoderEnd(renderpass);
    }

    /**
        Starts a render pass for the command buffer
    */
    override
    void beginPass(SbGPURenderTarget target, bool clear=true, bool scissor=false) {
        if (passRecording) return;
        passRecording = true;

        passScissor = scissor;
        passTarget = cast(SbWGPURenderTarget)target;

        // Scissor rect requires previous frame being loaded
        WGPULoadOp loadOp = clear && !scissor ? 
                                WGPULoadOp.Clear : 
                                WGPULoadOp.Load;


        // Setup render targets and clear state
        WGPURenderPassColorAttachment[] colors = [
            WGPURenderPassColorAttachment(
                (cast(SbWGPURenderTarget)target).getView(),
                null,
                loadOp,
                WGPUStoreOp.Store,
                WGPUColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a)
            )
        ];

        // Setup descriptor and instantiate pass
        WGPURenderPassDescriptor desc;
        desc.label = "Renderpass";
        desc.colorAttachmentCount = 1;
        desc.colorAttachments = colors.ptr;
        desc.timestampWriteCount = 0;

        renderpass = wgpuCommandEncoderBeginRenderPass(encoder, &desc);

        // Set viewport
        wgpuRenderPassEncoderSetViewport(
            renderpass, 
            0, 
            0, 
            target.getWidthPx(), 
            target.getHeightPx(), 
            0, 
            1
        );

        // Set default scissor
        wgpuRenderPassEncoderSetScissorRect(
            renderpass, 
            0, 
            0, 
            target.getWidthPx(), 
            target.getHeightPx()
        );
    }
    

    /**
        Sets the viewport of the current pass
    */
    override
    void setViewport(float x, float y, float width, float height) {
        if (!passRecording) return;

        wgpuRenderPassEncoderSetViewport(
            renderpass, 
            x, 
            y, 
            width, 
            height, 
            0, 
            1
        );
    }

    /**
        Sets the scissor rect of the current pass
    */
    override
    void setScissorRect(float x, float y, float width, float height) {
        if (!passRecording) return;

        if (passScissor) {
            wgpuRenderPassEncoderSetScissorRect(
                renderpass, 
                cast(uint)x, 
                cast(uint)y, 
                clamp(cast(uint)width, 0, passTarget.getWidthPx()), 
                clamp(cast(uint)height, 0, passTarget.getHeightPx())
            );
        }
    }

    /**
        Binds a shader to the current pass
    */
    override
    void bindShader(SbGPUShaderObject shader) {
        if (!passRecording) return;
    }
    
    /**
        Ends a render pass for the command buffer
    */
    override
    void endPass() {
        if (!passRecording) return;
        passRecording = false;
        
        // Remember to drop any needed textures
        wgpuRenderPassEncoderEnd(renderpass);
        passTarget.dropView();
    }

    /**
        Ends the current frame.
    */
    override
    void endFrame() {
        if (!recording) return;
        recording = false;

        WGPUCommandBuffer cmdbuffer = wgpuCommandEncoderFinish(encoder, new WGPUCommandBufferDescriptor(
            null,
            "Command Encoder"
        ));
        wgpuQueueSubmit(context.getQueue(), 1, &cmdbuffer);
    }
}