module soba.sio.events;
import numem.all;
import bindbc.sdl;
import soba.siok.window;

/**
    Manages events throughout SIO
*/
static
class SIOEventManager {
@nogc:
private:
    __gshared SDL_Event* ev;
    __gshared weak_map!(SIOWindowID, SIOEventQueue) queues;

public static:

    /**
        Pumps events into registered queues.
    */
    void pump() {

    }
    
}

enum SIOEventType {
    /**
        Event for when the application terminates/quits
    */
    appTerminate,

    /**
        Event for when the system runs low on memory

        The app should try to free as much memory as possible to
        not risk being force quit by the system.
    */
    appLowMemory,

    /**
        Event for when the application is about to become a background task
    */
    appBackgroundEnter,

    /**
        Event for when the application has become a background task
    */
    appBackgroundEntered,

    /**
        Event for when the application is about to become a foreground task
    */
    appForegroundEnter,

    /**
        Event for when the application has become a foreground task
    */
    appForegroundEntered,
    
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
    keyDown,

    /**
        Keyboard button release event
    */
    keyUp,

    /**
        Keymap change event

        Called when the user, for example, switches input language.
    */
    keyMapChanged,

    /**
        Full text input event
    */
    textEdit,

    /**
        Basic text input event
    */
    textInput,

    /**
        Mouse movement event
    */
    mouseMotion,

    /**
        Mouse button press event
    */
    mouseButtonUp,

    /**
        Mouse button release event
    */
    mouseButtonDown,

    /**
        Mouse scroll event
    */
    mouseWheel,

    /**
        Touch press event
    */
    fingerDown,

    /**
        Touch release event
    */
    fingerUp,

    /**
        Touch motion event
    */
    fingerMotion,

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
    An event queue
*/
class SIOEventQueue {
@nogc:
    SIOWindow window;

public:
}