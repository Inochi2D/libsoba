/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE fillastEvent.
    
    Authors: Luna Nielsen
*/
module soba.core.events;
import soba.core.window;
import soba.core.math;
import soba.widgets.window;
import soba.widgets.widget;
import numem.all;
import numem.mem.map;
import bindbc.sdl;
import inmath;

import core.stdc.string : strlen;

nothrow @nogc:

/**
    Singleton eventloop instanclastEvent.
*/
class SbEventLoop {
nothrow @nogc:
private:
    __gshared SbEventLoop singletonInstance;

    SDL_Event lastEvent;

    float currTime;
    float lastTime;

    weak_map!(uint, EventSubscriber) windows;
    weak_map!(void*, EventAnimation) animations;

    SbTextEntry currTextEntry;
    SbWidget focused;

public:

    this() {
        if (!singletonInstance) {
            singletonInstance = this;
        }
    }

    /**
        Returns the singleton event loop instance
    */
    static SbEventLoop instance() {
        return singletonInstance;
    }

    /**
        Starts handling text entry
    */
    void startTyping() {
        SDL_StartTextInput();
    }

    /**
        Stops handling text entry
    */
    void stopTyping() {
        SDL_StopTextInput();
    }

    /**
        Gets whether the event loop is getting text typing input.
    */
    bool isTyping() {
        return cast(bool)SDL_IsTextInputActive();
    }

    /**
        Sets the region tht is being typed in
    */
    void setTypingRegion(recti area) {
        SDL_Rect rect = SDL_Rect(area.x, area.y, area.width, area.height);
        SDL_SetTextInputRect(&rect);
    }

    /**
        Sets string in clipboard
    */
    void setClipboardText(nstring toCopy) {
        SDL_SetClipboardText(toCopy.ptr);
    }

    /**
        Gets string in clipboard
    */
    nstring getClipboardText() {
        char* tmp = SDL_GetClipboardText();
        nstring ret = nstring(tmp[0..strlen(tmp)]);
        SDL_free(tmp);

        return ret;
    }

    /**
        Updates the event loop, this is called automatically by SbApplication.
    */
    bool update() {

        // Pump system events
        SDL_PumpEvents();

        currTime = cast(float)SDL_GetTicks64()*0.0001;
        float deltaTime = currTime-lastTime;

        // If we have ongoing animations, they take precedent over the event queulastEvent.
        // As such we shouldn't freeze the main thread while an animation is running.
        int cont;
        if (animations.length() > 0) {
            cont = SDL_PollEvent(&lastEvent);
        } else {
            cont = SDL_WaitEventTimeout(&lastEvent, 500);
        }

        if (cont) {
            do {
                switch(lastEvent.type) {
                    case SDL_QUIT: 
                        return true;

                    case SDL_WINDOWEVENT:
                        if (lastEvent.window.windowID in windows) {
                            switch(lastEvent.window.event) {
                                case SDL_WINDOWEVENT_RESIZED:
                                    vec2 size = windows[lastEvent.window.windowID].backing.getFramebufferSize();
                                    windows[lastEvent.window.windowID].window.onResize(size.x, size.y);
                                    break;

                                default: break;
                            }
                        }
                        break;
                    case SDL_KEYDOWN:
                        
                        SDL_Keymod sysKM;
                        version(OSX) sysKM = KMOD_GUI;
                        else sysKM = KMOD_CTRL;

                        if (lastEvent.key.keysym.sym == SDLK_c && SDL_GetModState() & sysKM) {
                            windows[lastEvent.window.windowID].window.onUserCopy();
                        }

                        if (lastEvent.key.keysym.sym == SDLK_v && SDL_GetModState() & sysKM) {
                            windows[lastEvent.window.windowID].window.onUserPaste();
                        }
                        break;
                    
                    case SDL_MOUSEMOTION:
                        if (lastEvent.motion.windowID in windows) {
                            vec2 scale = windows[lastEvent.window.windowID].backing.getUIScale();
                            windows[lastEvent.motion.windowID].window.onMouseMove(lastEvent.motion.x*scale.x, lastEvent.motion.y*scale.y);
                        }
                        break;
                    
                    case SDL_MOUSEBUTTONDOWN:
                        if (lastEvent.button.windowID in windows) {
                            vec2 scale = windows[lastEvent.window.windowID].backing.getUIScale();

                            if (lastEvent.button.clicks == 2) 
                                windows[lastEvent.button.windowID].window.onMouseDoubleClicked(lastEvent.motion.x*scale.x, lastEvent.motion.y*scale.y, cast(SbMouseButton)lastEvent.button.button);

                            windows[lastEvent.button.windowID].window.onMouseClicked(lastEvent.motion.x*scale.x, lastEvent.motion.y*scale.y, cast(SbMouseButton)lastEvent.button.button);
                        }
                        break;
                    
                    case SDL_MOUSEBUTTONUP:
                        if (lastEvent.button.windowID in windows) {
                            vec2 scale = windows[lastEvent.window.windowID].backing.getUIScale();
                            windows[lastEvent.button.windowID].window.onMouseReleased(lastEvent.motion.x*scale.x, lastEvent.motion.y*scale.y, cast(SbMouseButton)lastEvent.button.button);
                        }
                        break;

                    default: break;
                }
            } while(SDL_PollEvent(&lastEvent));
        }

        // Animation events
        foreach(void* widget; animations.byKey()) {
            if (widget in animations) {
                animations[widget].time += deltaTime;
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

        lastTime = currTime;
        return false;
    }

    /**
        Gets the widget currently being focused
    */
    SbWidget getFocus() {
        return focused;
    }

    /**
        Sets the widget currently being focused
    */
    void setFocus(SbWidget widget) {
        focused = widget;
    }
}

/**
    Text entry
*/
struct SbTextEntry {

    /// Current text in buffer
    nstring text;

    /// The current composition string
    nstring composition;

    /// The cursor position in the text
    uint cursor;

    /// The length of text selection
    uint selectionLength;
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
    SbEventLoop.singletonInstance.animations[cast(void*)widget] = EventAnimation(widget, 0);
}

/**
    Subscribes the specified window to the event queue 
*/
void sbSubscribeWindow(SbBackingWindow backing, SbWindow window) {
    SbEventLoop.singletonInstance.windows[backing.getID()] = EventSubscriber(backing, window);
}

/**
    Unsubscribes the specified window from the event queue 
*/
void sbUnsubscribeWindow(SbBackingWindow backing) {
    if (backing.getID() in SbEventLoop.singletonInstance.windows) {
        SbEventLoop.singletonInstance.windows.remove(backing.getID());
    }
}


// Internal impl
private:

struct EventSubscriber {
    SbBackingWindow backing;
    SbWindow window;
}

struct EventAnimation {
    SbWidget widget;
    float time;
}