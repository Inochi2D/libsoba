module soba.drawing.surfaces;
import soba.drawing.compositors;
import soba.drawing.contexts;
import soba.drawing.common;
import soba.core.window;
import soba.core.math;
import numem.all;

nothrow @nogc:

/**
    A backing texture ready to be composited in to the application window.

    To draw on to this surface a SbDrawingContext needs to target the surface.
    see `SbDrawingContext.setTarget`.
*/
abstract
class SbSurface {
nothrow @nogc:
private:
    size_t width, height;
    bool dirty;
    SbSurfaceFormat format;

protected:
    SbDrawingContext parent;

public:
    this(SbSurfaceFormat format, size_t width, size_t height) {
        this.width = width;
        this.height = height;
        this.format = format;
    }

    /**
        Allows a drawing context to aquire the surface for writing
    */
    void aquire(SbDrawingContext ctx) {
        if(parent) {
            parent.setTarget(null);
        }

        this.parent = ctx;
    }

    /**
        Resizes the surface
    */
    void resize(size_t width, size_t height) {
        this.width = width;
        this.height = height;
        if (parent) {
            parent.resize(width, height);
        }
    }

    /**
        Flushes the surface, updating the rendering state and marking it clean again
    */
    void flush() {
        this.dirty = false;
    }

    /**
        Marks the surface as dirty
    */
    final
    void markDirty() {
        this.dirty = true;
    }

    /**
        Gets whether this surface is dirty and should be redrawn
    */
    final
    bool getDirty() {
        return this.dirty;
    }

    /**
        Width of the surface
    */
    final
    size_t getWidth() {
        return width;
    }

    /**
        Height of the surface
    */
    final
    size_t getHeight() {
        return height;
    }

    /**
        Format of the surface
    */
    final
    SbSurfaceFormat getFormat() {
        return format;
    }

    /**
        Creates a surface derived from the surface
    */
    abstract SbSurface createSubSurface(size_t width, size_t height);

    /**
        Blits from the current aquired context on to the surface
    */
    abstract void blit(recti src, vec2i dst);
}

SbSurface sbCreateSurface(SbBackingWindow backing) {
    version(SbApple) {
        import soba.drawing.surfaces.metal : SbMetalSurface;

        auto size = backing.getFramebufferSize();
        return nogc_new!SbMetalSurface(SbSurfaceFormat.RGB, cast(size_t)size.x, cast(size_t)size.y, backing.getDevice());
    }
    return null;
}