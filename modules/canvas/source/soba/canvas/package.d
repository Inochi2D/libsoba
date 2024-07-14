/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Soba Canvas
*/
module soba.canvas;
import soba.canvas.ctx;
import cairo;
import blend2d;

public import soba.canvas.ctx;
public import soba.canvas.canvas;
public import soba.canvas.pattern;
public import soba.canvas.effects;
public import soba.canvas.image;

private {
    __gshared SbCanvasBackend cnvBackend;
}

/**
    The backend in use
*/
enum SbCanvasBackend {
    none,
    cairo,
    blend2D
}

nothrow @nogc:
extern(C):

/**
    Attempts to initialize soba canvas with one of the backends
*/
bool cnvInit() {
    Blend2DSupport bsupport = loadBlend2D();
    if (bsupport == Blend2DSupport.blend2d) {
        cnvBackend = SbCanvasBackend.blend2D;
        return true;
    }

    // Try Cairo
    CairoSupport csupport = loadCairo();
    if (csupport == CairoSupport.cairo) {
        cnvBackend = SbCanvasBackend.cairo;
        return true;
    }

    return false;
}

/**
    Returns which backend is currently in use
*/
SbCanvasBackend cnvBackendGet() {
    return cnvBackend;
}