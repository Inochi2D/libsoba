/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Textures
*/
module soba.core.gpu.texture;
import soba.core.gpu;
import bindbc.wgpu;
import imagefmt;
import inmath.math;
import std.format;
import std.exception;

enum SbGFXTextureWrapMode {
    Repeat,
    MirroredRepeat,
    ClampToEdge
}

enum SbGFXTextureFilter {

    /**
        Nearest Neighbour filtering
    */
    Nearest = 0x0000000,

    /**
        Linear filtering
    */
    Linear = 0x00000001,

    /**
        Linear filtering
    */
    Mipmapped = 0x00000002,
}

/**
    Texture formats supported by soba
*/
enum SbGFXTextureFormat {

    /**
        Red
    */
    Red,

    /**
        Red and Green
    */
    RG,

    /**
        (Will be auto converted to RGBA from RGB)
    */
    RGB,

    /**
        8-bit unsigned RGBA
    */
    RGBA
}

class SbGFXTexture : SbGFXTextureView {
private:
    SbGFXContext ctx;
    
    int width, height;

    SbGFXTextureFormat sbformat;

    WGPUTextureDescriptor desc;
    WGPUTextureFormat format;
    WGPUTexture texture;
    WGPUTextureView view;

    WGPUSamplerDescriptor sdesc;
    WGPUSampler sampler;

    bool stateChanged = false;
    SbGFXTextureWrapMode uwrap;
    SbGFXTextureWrapMode vwrap;
    SbGFXTextureFilter minfilter;
    SbGFXTextureFilter magfilter;
    ushort anisotropy = 1;

    SbGFXTextureFormat toNativeType(ref IFImage img) {
        return cast(SbGFXTextureFormat)(img.c-1);
    }

    void createTexture(SbGFXTextureFormat fmt) {
        
        // Destroy old texture if need be
        if (texture) {
            wgpuTextureDrop(texture);
            texture = null;
        }

        // Get texture format
        this.sbformat = fmt;
        switch(fmt) {
            // TODO: Do conversion
            case SbGFXTextureFormat.RGBA:   format = WGPUTextureFormat.RGBA8Unorm;           break;
            case SbGFXTextureFormat.RGB:    format = WGPUTextureFormat.RGBA8Unorm;           break;
            case SbGFXTextureFormat.RG:     format = WGPUTextureFormat.RG8Unorm;             break;
            case SbGFXTextureFormat.Red:    format = WGPUTextureFormat.R8Unorm;              break;
            default: break;
        }

        import std.stdio : writeln;
        writeln(width, " ", height);

        // Create descriptor for texture
        desc = WGPUTextureDescriptor(
            null,
            "Texture",
            WGPUTextureUsage.TextureBinding | WGPUTextureUsage.CopyDst | WGPUTextureUsage.CopySrc,
            WGPUTextureDimension.D2,
            WGPUExtent3D(width, height, 1),
            format,
            1,
            1,
            0,
            null
        );
        texture = wgpuDeviceCreateTexture(ctx.getDevice(), &desc);
        enforce(texture !is null, "Texture failed creation!");
    }

    void createView() {
        
        // Destroy old view if need be
        if (view) {
            wgpuTextureViewDrop(view);
            view = null;
        }

        WGPUTextureViewDescriptor wdesc;
        wdesc.arrayLayerCount = 1;
        wdesc.baseArrayLayer = 0;

        wdesc.mipLevelCount = 1;
        wdesc.baseMipLevel = 0;

        wdesc.nextInChain = null;
        wdesc.aspect = WGPUTextureAspect.All;
        wdesc.format = format;
        wdesc.dimension = WGPUTextureViewDimension.D2;
        view = wgpuTextureCreateView(texture, &wdesc);
    }

    void createSampler() {

        // Destroy old sampler if need be
        if (sampler) {
            wgpuSamplerDrop(sampler);
            sampler = null;
        }
        
        sdesc.label = "Sampler";
        sdesc.addressModeU = cast(WGPUAddressMode)uwrap;
        sdesc.addressModeV = cast(WGPUAddressMode)vwrap;
        sdesc.minFilter = cast(WGPUFilterMode)(minfilter & SbGFXTextureFilter.Linear);
        sdesc.magFilter = cast(WGPUFilterMode)(magfilter & SbGFXTextureFilter.Linear);
        sdesc.mipmapFilter = cast(WGPUMipmapFilterMode)(magfilter & SbGFXTextureFilter.Linear);
        sdesc.maxAnisotropy = anisotropy;
        sdesc.lodMinClamp = 0;
        sdesc.lodMaxClamp = float.max;
        sampler = wgpuDeviceCreateSampler(ctx.getDevice(), &sdesc);
    }

public:

