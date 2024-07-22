/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module soba.core;

public import soba.core.app;
public import soba.core.math;

import bindbc.sdl;
import numem.all;

import soba.sio;
import soba.ssk;
import soba.canvas;

@nogc:

private {
    SioSurfaceCreateInfo preferredSurface;
}

SioSurfaceCreateInfo sbGetPreferredWindowSurface() {
    return preferredSurface;
}

/**
    Initialize Soba

    Throws a NuException if any of Soba's required submodules fail to load.
*/
void sbInit(SbCanvasBackend backend = SbCanvasBackend.blend2D) {
    sioInit();
    cnvInit(backend);

    // Setup preferred surface.
    version(OSX) {
        preferredSurface.type = SioWindowSurfaceType.metal;
    } else {
        preferredSurface.type = SioWindowSurfaceType.GL;
        preferredSurface.gl.major = 3;
        preferredSurface.gl.minor = 2;
    }
}