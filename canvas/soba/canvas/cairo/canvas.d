/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.cairo.canvas;
import soba.canvas.canvas;
import soba.canvas;
import cairo;
import numem.all;

class SbCairoCanvas : SbCanvas {
nothrow @nogc:
private:
    cairo_surface_t* surface;

protected:

    override
    ubyte* getData() {
        return cairo_image_surface_get_data(surface);
    }


public:

    ~this() {
        cairo_surface_destroy(surface);
    }

    this(SbCanvasFormat fmt, uint width, uint height) {
        super(SbCanvasBackend.cairo, fmt, width, height);

        // Create the underlying surface
        final switch(fmt) {
            case SbCanvasFormat.RGB32:
                surface = cairo_image_surface_create(cairo_format_t.CAIRO_FORMAT_RGB24, width, height);
                return;
            case SbCanvasFormat.ARGB32:
                surface = cairo_image_surface_create(cairo_format_t.CAIRO_FORMAT_ARGB32, width, height);
                return;
        }
    }

    override
    void resize(uint w, uint h) {
        if (!getLocked()) {

        }
    }

    override
    void unlock() {
        super.unlock();
        cairo_surface_flush(surface);
    }

    override
    void* getHandle() {
        return surface;
    }

    override
    void writeToFile(nstring name) {
        if (!getLocked()) {
            cairo_surface_write_to_png(surface, name.toCString());
        }
    }
}