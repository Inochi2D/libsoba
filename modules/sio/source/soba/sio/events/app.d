/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.sio.events.app;

enum SioAppEventID : ubyte {

    /**
        Event for when the application terminates/quits
    */
    terminate,

    /**
        Event for when the system runs low on memory

        The app should try to free as much memory as possible to
        not risk being force quit by the system.
    */
    lowMemory,

    /**
        Event for when the application is about to become a background task
    */
    backgroundEnter,

    /**
        Event for when the application has become a background task
    */
    backgroundEntered,

    /**
        Event for when the application is about to become a foreground task
    */
    foregroundEnter,

    /**
        Event for when the application has become a foreground task
    */
    foregroundEntered,
}

/**
    App Event
*/
struct SioAppEvent {

    /**
        App Event ID
    */
    SioAppEventID event;
}