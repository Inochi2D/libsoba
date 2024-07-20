module soba.ssk.renderers.gl;
import soba.ssk.renderers;
import soba.ssk.texture;
import soba.sio;
import numem.all;
import inmath;

import bindbc.opengl;

class SskGLRenderer : SskRenderer {
@nogc:
public:
    
    this(SioWindow window) {
        super(window);

        window.makeCurrent();
        enforce(loadOpenGL() != GLSupport.noLibrary, nstring("Failed to establish OpenGL context."));
    }

    override
    SskTexture createTexture(SskTextureFormat format, SskTextureKind kind, uint width, uint height) {
        this.getWindow().makeCurrent();
        return nogc_new!SskGLTexture(format, kind, width, height);
    }

    override
    void begin() {
        this.getWindow().makeCurrent();
        glEnable(GL_SCISSOR_TEST);
    }

    override
    void end() {
        this.getWindow().makeCurrent();
        glDisable(GL_SCISSOR_TEST);
    }

    override
    void setScissor(recti scissor) {
        this.getWindow().makeCurrent();
        vec2i wsize = this.getWindow().getFramebufferSize();
        glScissor(scissor.left, wsize.y-scissor.y, scissor.width, scissor.height);
    }
}

class SskGLTexture : SskTexture {
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