module soba.ssk.renderers.metal;
import soba.ssk.renderers;
import soba.sio;
import numem.all;

version(SbApple):

class SskMetalRenderer : SskRenderer {
@nogc:
public:
    
    this(SioWindow window) {
        super(window);
    }
}
