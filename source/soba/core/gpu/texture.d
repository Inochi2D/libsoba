/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Textures
*/
module soba.core.gpu.texture;
import soba.core.gpu;
import bindbc.wgpu;
import gamut;
import inmath.math;

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
        8-bit unsigned RGBA
    */
    RGBA8,

    /**
        32-bit floating point RGBA
    */
    RGBA32,
    
    /**
        8-bit unsigned RG
    */
    RG8,

    /**
        32-bit floating point RG
    */
    RG32,
    
    /**
        8-bit unsigned Red
    */
    Red8,

    /**
        32-bit floating point Red
    */
    Red32
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

    SbGFXTextureFormat gamutToNativeFormat(PixelType type) {
        switch(type) {
            case PixelType.rgbaf32: return SbGFXTextureFormat.RGBA32;
            case PixelType.rgba8:   return SbGFXTextureFormat.RGBA8;

            case PixelType.laf32:   return SbGFXTextureFormat.RG32;
            case PixelType.la8:     return SbGFXTextureFormat.RG8;

            case PixelType.lf32:    return SbGFXTextureFormat.Red32;
            case PixelType.l8:      return SbGFXTextureFormat.Red8;

            default: throw new Exception("Unsupported pixel type!");
        }
    }

    int getChannelsFromType() {
        
        // Handle internal auto-conversion
        switch(format) {

            // RGBA
            case WGPUTextureFormat.RGBA8Uint:       return 4;
            case WGPUTextureFormat.RGBA32Float:     return 4;

            // Grayscale-Alpha
            case WGPUTextureFormat.RG8Uint:         return 2;
            case WGPUTextureFormat.RG32Float:       return 2;

            // Grayscale
            case WGPUTextureFormat.R8Uint:          return 1;
            case WGPUTextureFormat.R32Float:        return 1;

            default: return 4;
        }
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
            case SbGFXTextureFormat.RGBA32: format = WGPUTextureFormat.RGBA32Float;     break;
            case SbGFXTextureFormat.RGBA8:  format = WGPUTextureFormat.RGBA8Uint;       break;

            case SbGFXTextureFormat.RG32:   format = WGPUTextureFormat.RG32Float;       break;
            case SbGFXTextureFormat.RG8:    format = WGPUTextureFormat.RG8Uint;         break;

            case SbGFXTextureFormat.Red32:  format = WGPUTextureFormat.R32Float;        break;
            case SbGFXTextureFormat.Red8:   format = WGPUTextureFormat.R8Uint;          break;

            default: break;
        }

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
        wdesc.baseMipLevel = 0;
        wdesc.mipLevelCount = 1;
        wdesc.nextInChain = null,
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
    this(SbGFXContext ctx, ref Image image) {
        this.ctx = ctx;
        this.width = width;
        this.height = height;
        this.createTexture(gamutToNativeFormat(image.type));
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
        this.setTextureSubData(data, 0, 0, width, height, getChannelsFromType());
    }

    /**
        Sets the texture data for the texture
    */
    void setTextureData(ref Image image) {
        this.setTextureSubData(image);
    }

    /**
        Sets the texture data for the texture
    */
    void setTextureSubData(ref Image image, int x = -1, int y = -1, int width = -1, int height = -1) {
        
        // Handle clamping of texture coordinates
        if (width < 1) width = image.width;
        if (height < 1) height = image.height;

        int channels = 4;
        // Handle internal auto-conversion
        switch(format) {

            // RGBA
            case WGPUTextureFormat.RGBA8Uint:
                if (!image.is8Bit) image.convertTo8Bit();
                if (image.type != PixelType.rgba8) image.convertToRGBA();
                break;
            case WGPUTextureFormat.RGBA32Float:
                if (!image.isFP32) image.convertToFP32();
                if (image.type != PixelType.rgbaf32) image.convertToRGBA();
                break;

            // Grayscale-Alpha
            case WGPUTextureFormat.RG8Uint:
                if (!image.is8Bit) image.convertTo8Bit();
                if (image.type != PixelType.la8) image.convertToGreyscaleAlpha();
                channels = 2;
                break;
            case WGPUTextureFormat.RG32Float:
                if (!image.isFP32) image.convertToFP32();
                if (image.type != PixelType.laf32) image.convertToGreyscaleAlpha();
                channels = 2;
                break;

            // Grayscale
            case WGPUTextureFormat.R8Uint:
                if (!image.is8Bit) image.convertTo8Bit();
                if (image.type != PixelType.l8) image.convertToGreyscale();
                channels = 1;
                break;
            case WGPUTextureFormat.R32Float:
                if (!image.isFP32) image.convertToFP32();
                if (image.type != PixelType.lf32) image.convertToGreyscale();
                channels = 1;
                break;

            default: break;
        }

        // Get data out
        ubyte[] data = image.allPixelsAtOnce();
        this.setTextureSubData(data, x, y, width, height, channels);
    }

    void setTextureSubData(ubyte[] data, int x, int y, int width, int height, int channels) {
        if (x < 0) x = clamp(x, 0, desc.size.width);
        if (y < 0) x = clamp(y, 0, desc.size.height);
        width = clamp(width, 1, desc.size.width-x);
        height = clamp(height, 1, desc.size.height-y);

        auto size = WGPUExtent3D(
            width,
            height,
            1
        );

        size_t boffset = y * (channels * width) + (channels * x);

        wgpuQueueWriteTexture(ctx.getQueue(), 
            new WGPUImageCopyTexture(
                null,
                texture,
                0,
                WGPUOrigin3D(x, y, 0),
                WGPUTextureAspect.All
            ),
            data.ptr,
            data.length,
            new WGPUTextureDataLayout(
                null,
                cast(ulong)boffset,
                (channels) * width,
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