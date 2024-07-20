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
    uint width, height;

public:
    this(SskTextureFormat format, SskTextureKind kind, uint width, uint height) {
        super(format, kind, width, height);

        this.width = width;
        this.height = height;
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

    }
}