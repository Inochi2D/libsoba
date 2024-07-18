/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.sio.events.event;
import numem.all;
import bindbc.sdl;
import soba.sio.window;
import bindbc.sdl;

public import soba.sio.events.app;
public import soba.sio.events.keyboard;
public import soba.sio.events.mouse;
public import soba.sio.events.textedit;
public import soba.sio.events.window;
public import soba.sio.events.handler;

nothrow @nogc:

/**
    Types of events that can be handled
*/
enum SioEventType : uint {

    /**
        Events related to the app
    */
    app,
    
    /**
        System locale has changed
    */
    localeChanged,

    /**
        Window Events
    */
    window,

    /**
        Keyboard button press event
    */
    keyboard,

    /**
        Keymap change event

        Called when the user, for example, switches input language.
    */
    keyMapChanged,

    /**
        Text input event
    */
    textEdit,

    /**
        Mouse event
    */
    mouse,

    /**
        Touch press event
    */
    touch,

    /**
        Multigesture touch event
    */
    multigesture,

    /**
        File drop event
    */
    dropFile,

    /**
        Tablet pen event
    */
    pen
}

/**
    An event
*/
struct SioEvent {
    /**
        The type of the event
    */
    SioEventType type;

    /**
        The timestamp of the event
    */
    uint timestamp;

    /// Window in which event happened.
    SioWindowID target;

    union {
    align(size_t.sizeof):
        struct {
            /// Event ID
            ubyte event;
        }

        /**
            Events relating to the app
        */
        SioAppEvent app;

        /**
            Events relating to the window
        */
        SioWindowEvent window;
        
        /**
            Events relating to mouse input
        */
        SioMouseEvent mouse;
        
        /**
            Events relating to keyboard input
        */
        SioKeyboardEvent keyboard;
        
        /**
            Events relating to text input and composition
        */
        SioTextEditEvent textEdit;
    }
}