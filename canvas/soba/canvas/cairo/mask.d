/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module soba.canvas.cairo.mask;
import soba.canvas.mask;
import soba.canvas.canvas;
import soba.canvas.ctx;
import cairo;

import inmath.math;

class SbCairoMask : SbMask {
nothrow @nogc:
private:
    cairo_t* parent;
    cairo_path_t* path;

public:
    ~this() {
        cairo_path_destroy(path);
        parent = null;
    }

    this(SbCanvasFormat fmt, SbContext parent, cairo_path_t* path) {
        super(fmt, parent);
        this.path = path;

        // Calculate the path size
        double x1, y1, x2, y2;
        cairo_path_extents(cast(cairo_t*)parent.getHandle(), &x1, &y1, &x2, &y2);
        this.width = cast(uint)(ceil(x2-x1));
        this.height = cast(uint)(ceil(y2-y1));
    }

    override
    void* getHandle() {
        return path;
    }
}