    /// Constructor
    this(SbGFXContext ctx, int width, int height, SbGFXTextureFormat format) {
        this.ctx = ctx;
        this.width = width;
        this.height = height;
        this.createTexture(format);
        this.createView();
        this.createSampler();
    }

    /// 
    this(SbGFXContext ctx, ref IFImage image) {
        this.ctx = ctx;
        this.width = image.w;
        this.height = image.h;
        this.createTexture(toNativeType(image));
        this.createView();
        this.createSampler();
        this.setTextureData(image);
    }

    /// 
    this(SbGFXContext ctx, ubyte[] data, int width, int height, SbGFXTextureFormat format) {
        this.ctx = ctx;
        this.width = width;
        this.height = height;
        this.createTexture(format);
        this.createView();
        this.createSampler();
        this.setTextureSubData(data, 0, 0, width, height, cast(int)format+1);
    }

    /**
        Sets the texture data for the texture
    */
    void setTextureData(ref IFImage image) {
        this.setTextureSubData(image);
    }

    /**
        Sets the texture data for the texture
    */
    void setTextureSubData(ref IFImage image, int x = -1, int y = -1, int width = -1, int height = -1) {
        
        // Handle clamping of texture coordinates
        if (width < 1) width = image.w;
        if (height < 1) height = image.h;

        int channels = image.c;
        ubyte[] data;

        import std.stdio : writeln;
        writeln(image.buf8.length);

        // Handle internal auto-conversion
        switch(format) {

            // RGBA
            case WGPUTextureFormat.RGBA8UnormSrgb:
            case WGPUTextureFormat.RGBA8Unorm:
                if (image.c == 3) {
                    data.length = image.buf8.length+(image.w*image.h);
                    conv_rgb2rgba(image.buf8, data);
                    channels = 4;
                } else {
                    data = image.buf8;
                }
                break;

            // Grayscale-Alpha
            case WGPUTextureFormat.RG8Unorm:
                data = image.buf8;
                break;

            // Grayscale
            case WGPUTextureFormat.R8Unorm:
                data = image.buf8;
                break;

            default: break;
        }
        this.setTextureSubData(data, x, y, width, height, channels);
    }

    void setTextureSubData(ubyte[] data, int x, int y, int width, int height, int channels) {
        // if (x < 0) x = clamp(x, 0, desc.size.width);
        // if (y < 0) x = clamp(y, 0, desc.size.height);
        // width = clamp(width, 1, desc.size.width-x);
        // height = clamp(height, 1, desc.size.height-y);

        auto size = WGPUExtent3D(
            width,
            height,
            1
        );

        wgpuQueueWriteTexture(ctx.getQueue(), 
            new WGPUImageCopyTexture(
                null,
                texture,
                0,
                WGPUOrigin3D(0, 0, 0),
                WGPUTextureAspect.All
            ),
            data.ptr,
            data.length,
            new WGPUTextureDataLayout(
                null,
                0,
                channels * width,
                height
            ),
            &size
        );
    }

    /**
        Sets the wrapping mode of the texture
    */
    SbGFXTexture setWrapping(SbGFXTextureWrapMode u, SbGFXTextureWrapMode v) {
        this.uwrap = u;
        this.vwrap = v;
        stateChanged = true;
        return this;
    }

    /**
        Sets the anisotropy level
    */
    SbGFXTexture setAnisotropy(ushort anisotropy=1) {
        this.anisotropy = anisotropy;
        stateChanged = true;
        return this;
    }

    /**
        Sets the minifcation filter
    */
    SbGFXTexture setMinFilter(SbGFXTextureFilter filter) {
        this.minfilter = filter;
        stateChanged = true;
        return this;
    }

    /**
        Sets the magnification filter
    */
    SbGFXTexture setMagFilter(SbGFXTextureFilter filter) {
        this.magfilter = filter;
        stateChanged = true;
        return this;
    }

    /**
        Gets a view in to the renderable
    */
    override
    WGPUTextureView currentView() {
        return view;
    }

    /**
        Drops the render source backing texture if needed
    */
    override
    void dropIfNeeded() { /* Base textures do not need to be dropped*/ }

    /**
        Gets the native underlying WGPU format
    */
    override
    WGPUTextureFormat getNativeFormat() {
        return format;
    }

    /**
        Gets the native underlying WGPU sampler
    */
    override
    WGPUSampler getNativeSampler() {
        if (stateChanged) {

            // Change the sampler state if need be
            this.createSampler();
            stateChanged = false;
        }
        return sampler;
    }
    
}