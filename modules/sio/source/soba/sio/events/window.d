/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen, SDL2 Project

    Definitions in this file are taken from the SDL headers for compatibility
    reasons.

    --------------------------------------------------------------------------

    Simple DirectMedia Layer
    Copyright (C) 1997-2024 Sam Lantinga <slouken@libsdl.org>

    This software is provided 'as-is', without any express or implied
    warranty.  In no event will the authors be held liable for any damages
    arising from the use of this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
        claim that you wrote the original software. If you use this software
        in a product, an acknowledgment in the product documentation would be
        appreciated but is not required.
    2. Altered source versions must be plainly marked as such, and must not be
        misrepresented as being the original software.
    3. This notice may not be removed or altered from any source distribution.
*/


module soba.sio.events.window;

/**
    Window event types
*/
enum SioWindowEventID : uint {
    
    /**
        Window has been opened.
    */
    opened,
    
    /**
        Window has been closed.
    */
    closed,
    
    /**
        Window requested to be closed.
    */
    closeRequested,
    
    /**
        Window was resized
    */
    resized,
    
    /**
        Window was moved
    */
    moved,
    
    /**
        Window was maximized
    */
    maximized,
    
    /**
        Window was minimized
    */
    minimized,
    
    /**
        Window was restored to normal size and position
    */
    restored,

    /**
        Window got mouse focus
    */
    mouseEnter,
    
    /**
        Window lost mouse focus
    */
    mouseLeave,

    /**
        Window got keyboard focus
    */
    keyboardEnter,

    /**
        Window got keyboard focus
    */
    keyboardLeave,

    /**
        Window moved to another display
    */
    displayChanged,

    /**
        Window was requested to redraw.
    */
    redraw
}

/**
    A window event
*/
struct SioWindowEvent {

    /// Window event ID
    SioWindowEventID event;
    
    uint data1;
    uint data2;

    uint[3] padding;
}