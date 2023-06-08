module soba.core.gpu.wgpu.fbo;
import soba.core.gpu.wgpu.target;
import soba.core.gpu.wgpu;
import soba.core.gpu.target;
import soba.core.gpu.fbo;
import soba.core.gpu.texture;

/**
    A WGPU framebuffer
*/
class SbWGPUFramebuffer : SbGPUFramebuffer {
private:
    SbWGPUContext context;

public:
    this(SbWGPUContext context) {
        this.context = context;
    }

    /**
        Adds a target to the framebuffer
    */
    override
    void addTarget(SbGPUTexture target) {
        super.addTarget(target);
    }
}