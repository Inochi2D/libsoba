module soba.ssk.renderers;
import soba.ssk.texture;
import soba.sio;
import numem.all;
import inmath;

import soba.ssk.renderers.gl;
import soba.ssk.renderers.gles;
version(SbApple) import soba.ssk.renderers.metal;

@nogc:

/**
    Soba Scene Kit renderer interface
*/
abstract
class SskRenderer {
@nogc:
private:
    SioWindow window;

protected:

    /**
        Gets the window this renderer is rendering to.
    */
    SioWindow getWindow() {
        return window;
    }

public:

    /**
        Instantiates a renderer.
    */
    this(SioWindow window) {
        this.window = window;
    }

    /**
        Creates a new texture
    */
    abstract SskTexture createTexture(SskTextureFormat format, SskTextureKind kind, uint width, uint height);

    /**
        Sets the scissor rectangle
    */
    abstract void setScissor(recti scissor);

    /**
        Begins rendering pass
    */
    abstract void begin();

    /**
        Ends rendering pass
    */
    abstract void end();

    /**
        Renders texture to the specified area
    */
    abstract void renderTextureTo(SskTexture texture, recti at);

    /**
        Sets texture to render target.
        Type of texture MUST be framebuffer.

        Set to null to render to the window once again.
    */
    abstract void renderToTexture(SskTexture texture);
}

SskRenderer sskCreateRendererFor(SioWindow window) {
    final switch(window.getSurfaceType()) {

        // OpenGL
        case SioWindowSurfaceType.GL:
                return nogc_new!SskGLRenderer(window);

        // OpenGL ES
        case SioWindowSurfaceType.GLES:
                return nogc_new!SskGLESRenderer(window);

        // Apple Metal
        case SioWindowSurfaceType.metal:
            version(SbApple) {
                return nogc_new!SskMetalRenderer(window);
            } else {
                throw nogc_new!NuException(nstring("Metal is not supported on this platform."));
            }
    }
}