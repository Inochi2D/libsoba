/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.sio.events.handler;
import soba.sio.events.event;
import soba.sio.window;


/**
    Interface for all classes which can handle Sio Events
*/
interface SioIEventHandler {
@nogc:
    
    /**
        Push an event to the handler
    */
    void pushEvent(SioEvent event);

    /**
        Tells the event system to register the handler for execution
    */
    final
    void registerHandlerFor(SioWindowID window) {
        
    }

    /**
        Tells the event system to unregister the handler for execution
    */
    final
    void unregisterHandlerFor(SioWindowID window) {

    }
}

/**
    An animation handler
*/
interface SioIAnimationHandler {
@nogc:

    /**
        Run a frame of animation.

        Return true once the animation is done.
    */
    bool runFrame(float currTime, float deltaTime);
}