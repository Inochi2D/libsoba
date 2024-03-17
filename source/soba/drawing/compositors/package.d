module soba.drawing.compositors;
import soba.drawing.surfaces;
import soba.core.window;
import inmath;

abstract
class SbCompositor {
@nogc nothrow:
protected:
    SbBackingWindow backing;

public:
    this(SbBackingWindow backing) {
        this.backing = backing;
    }

    abstract void resize(size_t width, size_t height);
    abstract void blitSurface(ref SbSurface surface, rect area);

    abstract void beginFrame();
    abstract void endFrame();
}