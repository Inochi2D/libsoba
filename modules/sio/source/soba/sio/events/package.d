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

    map!(SioWindowID, weak_vector!SioIEventHandler) handlers;

    weak_vector!_ImplSioAnimation animations;
    weak_vector!_ImplSioAnimation animationBackBuffer;

    // TODO: Add a type to numem for a fixed size buffer.
    weak_vector!SioEvent submittedEvents;

    SioIEventHandler focused;

    void pumpSDLEventsToLoop() {

        // Pump system events
        SDL_PumpEvents();

        // If we have ongoing animations, they take precedent over the event queulastEvent.
        // As such we shouldn't freeze the main thread while an animation is running.
        int cont;
        if (animations.size() > 0) {
            cont = SDL_PollEvent(&lastEvent);
        } else {
            cont = SDL_WaitEventTimeout(&lastEvent, 100);
        }

        if (cont) {
            do {
                SioEvent toSubmit;
                mswitch: switch(lastEvent.type) {
                    case SDL_WINDOWEVENT:
                        SDL_WindowEvent ev = lastEvent.window;
                        toSubmit.type = SioEventType.window;
                        toSubmit.target = ev.windowID;

                        switch(ev.event) {

                            // Events without data.
                            case SDL_WINDOWEVENT_CLOSE:         toSubmit.event = SioWindowEventID.closeRequested;   break;
                            case SDL_WINDOWEVENT_SHOWN:         toSubmit.event = SioWindowEventID.opened;           break;
                            case SDL_WINDOWEVENT_HIDDEN:        toSubmit.event = SioWindowEventID.closed;           break;
                            case SDL_WINDOWEVENT_EXPOSED:       toSubmit.event = SioWindowEventID.redraw;           break;
                            case SDL_WINDOWEVENT_MINIMIZED:     toSubmit.event = SioWindowEventID.minimized;        break;
                            case SDL_WINDOWEVENT_MAXIMIZED:     toSubmit.event = SioWindowEventID.maximized;        break;
                            case SDL_WINDOWEVENT_RESTORED:      toSubmit.event = SioWindowEventID.restored;         break;
                            case SDL_WINDOWEVENT_ENTER:         toSubmit.event = SioWindowEventID.mouseEnter;       break;
                            case SDL_WINDOWEVENT_LEAVE:         toSubmit.event = SioWindowEventID.mouseLeave;       break;
                            case SDL_WINDOWEVENT_FOCUS_GAINED:  toSubmit.event = SioWindowEventID.keyboardEnter;    break;
                            case SDL_WINDOWEVENT_FOCUS_LOST:    toSubmit.event = SioWindowEventID.keyboardLeave;    break;

                            // Events which have data
                            case SDL_WINDOWEVENT_SIZE_CHANGED:
                                toSubmit.window.event = SioWindowEventID.resized;
                                toSubmit.window.data1 = ev.data1;
                                toSubmit.window.data2 = ev.data2;
                                break;

                            case SDL_WINDOWEVENT_MOVED:
                                toSubmit.window.event = SioWindowEventID.moved;
                                toSubmit.window.data1 = ev.data1;
                                toSubmit.window.data2 = ev.data2;
                                break;

                            case SDL_WINDOWEVENT_DISPLAY_CHANGED:
                                toSubmit.window.event = SioWindowEventID.displayChanged;
                                toSubmit.window.data1 = ev.data1;
                                break;

                            // Discard remaining events
                            default:
                                break mswitch;
                        }
                        
                        this.pushEvent(toSubmit);
                        break;

                    case SDL_MOUSEMOTION:
                        SDL_MouseMotionEvent ev = lastEvent.motion;
                        toSubmit.type = SioEventType.mouse;
                        toSubmit.target = ev.windowID;
                        
                        toSubmit.mouse.event = SioMouseEventID.motion;
                        toSubmit.mouse.mouseX = ev.x;
                        toSubmit.mouse.mouseY = ev.y;

                        toSubmit.mouse.motion.relX = ev.xrel;
                        toSubmit.mouse.motion.relX = ev.yrel;
                        toSubmit.mouse.motion.buttonState = ev.state;

                        this.pushEvent(toSubmit);
                        break;

                    case SDL_MOUSEBUTTONDOWN:
                        SDL_MouseButtonEvent ev = lastEvent.button;
                        toSubmit.type = SioEventType.mouse;
                        toSubmit.target = ev.windowID;

                        toSubmit.mouse.event = SioMouseEventID.buttonDown;
                        toSubmit.mouse.mouseX = ev.x;
                        toSubmit.mouse.mouseY = ev.y;

                        toSubmit.mouse.button.btn = cast(SioMouseButton)ev.button;
                        toSubmit.mouse.button.pressed = ev.state == SDL_PRESSED;
                        toSubmit.mouse.button.clicks = ev.clicks;
                        
                        this.pushEvent(toSubmit);
                        break;

                    case SDL_MOUSEBUTTONUP:
                        SDL_MouseButtonEvent ev = lastEvent.button;
                        toSubmit.type = SioEventType.mouse;
                        toSubmit.target = ev.windowID;

                        toSubmit.mouse.event = SioMouseEventID.buttonUp;
                        toSubmit.mouse.mouseX = ev.x;
                        toSubmit.mouse.mouseY = ev.y;

                        toSubmit.mouse.button.btn = cast(SioMouseButton)ev.button;
                        toSubmit.mouse.button.pressed = ev.state == SDL_PRESSED;
                        toSubmit.mouse.button.clicks = ev.clicks;
                        
                        this.pushEvent(toSubmit);
                        break;
                    
                    case SDL_MOUSEWHEEL:
                        SDL_MouseWheelEvent ev = lastEvent.wheel;
                        toSubmit.type = SioEventType.mouse;
                        toSubmit.target = ev.windowID;

                        toSubmit.mouse.event = SioMouseEventID.wheel;
                        toSubmit.mouse.mouseX = ev.mouseX;
                        toSubmit.mouse.mouseY = ev.mouseY;
                        
                        toSubmit.mouse.scroll.directionFlipped = 
                            ev.direction == SDL_MOUSEWHEEL_FLIPPED;
                        toSubmit.mouse.scroll.x = ev.preciseX;
                        toSubmit.mouse.scroll.y = ev.preciseY;
                        
                        this.pushEvent(toSubmit);
                        break;

                    case SDL_TEXTEDITING:
                    case SDL_TEXTEDITING_EXT:
                        SDL_TextEditingEvent ev = lastEvent.edit;
                        composeEntry.target = ev.windowID;
                        composeEntry.addText(ev.text[0..strlen(&ev.text[0])], ev.start, ev.length, true);
                        break;

                    case SDL_TEXTINPUT:
                        SDL_TextInputEvent ev = lastEvent.text;
                        textEntry.target = ev.windowID;
                        textEntry.addText(ev.text[0..strlen(&ev.text[0])], 0, 0, false);
                        break;

                    default: break;
                }
                
            } while(SDL_PollEvent(&lastEvent));

            if (textEntry.shouldSubmit()) {
                textEntry.submitText(false);
                composeEntry.reset();
                textEntry.reset();
            }

            if (composeEntry.shouldSubmit()) {
                composeEntry.submitText(true);
                composeEntry.reset();
            }
        }
    }

    bool processSioEvents() {
        if (submittedEvents.size() > 0) {
            foreach(ref SioEvent ev; submittedEvents) {
                if (ev.target in handlers) {
                    foreach(ref handler; handlers[ev.target]) {
                        handler.processEvent(ev);
                    }
                }

                if (ev.target == SioWindowAll) {
                    foreach(target; handlers) {
                        foreach(ref handler; target) {
                            handler.processEvent(ev);
                        }
                    }
                }
            }

            // Resize, keeping the allocated memory of the event queue
            submittedEvents.resize(0);
            return true;
        }

        return false;
    }

    void processAnimations(float deltaTime) {
        
        // Animation events
        // resize does not resize the underlying memory
        // so this *should* be efficient enough.
        animationBackBuffer.resize(0);
        foreach(i, animation; animations) {
            animation.time += deltaTime;
            if (!animation.handler.runFrame(animation.time, deltaTime)) {
                animationBackBuffer ~= animation;
            }
        }

        // Same goes for this, the slice copy should be fast
        // enough too.
        animations.resize(animationBackBuffer.size());
        animations.data[0..animationBackBuffer.size()] = animationBackBuffer[0..$];
    }

    
    // Text handling
    bool composeEnabled;
    SioTextEntry composeEntry;
    SioTextEntry textEntry;

