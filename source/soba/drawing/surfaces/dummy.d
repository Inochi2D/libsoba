module soba.drawing.surfaces.dummy;
import soba.drawing.common;
import soba.drawing.surfaces;
import metal;
import numem.all;

class SbDummySurface : SbSurface {
nothrow @nogc:
private:
public:
    ~this() {
    }

    this(SbSurfaceFormat format, size_t width, size_t height, MTLDevice device) {
        super(format, width, height);
    }

    final
    void dumpToFile(nstring file) {
        this.getContext().saveToPNG(file);
    }
}