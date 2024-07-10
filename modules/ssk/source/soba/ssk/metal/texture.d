module soba.ssk.metal.texture;
import soba.ssk.texture;
import metal;

class SSKMTLTexture : SSKTexture {
@nogc:
private:
    MTLTextureDescriptor descriptor;
    MTLTexture texture;

    MTLDevice getDeviceHandle() {
        return cast(MTLDevice)ctx.getHandle();
    }

    void initTexture() {
        MTLPixelFormat pfmt;

        switch(getFormat()) {
            default:
            case SSKTextureFormat.rgba32:
                pfmt = MTLPixelFormat.RGBA8Unorm_sRGB;
                break;
            case SSKTextureFormat.argb32:
                pfmt = MTLPixelFormat.BGRA8Unorm_sRGB;
                break;
            case SSKTextureFormat.rgb32:
                pfmt = MTLPixelFormat.RGBA8Unorm_sRGB;
                break;
            case SSKTextureFormat.r8:
                pfmt = MTLPixelFormat.R8Unorm;
                break;
        }

        auto descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
            pfmt,
            width,
            height,
            false
        );
        texDescriptor.usage = 
            MTLTextureUsage.RenderTarget |
            MTLTextureUsage.ShaderRead;

        texture = this.getDeviceHandle().newTextureWithDescriptor(descriptor);
    }

public:

    ~this() {
        descriptor.release();
        texture.release();
    }

    this(SSKContext ctx, SSKTextureFormat fmt, uint width, uint height) {
        super(ctx, fmt, width, height);
    }

    override
    void* getHandle() {
        return cast(void*)texture;
    }

    override
    void resize(uint width, uint height) {
        this.width = width;
        this.height = height;

        if (texture) {
            
            // Free old texture
            texture.release();
            texture = null;

            // Init new texture
            this.initTexture();
        }
    }

    override
    void blit(ubyte* data, SSKTextureFormat fmt, uint width, uint height, uint stride) {
        MTLRegion region;
        region.origin.x = 0;
        region.origin.y = 0;
        region.origin.z = 1;
        region.size.width = width;
        region.size.height = height;
        region.size.depth = 1;
        texture.replaceRegion(region, 0, data, stride);
    }
}