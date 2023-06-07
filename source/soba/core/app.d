/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Application
*/
module soba.core.app;
import soba.core.gpu;
import soba.ui;
import std.format;
import inmath.math;
import soba.ui.window.appwindow;
import soba.ui.window;
import bindbc.sdl;

private {
    __gshared SbApp sbCurrApp_;
}

struct SbVersion {
    int major;
    int minor;
    int patch;
    string tag;

    int opCmp(ref SbVersion other) const {
        int s = this.major - other.major;
        if (s == 0) s += this.minor - other.minor;
        if (s == 0) s += this.patch - other.patch;
        return clamp(s, -1, 1);
    }

    /**
        Gets semantic version string
    */
    string toString() const {
        string ver_ = "%s.%s.%s".format(major, minor, patch);
        if (tag.length > 0) ver_ ~= "-%s".format(tag);
        return ver_;
    }
}

@("Version Comparison")
unittest {
    SbVersion ver_ = SbVersion(1, 0, 0);
    SbVersion ver2_ = SbVersion(2, 0, 0);
    assert(ver_ < ver2_);
    assert(ver2_ > ver_);
    assert(ver_ == ver_);
    
    ver_ = SbVersion(0, 1, 0);
    ver2_ = SbVersion(0, 2, 0);
    assert(ver_ < ver2_);
    assert(ver2_ > ver_);
    assert(ver_ == ver_);
    
    ver_ = SbVersion(0, 0, 1);
    ver2_ = SbVersion(0, 0, 2);
    assert(ver_ < ver2_);
    assert(ver2_ > ver_);
    assert(ver_ == ver_);
}

/**
    A Soba Application

    The application manages windows, event loops, and such.
    There can only be one active application per exeuction context.
*/
class SbApp {
private:
    SbApplicationWindow mainwindow;
    SbWindow[] windows;
    SbWidget[] continuousWidgets;


    void eventLoop() {
        SDL_Event ev;
        while (!mainwindow.isClosed()) {
            while(SDL_PollEvent(&ev)) {
                switch(ev.type) {
                    case SDL_WINDOWEVENT:
                        if (mainwindow.getID == ev.window.windowID) mainwindow.onWindowEvent(ev.window);
                        foreach(window; windows) {
                            if (window.getID == ev.window.windowID) {
                                window.onWindowEvent(ev.window);
                                break;
                            }
                        }
                        break;
                    
                    default: break;
                }
            }

            // Widgets slated for continuous updates
            foreach(widget; continuousWidgets) {
                widget.onUpdate();
            }
        }
    }

package(soba):
    void addWindow(SbWindow window) {
        windows ~= window;
    }

    void removeWindow() {

    }

public:
    /**
        Name of the application in reverse domain notation
    */
    string name;
    
    /**
        Human-readable of the application
    */
    string humanName;

    /**
        Version number of the application
    */
    SbVersion version_;

    this(string name, string humanName, SbVersion version_, SbGPUContextType contextType = SbGPUContextType.Auto) {
        this.name = name;
        this.humanName = humanName;
        this.version_= version_;
        sbGPUInit(sbGPUResolveContextType(contextType));
        sbCurrApp_ = this;
    }

    /**
        Starts the app
    */
    int run(SbApplicationWindow window) {
        this.mainwindow = window;
        mainwindow.show();
        this.eventLoop();
        return 0;
    }
}

/**
    Gets the current application
*/
ref SbApp sbGetApplication() {
    return sbCurrApp_;
}