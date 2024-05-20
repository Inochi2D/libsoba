module soba.drawing.surfaces.dummy;
import soba.drawing.common;
import soba.drawing.surfaces;
import numem.all;

class SbDummySurface : SbSurface {
nothrow @nogc:
private:
public:
    ~this() {
    }

    this(SbSurfaceFormat format, size_t width, size_t height) {
        super(format, width, height);
    }
}