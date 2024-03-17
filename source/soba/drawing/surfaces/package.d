module soba.drawing.surfaces;
import soba.drawing.compositors;
import soba.drawing.contexts;
import soba.drawing.common;
import soba.core.window;
import numem.all;
import inmath;

nothrow @nogc:

abstract
class SbSurface {
nothrow @nogc:
private:
    size_t width, height;
    bool dirty;
    SbSurfaceFormat format;
    shared_ptr!SbDrawingContext context;

public:
    this(SbSurfaceFormat format, size_t width, size_t height) {
        this.context = createContext(format, width, height);
        this.width = width;
        this.height = height;
        this.format = format;
    }

    /**
        Resizes the surface
    */
    void resize(size_t width, size_t height) {
        context.get().resize(width, height);
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
        Gets the drawing context associated with the surface
    */
    final
    SbDrawingContext getContext() {
        return context.get();
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
}

SbSurface createSurfaceForBackingWindow(SbBackingWindow backing) {
    version(SbMetal) {
        import soba.drawing.surfaces.metal : SbMetalSurface;

        auto size = backing.getFramebufferSize();
        return nogc_new!SbMetalSurface(SbSurfaceFormat.RGB, cast(size_t)size.x, cast(size_t)size.y, backing.getDevice());
    }
    return null;
}

/**
    Surface for graphics accelerated rendering
*/
abstract
class SbSurface3D {
nothrow @nogc:
private:
    size_t width, height;
    bool dirty;
    SbSurfaceFormat format;
    shared_ptr!SbDrawingContext context;

public:
    ~this() {
        nogc_delete(context);
    }

    this(SbSurfaceFormat format, size_t width, size_t height) {
        this.width = width;
        this.height = height;
        this.format = format;
    }

    /**
        Gets the backing context
    */
    void* getBackingContext() { return null; }

    /**
        Resizes the surface
    */
    void resize(size_t width, size_t height) { }

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
        Creates a surface derived from the surface
    */
    abstract SbSurface createSubSurface(size_t width, size_t height);
}