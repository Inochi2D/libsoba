module soba.drawing.surfaces.metal;
import soba.drawing.common;
import soba.drawing.surfaces;
import numem.all;
import inmath;

version(SbMetal):
import metal;

class SbMetalSurface : SbSurface {
nothrow @nogc:
private:
    MTLDevice device;
    MTLTexture renderTarget;
    MTLPixelFormat fmt;
    MTLBuffer vtxBuffer;

    void createSurfaceTexture() {

        if (cast(void*)renderTarget) {
            renderTarget.release();
        }

        MTLTextureDescriptor desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
            fmt, 
            this.getWidth(), 
            this.getHeight(), 
            false
        );
        desc.allowGPUOptimizedContents = true;

        renderTarget = device.newTextureWithDescriptor(desc);
        desc.release();
    }

    void refillBuffer() {
        vec4* ptr = cast(vec4*)vtxBuffer.contents();
        float width = getWidth();
        float height = getHeight();

        ptr[0] = vec4(0, height,        0, 0);
        ptr[1] = vec4(0, 0,             0, 1);
        ptr[2] = vec4(width, 0,         1, 1);

        ptr[3] = vec4(width, 0,         1, 1);
        ptr[4] = vec4(width, height,    1, 0);
        ptr[5] = vec4(0, height,        0, 0);
    }

public:
    ~this() {
        renderTarget.release();
        vtxBuffer.release();
    }

    this(SbSurfaceFormat format, size_t width, size_t height, MTLDevice device) {
        super(format, width, height);
        this.device = device;
        
        fmt = MTLPixelFormat.RGBA8Unorm_sRGB;
        switch(format) {
            case SbSurfaceFormat.RGB:
                fmt = MTLPixelFormat.RGBA8Unorm;
                break;
            case SbSurfaceFormat.ARGB:
                fmt = MTLPixelFormat.RGBA8Unorm;
                break;
            default:
                fmt = MTLPixelFormat.RGBA8Unorm;
                break;
        }

        this.createSurfaceTexture();
        vtxBuffer = device.newBuffer(vec4.sizeof*6, MTLResourceOptions.StorageModeShared);
        this.refillBuffer();
    }
    
    override
    void resize(size_t width, size_t height) {
        super.resize(width, height);
        this.createSurfaceTexture();
        this.refillBuffer();
    }

    override
    void flush() {
        super.flush();
    }

    /**
        Blits from the current aquired context on to the surface
    */
    override
    void blit(recti src, vec2i dst) {
        if (this.parent) {
            size_t offset = ((src.y*src.width)+src.x)*4;

            renderTarget.replaceRegion(
                MTLRegion(
                    MTLOrigin(dst.x, dst.y), 
                    MTLSize(src.width, src.height, 1)
                ), 
                0, 
                this.parent.getBufferHandle()+offset,
                this.parent.getStride()
            );
        }
    }

    override
    SbSurface createSubSurface(size_t width, size_t height) {
        return nogc_new!SbMetalSurface(this.getFormat(), width, height, device);
    }

    /**
        Returns the vertex buffer needed to render surface
    */
    MTLBuffer getBuffer() {
        return vtxBuffer;
    }

    /**
        Returns the texture needed to render surface
    */
    MTLTexture getTexture() {
        return renderTarget;
    }
}