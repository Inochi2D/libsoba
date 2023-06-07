/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Textures
*/
module soba.core.gpu.wgpu.texture;
import soba.core.gpu.wgpu;
import soba.core.gpu;
import soba.core.gpu.texture;
import bindbc.wgpu;
import imagefmt;
import std.exception;
import inmath;

/**
    A 2D texture
*/
class SbWGPUTexture : SbGPUTexture {
private:
    SbWGPUContext context;
    
    int width, height;

    SbGPUTextureFormat sbformat;

    WGPUTextureDescriptor desc;
    WGPUTextureFormat format;
    WGPUTexture texture;
    WGPUTextureView view;

    WGPUSamplerDescriptor sdesc;
    WGPUSampler sampler;

    bool stateChanged = false;
    SbGPUTextureWrapMode uwrap;
    SbGPUTextureWrapMode vwrap;
    SbGPUTextureFilter minfilter;
    SbGPUTextureFilter magfilter;
    ushort anisotropy = 1;

    SbGPUTextureFormat toNativeType(ref IFImage img) {
        return cast(SbGPUTextureFormat)(img.c-1);
    }

    void createTexture(SbGPUTextureFormat fmt) {
        
        // Destroy old texture if need be
        if (texture) {
            wgpuTextureDrop(texture);
            texture = null;
        }

        // Get texture format
        this.sbformat = fmt;
        switch(fmt) {
            // TODO: Do conversion
            case SbGPUTextureFormat.RGBA:   format = WGPUTextureFormat.RGBA8Unorm;           break;
            case SbGPUTextureFormat.RGB:    format = WGPUTextureFormat.RGBA8Unorm;           break;
            case SbGPUTextureFormat.RG:     format = WGPUTextureFormat.RG8Unorm;             break;
            case SbGPUTextureFormat.Red:    format = WGPUTextureFormat.R8Unorm;              break;
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
        texture = wgpuDeviceCreateTexture(context.getDevice(), &desc);
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
        sdesc.minFilter = cast(WGPUFilterMode)(minfilter & SbGPUTextureFilter.Linear);
        sdesc.magFilter = cast(WGPUFilterMode)(magfilter & SbGPUTextureFilter.Linear);
        sdesc.mipmapFilter = cast(WGPUMipmapFilterMode)(magfilter & SbGPUTextureFilter.Linear);
        sdesc.maxAnisotropy = anisotropy;
        sdesc.lodMinClamp = 0;
        sdesc.lodMaxClamp = float.max;
        sampler = wgpuDeviceCreateSampler(context.getDevice(), &sdesc);
    }

public:

    /// Constructor
    this(SbGPUContext context, int width, int height, SbGPUTextureFormat format) {
        this.context = cast(SbWGPUContext)context;
        this.width = width;
        this.height = height;
        this.createTexture(format);
        this.createView();
        this.createSampler();
    }

    /// 
    this(SbGPUContext context, ref IFImage image) {
        this.context = cast(SbWGPUContext)context;
        this.width = image.w;
        this.height = image.h;
        this.createTexture(toNativeType(image));
        this.createView();
        this.createSampler();
        this.setData(image);
    }

    /// 
    this(SbGPUContext context, ubyte[] data, int width, int height, SbGPUTextureFormat format) {
        this.context = cast(SbWGPUContext)context;
        this.width = width;
        this.height = height;
        this.createTexture(format);
        this.createView();
        this.createSampler();
        this.setTextureSubData(data, 0, 0, width, height, cast(int)format+1);
    }

    override
    uint getWidthPx() {
        return width;
    }

    override
    uint getHeightPx() {
        return width;
    }

    /**
        Sets the texture data for the texture
    */
    override
    void setData(ref IFImage image) {
        this.setSubData(image);
    }

    /**
        Sets the texture data for the texture
    */
    override
    void setSubData(ref IFImage image, int x = -1, int y = -1, int width = -1, int height = -1) {
        
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
        x = clamp(x, 0, desc.size.width);
        y = clamp(y, 0, desc.size.height);
        int wwidth = clamp(width, 1, desc.size.width-x);
        int wheight = clamp(height, 1, desc.size.height-y);

        // Write size
        auto size = WGPUExtent3D(
            wwidth,
            wheight,
            1
        );

        wgpuQueueWriteTexture(context.getQueue(), 
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
                0,
                width * channels,
                height
            ),
            &size
        );
    }

    /**
        Sets the wrapping mode of the texture
    */
    SbGPUTexture setWrapping(SbGPUTextureWrapMode u, SbGPUTextureWrapMode v) {
        this.uwrap = u;
        this.vwrap = v;
        stateChanged = true;
        return this;
    }

    /**
        Sets the anisotropy level
    */
    SbGPUTexture setAnisotropy(ushort anisotropy=1) {
        this.anisotropy = anisotropy;
        stateChanged = true;
        return this;
    }

    /**
        Sets the minifcation filter
    */
    SbGPUTexture setMinFilter(SbGPUTextureFilter filter) {
        this.minfilter = filter;
        stateChanged = true;
        return this;
    }

    /**
        Sets the magnification filter
    */
    SbGPUTexture setMagFilter(SbGPUTextureFilter filter) {
        this.magfilter = filter;
        stateChanged = true;
        return this;
    }

    /**
        Gets a view in to the renderable
    */
    WGPUTextureView getView() {
        return view;
    }

    /**
        Gets the native underlying WGPU format
    */
    WGPUTextureFormat getFormat() {
        return format;
    }

    /**
        Gets the native underlying WGPU sampler
    */
    WGPUSampler getSampler() {
        if (stateChanged) {

            // Change the sampler state if need be
            this.createSampler();
            stateChanged = false;
        }
        return sampler;
    }
    
}