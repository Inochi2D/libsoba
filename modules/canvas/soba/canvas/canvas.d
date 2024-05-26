/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.canvas;
import soba.canvas;
import numem.all;
import imagefmt;

import soba.canvas.cairo.canvas;

enum SbCanvasFormat {
    /**
        Alpha only data
    */
    A8,

    /**
        8-bit RGB data aligned to a 32 bit boundary
    */
    RGB32,

    /**
        8-bit ARGB data aligned to a 32 bit boundary
    */
    ARGB32,
}

/**
    A soba canvas.

    A canvas is the destination of rendering commands issued by a SbContext.
*/
abstract
class SbCanvas {
@nogc nothrow:
private:
    uint w, h;
    uint stride;
    SbCanvasBackend backend;
    SbCanvasFormat fmt;
    bool isLocked;

    uint calcStride() {
        final switch(fmt) {
            case SbCanvasFormat.A8:
                return w;

            case SbCanvasFormat.RGB32:
            case SbCanvasFormat.ARGB32:
                return w * 4;
        }
    }

protected:

    /**
        Returns backing data pointer
    */
    abstract ubyte* getData();

public:

    ~this() { }

    this(SbCanvasBackend backend, SbCanvasFormat fmt, uint w, uint h) {
        this.backend = backend;
        this.fmt = fmt;
        this.w = w;
        this.h = h;
        this.stride = this.calcStride();
    }

    /**
        Creates a canvas for the specified backend
    */
    static shared_ptr!SbCanvas create(SbCanvasFormat fmt, uint w, uint h) {
        switch(cnvBackendGet()) {
            case SbCanvasBackend.cairo:
                return shared_ptr!SbCanvas.fromPtr(nogc_new!SbCairoCanvas(fmt, w, h));

            default:
                shared_ptr!SbCanvas canvas;
                return canvas;
        }
    }

    /**
        Gets the width of the surface
    */
    final
    uint getWidth() {
        return w;
    }

    /**
        Gets the height of the surface
    */
    final
    uint getHeight() {
        return w;
    }

    /**
        Gets the stride of the surface
    */
    final
    uint getStride() {
        return stride;
    }

    /**
        Gets how many color channels is in the image
    */
    final
    uint getChannels() {
        final switch(fmt) {
            case SbCanvasFormat.A8:
                return 1;
                
            case SbCanvasFormat.RGB32:
                return 3;

            case SbCanvasFormat.ARGB32:
                return 4;
        }
    }

    /**
        Gets the alignment in bytes of pixels
    */
    final
    uint getAlign() {
        final switch(fmt) {
            case SbCanvasFormat.A8:
                return 1;
                
            case SbCanvasFormat.RGB32:
            case SbCanvasFormat.ARGB32:
                return 4;
        }
    }

    /**
        Resizes the canvas
    */
    abstract void resize(uint w, uint h);

    /**
        Acquires a lock to the canvas data.

        This allows the canvas to be modified manually
    */
    final
    ubyte* lock() {
        if (!isLocked) {
            isLocked = true;
            return getData();
        }

        return null;
    }

    /**
        Unlocks the canvas.
    */
    void unlock() {
        isLocked = false;
    }

    /**
        Gets the backend this canvas was created with
    */
    final
    SbCanvasBackend getBackend() {
        return backend;
    }

    /**
        Gets the format of the canvas
    */
    final
    SbCanvasFormat getFormat() {
        return fmt;
    }

    /**
        Gets whether the canvas is locked.

        Rendering to the canvas should be avoided while locked.
    */
    final
    bool getLocked() {
        return isLocked;
    }

    /**
        Gets the backing handle
    */
    abstract void* getHandle();

    /**
        Writes content of the canvas to file
    */
    void writeToFile(nstring name) {
        if (!getLocked()) {
            ubyte* data = lock();
                write_image(name.toDString(), w, h, data[0..stride+h], 4);
            unlock();
        }
    }
}