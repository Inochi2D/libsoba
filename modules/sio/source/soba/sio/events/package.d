/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.sio.events;
import soba.sio.window;
import bindbc.sdl;
import numem.all;
import inmath;

import core.stdc.string : strlen;

public import soba.sio.events.window;
public import soba.sio.events.mouse;
public import soba.sio.events.keyboard;
public import soba.sio.events.textedit;
public import soba.sio.events.handler;
public import soba.sio.events.event;

/**
    Event Loop
*/
class SioEventLoop {
@nogc:
private:
    __gshared SioEventLoop singletonInstance;

    SDL_Event lastEvent;

    float currTime;
    float lastTime;

    weak_map!(SioWindowID, weak_vector!SioIEventHandler) handlers;

    weak_vector!SioIAnimationHandler animations;
    weak_vector!SioIAnimationHandler animationBackBuffer;

    SioTextEntry textEntry;
    SioIEventHandler focused;

public:

    /**
        Returns the singleton event loop instance
    */
    static SioEventLoop instance() {
        if (!singletonInstance) {
            singletonInstance = nogc_new!SioEventLoop();
        }
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
        Runs one update cycle of the event loop.
    */
    bool pumpEvents() {

        // Pump system events
        SDL_PumpEvents();

        currTime = cast(float)SDL_GetTicks64()*0.0001;
        float deltaTime = currTime-lastTime;

        // If we have ongoing animations, they take precedent over the event queulastEvent.
        // As such we shouldn't freeze the main thread while an animation is running.
        int cont;
        if (animations.size() > 0) {
            cont = SDL_PollEvent(&lastEvent);
        } else {
            cont = SDL_WaitEventTimeout(&lastEvent, 500);
        }

        if (cont) {
            do {
                // SioWindowID windowID = lastEvent.event.windowID;

                // TODO: pipe events to Sio
            } while(SDL_PollEvent(&lastEvent));
        }

        // Animation events
        // resize does not resize the underlying memory
        // so this *should* be efficient enough.
        animationBackBuffer.resize(0);
        foreach(i, animation; animations) {
            if (!animation.runFrame(currTime, deltaTime)) {
                animationBackBuffer ~= animation;
            }
        }

        // Same goes for this, the slice copy should be fast
        // enough too.
        animations.resize(animationBackBuffer.size());
        animations.data[0..animationBackBuffer.size()] = animationBackBuffer[0..$];

        lastTime = currTime;
        return false;
    }

    /**
        Gets the handler currently being focused
    */
    SioIEventHandler getFocus() {
        return focused;
    }

    /**
        Sets the handler currently being focused
    */
    void setFocus(SioIEventHandler focused) {
        this.focused = focused;
    }
}