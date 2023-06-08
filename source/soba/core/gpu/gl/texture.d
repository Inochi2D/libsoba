/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Textures
*/
module soba.core.gpu.gl.texture;
import soba.core.gpu.gl.target;
import soba.core.gpu.gl;
import soba.core.gpu.target;
import soba.core.gpu;
import soba.core.gpu.texture;
import bindbc.opengl;
import imagefmt;
import std.exception;


/**
    A 2D texture
*/
class SbGLTexture : SbGPUTexture {
private:
    SbGPUTextureFormat format;
    SbGLContext context;
    GLuint id;
    uint width, height;

    GLuint fmtToGLFmt(SbGPUTextureFormat format) {
        switch(format) {
            case SbGPUTextureFormat.Red:
                return GL_RED;
            case SbGPUTextureFormat.RG:
                return GL_RG;
            case SbGPUTextureFormat.RGB:
                return GL_RGB;
            case SbGPUTextureFormat.RGBA:
                return GL_RGBA;
            case SbGPUTextureFormat.DepthStencil:
                return GL_DEPTH24_STENCIL8;
            default: return GL_RGBA;
        }
    }

    GLuint channelsToGLFmt(int channels) {
        switch(channels) {
            case 1:
                return GL_RED;
            case 2:
                return GL_RG;
            case 3:
                return GL_RGB;
            case 4:
                return GL_RGBA;
            default: return GL_RGBA;
        }
    }

    GLint wrapModeToGL(SbGPUTextureWrapMode mode) {
        switch(mode) {
            case SbGPUTextureWrapMode.ClampToEdge:
                return GL_CLAMP_TO_EDGE;
            case SbGPUTextureWrapMode.Repeat:
                return GL_REPEAT;
            case SbGPUTextureWrapMode.MirroredRepeat:
                return GL_MIRRORED_REPEAT;
            default: assert(0, "WrapMode not implemented! This is a bug.");
        }
    }

    GLint filterModeToGL(SbGPUTextureFilter mode) {
        switch(mode) {
            case (SbGPUTextureFilter.Linear | SbGPUTextureFilter.Mipmapped):
                return GL_LINEAR_MIPMAP_LINEAR;
            case (SbGPUTextureFilter.Nearest | SbGPUTextureFilter.Mipmapped):
                return GL_NEAREST_MIPMAP_LINEAR;
            case SbGPUTextureFilter.Linear:
                return GL_LINEAR;
            case SbGPUTextureFilter.Nearest:
                return GL_NEAREST;
            default: assert(0, "WrapMode not implemented! This is a bug.");
        }
    }

public:

    /// Constructor
    this(SbGPUContext context, int width, int height, SbGPUTextureFormat format) {
        this.context = cast(SbGLContext)context;
        this.width = width;
        this.height = height;
        this.format = format;

        glGenTextures(1, &id);
        glBindTexture(GL_TEXTURE_2D, id);
        glTexImage2D(GL_TEXTURE_2D, 0, fmtToGLFmt(format), width, height, 0, fmtToGLFmt(format), GL_UNSIGNED_BYTE, null);
    }

    /// 
    this(SbGPUContext context, ref IFImage image) {
        this.context = cast(SbGLContext)context;
        this.width = image.w;
        this.height = image.h;
        this.format = format;

        glGenTextures(1, &id);
        this.setData(image);
    }

    /// 
    this(SbGPUContext context, ubyte[] data, int width, int height, SbGPUTextureFormat format) {
        this.context = cast(SbGLContext)context;
        this.width = width;
        this.height = height;
        this.format = format;

        glGenTextures(1, &id);
    }

    override
    uint getWidthPx() { return width; }

    override
    uint getHeightPx() { return height; }
    
    override
    void setSubData(ref IFImage data, int x, int y, int width, int height) {
        glBindTexture(GL_TEXTURE_2D, id);
        switch(data.bpc) {
            case 8:
                glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, width, height, channelsToGLFmt(data.c), GL_UNSIGNED_BYTE, data.buf8.ptr);
                break;
            case 16:
                glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, width, height, channelsToGLFmt(data.c), GL_UNSIGNED_SHORT, data.buf16.ptr);
                break;
            default: break;
        }
    }
    
    override
    void setData(ref IFImage data) {
        glBindTexture(GL_TEXTURE_2D, id);
        switch(data.bpc) {
            case 8:
                glTexImage2D(GL_TEXTURE_2D, 0, fmtToGLFmt(format), width, height, 0, channelsToGLFmt(data.c), GL_UNSIGNED_BYTE, data.buf8.ptr);
                break;
            case 16:
                glTexImage2D(GL_TEXTURE_2D, 0, fmtToGLFmt(format), width, height, 0, channelsToGLFmt(data.c), GL_UNSIGNED_SHORT, data.buf16.ptr);
                break;
            default: break;
        }
    }

    /**
        Sets the wrapping mode of the texture
    */
    override
    SbGPUTexture setWrapping(SbGPUTextureWrapMode u, SbGPUTextureWrapMode v) {
        glBindTexture(GL_TEXTURE_2D, id);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapModeToGL(u));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapModeToGL(v));
        return this;
    }

    /**
        Sets the anisotropy level
    */
    override
    SbGPUTexture setAnisotropy(ushort anisotropy=1) {
        glBindTexture(GL_TEXTURE_2D, id);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY, anisotropy);
        return this;
    }

    /**
        Sets the minifcation filter
    */
    override
    SbGPUTexture setMinFilter(SbGPUTextureFilter filter) {
        glBindTexture(GL_TEXTURE_2D, id);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filterModeToGL(filter));
        return this;
    }

    /**
        Sets the magnification filter
    */
    override
    SbGPUTexture setMagFilter(SbGPUTextureFilter filter) {
        glBindTexture(GL_TEXTURE_2D, id);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filterModeToGL(filter));
        return this;
    }

    /**
        Returns the format of this texture
    */
    override
    SbGPUTextureFormat getFormat() {
        return format;
    }

    /**
        Gets the ID of the texture
    */
    GLuint getId() {
        return id;
    }
}