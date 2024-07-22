module soba.ssk.renderers.metal;
import soba.ssk.renderers;
import soba.ssk.texture;
import soba.sio;
import numem.all;
import inmath;

version(SbApple):

import metal;

class SskMetalRenderer : SskRenderer {
@nogc:
public:
    
    this(SioWindow window) {
        super(window);
    }

    override
    SskTexture createTexture(SskTextureFormat format, SskTextureKind kind, uint width, uint height) {
        return null;
    }

    override
    void begin() {
    }

    override
    void end() {
    }

    override
    void setScissor(recti scissor) {
    }

    /**
        Renders texture to the specified area
    */
    override
    void renderTextureTo(SskTexture texture, recti at) {

    }

    /**
        Sets texture to render target.
        Type of texture MUST be framebuffer.

        Set to null to render to the window once again.
    */
    override
    void renderToTexture(SskTexture texture) {

    }
}
