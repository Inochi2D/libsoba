/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Soba Library Entry
*/
module soba;
import bindbc.sdl;
import cairo;
import std.exception;

public import soba.core;

/**
    Initialize Soba

    Throws:
        If dependencies are not found
        If dependencies are too old
*/
void sbInit() {
    // auto sdlSupport = loadSDL();
    // enforce(sdlSupport != SDLSupport.noLibrary, "SDL2 was not found!");
    // enforce(sdlSupport >= SDLSupport.v2_26, "SDL2 is too old, 2.26 or newer is expected!");

    // SDL_Init(SDL_INIT_EVERYTHING);

    auto cairoSupport = loadCairo();
    enforce(cairoSupport != cairoSupport.noLibrary, "Cairo not found!");
}