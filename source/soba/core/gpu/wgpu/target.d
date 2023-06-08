module soba.core.gpu.wgpu.target;
import soba.core.gpu.target;
import soba.core.gpu.wgpu.texture;
import soba.core.gpu.wgpu.surface;
import bindbc.wgpu;
import soba.core.gpu.wgpu;

class SbWGPURenderTarget : SbGPURenderTarget {
private:
    SbWGPUContext context;

    // NOTE: since this internal the tag determines which 
    //       item in the union is active.
    //       0 = SbWGPUTexture
    //       1 = SbWGPUSurface
    uint tag;
    union {
        SbWGPUTexture texture;
        SbWGPUSurface surface;
    }

    WGPUTextureView view;

public:
    this(SbWGPUContext context, SbWGPUTexture texture) {
        this.context = context;
        this.texture = texture;
        this.tag = 0;
    }

    this(SbWGPUContext context, SbWGPUSurface surface) {
        this.context = context;
        this.surface = surface;
        this.tag = 1;
    }

    override
    uint getWidthPx() {
        switch(tag) {
            case 0:
                return texture.getWidthPx();
            case 1:
                return surface.getWidthPx();
            default: assert(0, "Invalid tag!");
        }
    }

    override
    uint getHeightPx() {
        switch(tag) {
            case 0:
                return texture.getHeightPx();

            case 1:
                return surface.getHeightPx();

            default: assert(0, "Invalid tag!");
        }
    }

    WGPUTextureView getView() {
        switch(tag) {
            case 0:
                return texture.getView();
                
            case 1:
                view = surface.getNextTexture();
                return view;

            default: assert(0, "Invalid tag!");
        }
    }

    void dropView() {
        switch(tag) {
            case 0:
                return;
                
            case 1:
                if (view) {
                    wgpuTextureViewDrop(view);
                    view = null;
                }
                return;

            default: assert(0, "Invalid tag!");
        }
    }
}