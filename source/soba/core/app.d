/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module soba.core.app;
import soba.core;
import numem.all;
import numem.mem.map;
import cairo;
import bindbc.sdl;
import soba.sio;
import soba.widgets.window;

@nogc:

/**
    Information about the application
*/
struct SbAppInfo {
    nstring name;
    nstring version_;
}

/**
    Instance of the application.
*/
class SbApplication {
@nogc:
private:
    SbAppInfo appInfo;
    SbWindow rootWindow;

public:
    ~this() {
        nogc_delete(appInfo.name);
        nogc_delete(appInfo.version_);
        nogc_delete(rootWindow);
    }

    /**
        Instantiates the application
    */
    this(SbAppInfo appInfo) {
        this.appInfo = appInfo;
    }

    /**
        Sets the root window for the application
    */
    void setRootWindow(SbWindow rootWindow) {
        if (!this.rootWindow) {
            this.rootWindow = rootWindow;
        }
    }

    /**
        Runs the application
    */
    void run() {
        if (!this.rootWindow) return;

        try {
            sbInit();

            rootWindow.showAll();

            /// Pump event queue while the root window is meant to run.
            while(rootWindow.isVisible()) {
                SioEventLoop.instance().pumpEvents();
            }
        } catch(NuException ex) {
            import core.stdc.stdio : printf;
            nstring str = ex.msg;
            printf("FATAL ERROR: %s\n", str.toCString());
            nogc_delete(ex);
            
        }
    }

    /**
        Gets the base information about the app
    */
    SbAppInfo getInfo() {
        return appInfo;
    }
}