public:

    ~this() {
        nogc_delete(handlers);
        nogc_delete(animations);
        nogc_delete(animationBackBuffer);
        nogc_delete(submittedEvents);
    }

    this() {

        // Text input as a default is a nono.
        SDL_StopTextInput();
    }


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
    final
    void startTyping() {
        SDL_StartTextInput();
        composeEnabled = true;
    }

    /**
        Stops handling text entry
    */
    final
    void stopTyping() {
        SDL_StopTextInput();
        composeEnabled = false;
    }

    /**
        Gets whether the event loop is getting text typing input.
    */
    final
    bool isTyping() {
        return cast(bool)SDL_IsTextInputActive();
    }

    /**
        Sets the region tht is being typed in
    */
    final
    void setTypingRegion(recti area) {
        SDL_Rect rect = SDL_Rect(area.x, area.y, area.width, area.height);
        SDL_SetTextInputRect(&rect);
    }

    /**
        Sets string in clipboard
    */
    final
    void setClipboardText(nstring toCopy) {
        SDL_SetClipboardText(toCopy.ptr);
    }

    /**
        Gets string in clipboard
    */
    final
    nstring getClipboardText() {
        char* tmp = SDL_GetClipboardText();
        nstring ret = nstring(tmp[0..strlen(tmp)]);
        SDL_free(tmp);

        return ret;
    }

    /**
        Runs one update cycle of the event loop.
    */
    final
    void pumpEvents() {

        currTime = cast(float)SDL_GetTicks64()*0.0001;
        float deltaTime = currTime-lastTime;
        
        this.pumpSDLEventsToLoop();
        this.processSioEvents();
        this.processAnimations(deltaTime);

        lastTime = currTime;
    }

    /**
        Gets the handler currently being focused
    */
    final
    SioIEventHandler getFocus() {
        return focused;
    }

    /**
        Sets the handler currently being focused
    */
    final
    void setFocus(SioIEventHandler focused) {
        this.focused = focused;
    }

    /**
        Adds an event handler to the event loop
    */
    final
    void addGlobalHandler(SioIEventHandler handler) {
        this.addHandler(SioWindowGlobal, handler);
    }
    
    /**
        Removes a event handler from the event loop
    */
    final
    void removeGlobalHandler(SioIEventHandler handler) {
        this.removeHandler(SioWindowGlobal, handler);
    }

    /**
        Adds an event handler to the event loop
    */
    final
    void addHandler(SioWindowID id, SioIEventHandler handler) {
        if (id !in handlers) {
            handlers[id] = weak_vector!SioIEventHandler();
        }
        handlers[id] ~= handler;
    }

    /**
        Removes all event handlers for the specified window from the event loop
    */
    final
    void removeAllHandlersFor(SioWindowID id) {
        if (id in handlers) {
            handlers.remove(id);
        }
    }
    
    /**
        Removes a event handler from the event loop
    */
    final
    void removeHandler(SioWindowID id, SioIEventHandler handler) {
        foreach(i; 0..handlers[id].size()) {
            if (handlers[id][i] is handler) {
                handlers[id].remove(i);
                return;
            }
        }
    }

    /**
        Adds a animation handler to the event loop
    */
    final
    void addAnimation(SioIAnimationHandler handler) {
        animations ~= _ImplSioAnimation(0, handler);
    }

    /**
        Adds an event to the queue
    */
    final
    void pushEvent(SioEvent event) {
        event.timestamp = SDL_GetTicks();
        submittedEvents ~= event;
    }

    /**
        Adds an event to the queue
    */
    final
    bool hasHandlers() {
        return handlers.length > 0;
    }
}

private {
    struct _ImplSioAnimation {
        float time;
        SioIAnimationHandler handler;
    }
}