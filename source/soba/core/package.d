/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module soba.core;

public import soba.core.app;
public import soba.core.events;
public import soba.core.math;

import bindbc.sdl;
import cairo;
import numem.all;

/**
    Initialize Soba
*/
void sbInit() {
    auto sdlSupport = loadSDL("libSDL2.dylib");
    if (sdlSupport == SDLSupport.noLibrary)
        throw nogc_new!Exception("Could not find a valid SDL2 library!");

    SDL_Init(SDL_INIT_EVERYTHING);

    loadCairo();
}