/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Window Creation
*/
module soba.ui.window.appwindow;
import soba.ui.window;
import soba.ui.widget;
import soba.drawing;
import soba.core.gpu;
import soba.core.gpu.surface;
import soba.core.app;

import bindbc.sdl;
import std.string;

/**
    Root window of an application
*/
class SbApplicationWindow : SbWindow {
protected:
    override 
    void setParent(SbWidget parent) {
        // NOTE: to prevent infinite recursion of application window
        // we do not allow the main window to be reparented.
        throw new Exception("Can't reparent ApplicationWindow.");
    }

public:
    this(SbApp app, int width, int height) {
        super(null, app.humanName, width, height);
    }

    override
    void onShown() {
        this.createNativeWindow(SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI); // TODO: add | SDL_WINDOW_BORDERLESS
    }

    override
    void onHidden() {
        SDL_DestroyWindow(getHandle());
    }

    override
    void onRender(SbDrawingContext drawing) {
        super.onRender(drawing);
    }

    override
    void onContextChanged(SbGPUContext prev, SbGPUContext next) {
        // NOTE: The context will never change, do nothing.
    }
}