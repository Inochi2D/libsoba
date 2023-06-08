module soba.core.gpu.wgpu.target;
import soba.core.gpu.target;
import soba.core.gpu.wgpu.texture;
import soba.core.gpu.wgpu.surface;
import soba.core.gpu.wgpu.fbo;
import soba.core.gpu.texture;
import bindbc.wgpu;
import soba.core.gpu.wgpu;
import std.exception;

class SbWGPURenderTarget : SbGPURenderTarget {
private:
    SbWGPUContext context;
    SbGPURenderTargetType tag;
    union {
        SbWGPUFramebuffer framebuffer;
        SbWGPUSurface surface;
    }

    WGPUTextureView view;

public:
    this(SbWGPUContext context, SbWGPUFramebuffer framebuffer) {
        this.context = context;
        this.framebuffer = framebuffer;
        this.tag = SbGPURenderTargetType.Framebuffer;
    }

    this(SbWGPUContext context, SbWGPUSurface surface) {
        this.context = context;
        this.surface = surface;
        this.tag = SbGPURenderTargetType.Surface;
    }

    /**
        Gets the render targets width in pixels
    */
    override
    uint getWidthPx() {
        switch(tag) {
            case SbGPURenderTargetType.Framebuffer:
                return framebuffer.getWidthPx();
            case SbGPURenderTargetType.Surface:
                return surface.getWidthPx();
            default: assert(0, "Invalid tag!");
        }
    }

    /**
        Gets the render targets height in pixels
    */
    override
    uint getHeightPx() {
        switch(tag) {
            case SbGPURenderTargetType.Framebuffer:
                return framebuffer.getHeightPx();

            case SbGPURenderTargetType.Surface:
                return surface.getHeightPx();

            default: assert(0, "Invalid tag!");
        }
    }

    /**
        Gets the type of the render target
    */
    override
    SbGPURenderTargetType getType() {
        return tag;
    }

    /**
        Whether the render target has a depth and stencil texture
    */
    override
    bool hasDepthStencil() {
        switch(tag) {
            case SbGPURenderTargetType.Framebuffer:
                foreach(target; framebuffer.getTargets()) {
                    if (target.getFormat() == SbGPUTextureFormat.DepthStencil) return true;
                }
                return false;
                
            case SbGPURenderTargetType.Surface:
                return false;

            default: assert(0, "Invalid tag!");
        }
    }

    /**
        Gets the amount of views
    */
    uint getViewCount() {
        switch(tag) {
            case SbGPURenderTargetType.Framebuffer:
                return cast(uint)framebuffer.getTargets().length;
                
            case SbGPURenderTargetType.Surface:
                return 1;

            default: assert(0, "Invalid tag!");
        }
    }

    /**
        Gets the view for the specified ID
    */
    WGPUTextureView getView(size_t id) {
        switch(tag) {
            case SbGPURenderTargetType.Framebuffer:
                return (cast(SbWGPUTexture)framebuffer.getTargets()[id]).getView();
                
            case SbGPURenderTargetType.Surface:
                view = surface.getNextTexture();
                return view;

            default: assert(0, "Invalid tag!");
        }
    }

    /**
        Drops the view if need be.
    */
    void dropView() {
        switch(tag) {
            case SbGPURenderTargetType.Framebuffer:
                return;
                
            case SbGPURenderTargetType.Surface:
                if (view) {
                    wgpuTextureViewDrop(view);
                    view = null;
                }
                return;

            default: assert(0, "Invalid tag!");
        }
    }

    /**
        Gets the underlying framebuffer
    */
    SbWGPUFramebuffer getFramebuffer() {
        enforce(tag == SbGPURenderTargetType.Framebuffer, "Not a framebuffer target!");
        return framebuffer;
    }

    /**
        Gets the underlying surface
    */
    SbWGPUSurface getSurface() {
        enforce(tag == SbGPURenderTargetType.Surface, "Not a surface!");
        return surface;
    }
}