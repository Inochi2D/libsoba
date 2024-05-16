/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module soba.core.app;
import soba.core.events;
import soba.widgets.window.mainwindow;
import numem.all;
import numem.mem.map;
import cairo;
import bindbc.sdl;
import soba.core.window;

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
nothrow @nogc:
private:
    SbAppInfo appInfo;
    SbMainWindow rootWindow;
    SbEventLoop eventLoop;

public:
    ~this() {
        nogc_delete(appInfo.name);
        nogc_delete(appInfo.version_);
        nogc_delete(rootWindow);
        nogc_delete(eventLoop);
    }

    /**
        Instantiates the application
    */
    this(SbAppInfo appInfo) {
        this.appInfo = appInfo;
        eventLoop = nogc_new!SbEventLoop();
    }

    /**
        Runs the application
    */
    void run(SbMainWindow rootWindow) {
        this.rootWindow = rootWindow;
        rootWindow.show();
        try {

            /// Pump event queue while the root window is meant to run.
            while(!rootWindow.isCloseRequested()) {
                if (eventLoop.update()) break;
            }
        } catch(Exception ex) {
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