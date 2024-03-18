module soba.core.events;
import soba.core.window;
import soba.core.math;
import soba.widgets.window;
import soba.widgets.widget;
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

    // If we have ongoing animations, they take precedent over the event queue.
    // As such we shouldn't freeze the main thread while an animation is running.
    int cont;
    SDL_Event ev;
    if (animations.length() > 0) {
        cont = SDL_PollEvent(&ev);
    } else {
        cont = SDL_WaitEventTimeout(&ev, 500);
    }

    if (cont) {
        do {
            switch(ev.type) {
                case SDL_QUIT: 
                    return true;

                case SDL_WINDOWEVENT:
                    if (ev.window.windowID in windows) {
                        switch(ev.window.type) {
                            case SDL_WINDOWEVENT_RESIZED:
                                windows[ev.window.windowID].window.onResize(ev.window.data1, ev.window.data2);
                                break;

                            default: break;
                        }
                    }
                    break;
                
                case SDL_MOUSEMOTION:
                    if (ev.motion.windowID in windows) {
                        vec2 scale = windows[ev.window.windowID].backing.getUIScale();
                        windows[ev.motion.windowID].window.onMouseMove(ev.motion.x*scale.x, ev.motion.y*scale.y);
                    }
                    break;
                
                case SDL_MOUSEBUTTONDOWN:
                    if (ev.button.windowID in windows) {
                        vec2 scale = windows[ev.window.windowID].backing.getUIScale();

                        if (ev.button.clicks == 2) 
                            windows[ev.button.windowID].window.onMouseDoubleClicked(ev.motion.x*scale.x, ev.motion.y*scale.y, cast(SbMouseButton)ev.button.button);

                        windows[ev.button.windowID].window.onMouseClicked(ev.motion.x*scale.x, ev.motion.y*scale.y, cast(SbMouseButton)ev.button.button);
                    }
                    break;
                
                case SDL_MOUSEBUTTONUP:
                    if (ev.button.windowID in windows) {
                        vec2 scale = windows[ev.window.windowID].backing.getUIScale();
                        windows[ev.button.windowID].window.onMouseReleased(ev.motion.x*scale.x, ev.motion.y*scale.y, cast(SbMouseButton)ev.button.button);
                    }
                    break;

                default: break;
            }
        } while(SDL_PollEvent(&ev));
    }

    // Animation events
    foreach(void* widget; animations.byKey()) {
        if (widget in animations) {
            animations[widget].widget.onAnimate(animations[widget].time);
            animations.remove(widget);
        }
    }

    // Redraw windows
    foreach(window; windows.byValue()) {
        if (window.window.isDirty()) {
            window.window.draw();
        }
    }

    return false;
}

/**
    Mouse buttons
*/
enum SbMouseButton {
    Left = SDL_BUTTON_LEFT,
    Middle = SDL_BUTTON_MIDDLE,
    Right = SDL_BUTTON_RIGHT
}

/**
    Adds a widget to the animation handler of the event queue
*/
void sbAddAnimation(SbWidget widget) {
    animations[cast(void*)widget] = EventAnimation(widget, 0);
}

/**
    Subscribes the specified window to the event queue 
*/
void sbSubscribeWindow(SbBackingWindow backing, SbWindow window) {
    windows[backing.getID()] = EventSubscriber(backing, window);
}

/**
    Unsubscribes the specified window from the event queue 
*/
void sbUnsubscribeWindow(SbBackingWindow backing) {
    if (backing.getID() in windows) {
        windows.remove(backing.getID());
    }
}

private {
    struct EventSubscriber {
        SbBackingWindow backing;
        SbWindow window;
    }

    struct EventAnimation {
        SbWidget widget;
        float time;
    }

    weak_map!(uint, EventSubscriber) windows;
    weak_map!(void*, EventAnimation) animations;
}