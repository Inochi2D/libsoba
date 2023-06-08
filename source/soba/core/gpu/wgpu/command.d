module soba.core.gpu.wgpu.command;
import soba.core.gpu.wgpu;
import soba.core.gpu.wgpu.surface;
import soba.core.gpu.command;
import soba.core.gpu.target;
import bindbc.wgpu;

class SbWGPUCommandBuffer : SbGPUCommandBuffer {
private:
    SbWGPUContext context;
    SbWGPUSurface surface;

    bool recording = false;
    WGPUCommandEncoder encoder;
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

        encoder = wgpuDeviceCreateCommandEncoder(context.getDevice(), new WGPUCommandEncoderDescriptor(null, this.name));
    }

    /**
        Starts a render pass for the command buffer
    */
    override
    void beginPass(SbGPURenderTarget target) {

    }
    
    /**
        Ends a render pass for the command buffer
    */
    override
    void endPass() {
        
    }

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