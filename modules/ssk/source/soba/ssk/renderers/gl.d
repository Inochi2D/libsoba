module soba.ssk.renderers.gl;
import soba.ssk.renderers;
import soba.sio;
import numem.all;
import bindbc.opengl;

class SskGLRenderer : SskRenderer {
@nogc:
public:
    
    this(SioWindow window) {
        super(window);

        window.makeCurrent();
        enforce(loadOpenGL() != GLSupport.noLibrary, nstring("Failed to establish OpenGL context."));
    }
}