module soba.ssk.renderers.gles;
import soba.ssk.renderers;
import soba.ssk.texture;
import soba.sio;
import numem.all;
import numem.mem.utils;
import inmath;

import bindbc.gles.gles;

class SskGLESRenderer : SskRenderer {
@nogc:
public:
    this(SioWindow window) {
        super(window);
        window.makeCurrent();

        // NOTE: For some reason the dev of this binding didn't make it nogc??
        auto esLoader = assumeNothrowNoGC(&loadGLES);
        enforce(esLoader() != GLESSupport.noLibrary, nstring("Failed to establish OpenGL ES context."));
    }

    override
    SskTexture createTexture(SskTextureFormat format, SskTextureKind kind, uint width, uint height) {
        return nogc_new!SskGLESTexture(format, kind, width, height);
    }

    override
    void begin() {
        glEnable(GL_SCISSOR_TEST);
    }

    override
    void end() {
        glDisable(GL_SCISSOR_TEST);
    }

    override
    void setScissor(recti scissor) {
        vec2i wsize = this.getWindow().getFramebufferSize();
        glScissor(scissor.left, wsize.y-scissor.y, scissor.width, scissor.height);
    }
}


class SskGLESTexture : SskTexture {
@nogc:
private:
    GLuint handle;
    GLuint fbTexHandle;

    uint width, height;

    void create() {
        if (this.getKind() == SskTextureKind.image) {
            glGenTextures(1, &handle);
            glBindTexture(GL_TEXTURE_2D, handle);
            glTexImage2D(
                GL_TEXTURE_2D,
                0,
                GL_RGBA,
                width,
                height,
                0,
                this.getFormat() == SskTextureFormat.RGB ? GL_RGB : GL_RGBA,
                GL_UNSIGNED_BYTE,
                null
            );
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);  

        } else {
            glGenTextures(1, &fbTexHandle);
            glGenFramebuffers(1, &handle);

            glBindTexture(GL_TEXTURE_2D, handle);
            glTexImage2D(
                GL_TEXTURE_2D,
                0,
                GL_RGBA,
                width,
                height,
                0,
                GL_RGBA,
                GL_UNSIGNED_BYTE,
                null
            );
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 

            glBindFramebuffer(GL_FRAMEBUFFER, handle);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fbTexHandle, 0);
        }
    }

public:
    ~this() {
        final switch(this.getKind()) {
            case SskTextureKind.image:
                glDeleteTextures(1, &handle);
                break;

            case SskTextureKind.framebuffer:
                glDeleteFramebuffers(1, &handle);
                glDeleteTextures(1, &fbTexHandle);
                break;
        }
    }

    this(SskTextureFormat format, SskTextureKind kind, uint width, uint height) {
        super(format, kind, width, height);

        this.width = width;
        this.height = height;

        this.create();
    }

    /**
        Gets the render-api specific handle
    */
    override
    SskTextureRef getHandle() {
        return cast(SskTextureRef)handle;
    }

    /**
        Resizes the texture
    */
    override
    void resize(uint width, uint height) {
        this.width = width;
        this.height = height;

        glBindTexture(GL_TEXTURE_2D, this.getKind() == SskTextureKind.framebuffer ? fbTexHandle : handle);
        glTexImage2D(
            GL_TEXTURE_2D,
            0,
            GL_RGBA,
            width,
            height,
            0,
            GL_RGBA,
            GL_UNSIGNED_BYTE,
            null
        );
    }

    /**
        Gets the width of the texture
    */
    override
    uint getWidth() {
        return width;
    }

    /**
        Gets the height of the texture
    */
    override
    uint getHeight() {
        return height;
    }

    override
    void upload(SskTextureFormat format, ubyte[] data, uint width, uint height) {
        if (this.getKind() == SskTextureKind.image) {
            glBindTexture(GL_TEXTURE_2D, handle);
            glTexImage2D(
                GL_TEXTURE_2D,
                0,
                GL_RGBA,
                width,
                height,
                0,
                GL_RGBA,
                GL_UNSIGNED_BYTE,
                null
            );

            glGenerateMipmap(GL_TEXTURE_2D);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }
}