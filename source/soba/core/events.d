module soba.core.events;
import soba.core.window;
import soba.widgets.window;
import numem.all;
import numem.mem.map;
import bindbc.sdl;

nothrow @nogc:

/**
    Pumps the event queue and returns true if the application requested a quit.
*/
bool sbPumpEventQueue() {
            
    // Pump system events
    SDL_PumpEvents();
    SDL_Event ev;
    while(SDL_PollEvent(&ev)) {
        switch(ev.type) {
            case SDL_QUIT: 
                return true;

            case SDL_WINDOWEVENT:
                if (ev.window.windowID in windows) {
                    switch(ev.window.type) {
                        case SDL_WINDOWEVENT_RESIZED:
                            windows[ev.window.windowID].onResize(ev.window.data1, ev.window.data2);
                            break;
                        default: break;
                    }
                }
                break;
            
            default: break;
        }
    }

    return false;
}


/**
    Subscribes the specified window to the event queue 
*/
void sbSubscribeWindow(SbBackingWindow backing, SbWindow window) {
    windows[backing.getID()] = window;
}

/**
    Unsubscribes the specified window from the event queue 
*/
void sbUbsubscribeWindow(SbBackingWindow backing) {
    if (backing.getID() in windows) {
        windows.remove(backing.getID());
    }
}

private {
    weak_map!(uint, SbWindow) windows;
}