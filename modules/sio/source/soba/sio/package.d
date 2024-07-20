/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Soba I/O
*/
module soba.sio;
import numem.all;
import bindbc.sdl;

public import soba.sio.window;
public import soba.sio.events;

@nogc:

/**
    Initializes SIO.

    Throws an exception on loading failure
*/
void sioInit() {
    SDLSupport support = loadSDL();
    enforce(support != SDLSupport.noLibrary, nstring("SDL2 could not be found!"));

    SDL_Init(SDL_INIT_EVERYTHING);
}