/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Window Creation
*/
module soba.core.window;
import soba.core.gpu;
import soba.core.app;

import bindbc.sdl;
import soba.core.gpu.surface;
import std.string;

class Window {
protected:
    SbGPUContext gpuctx;
    SbSurface surface;
    SDL_Window* handle;
    const(char)* title;

    void createWindow(string title, int width, int height) {
        
        // TODO: Expand this
        this.title = title.toStringz;
        handle = SDL_CreateWindow(
            this.title, 
            SDL_WINDOWPOS_UNDEFINED, 
            SDL_WINDOWPOS_UNDEFINED,
            width,
            height,
            SDL_WINDOW_RESIZABLE
        );
    }

    void createSurface() {
        
        int width, height;
        SDL_GetWindowSizeInPixels(handle, &width, &height);
        surface = new SbSurface(gpuctx, handle, width, height);
    }

public:
    this(SbApp app, string title, int width, int height) {
        this.gpuctx = app.gpuContext;
        this.createWindow(title, width, height);
        this.createSurface();
    }
}