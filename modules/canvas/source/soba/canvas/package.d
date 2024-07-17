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
import harfbuzz;

import soba.canvas.cairo.font;
import soba.canvas.blend2d.font;

public import soba.canvas.ctx;
public import soba.canvas.pattern;
public import soba.canvas.effects;
public import soba.canvas.image;
public import soba.canvas.text;

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
bool cnvInit(SbCanvasBackend preferredBackend = SbCanvasBackend.blend2D) {

    switch(preferredBackend) {
        default:
            return false;

        case SbCanvasBackend.blend2D:
            if (!cnvInitHarfbuzz()) return false;

            if (!cnvInitBlend2D()) {
                return cnvInitCairo();
            }
            return false;

        case SbCanvasBackend.cairo:
            if (!cnvInitHarfbuzz()) return false;

            if (!cnvInitCairo()) {
                return cnvInitBlend2D();
            }
            return false;
    }
}

/**
    Returns which backend is currently in use
*/
SbCanvasBackend cnvBackendGet() {
    return cnvBackend;
}


// INITIALIZERS
private:
bool cnvInitBlend2D() {
    Blend2DSupport bsupport = loadBlend2D();
    if (bsupport == Blend2DSupport.blend2d) {
        cnvBackend = SbCanvasBackend.blend2D;
        cnvInitBLFontRendering();
        return true;
    }
    return false;
}

bool cnvInitCairo() {

    // Try Cairo
    CairoSupport csupport = loadCairo();
    if (csupport == CairoSupport.cairo) {
        cnvBackend = SbCanvasBackend.cairo;
        cnvInitCairoFontRendering();
        return true;
    }
    return false;
}

bool cnvInitHarfbuzz() {
    HarfBuzzSupport hbsupport = loadHarfBuzz();
    return hbsupport == HarfBuzzSupport.harfbuzz;
}