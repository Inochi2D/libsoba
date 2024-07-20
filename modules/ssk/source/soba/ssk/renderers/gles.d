module soba.ssk.renderers.gles;
import soba.ssk.renderers;
import soba.sio;
import numem.all;
import numem.mem.utils;
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
}