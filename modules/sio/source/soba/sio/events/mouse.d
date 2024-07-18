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


module soba.sio.events.mouse;
import bindbc.sdl;



/**
    Window event types
*/
enum SioMouseEventID : uint {
    button,
    wheel,
    motion
}

/**
    Mouse buttons
*/
enum SioMouseButton : ubyte {
    left = SDL_BUTTON_LEFT,
    middle = SDL_BUTTON_MIDDLE,
    right = SDL_BUTTON_RIGHT
}

/**
    Mouse event
*/
struct SioMouseEvent {

    /// Mouse event ID
    SioMouseEventID event;

    // Position of mouse relative to window
    int mouseX;
    
    // Position of mouse relative to window
    int mouseY;

    union {

        // Mouse button event
        struct SioMouseButtonEv {
        align(4):
            SioMouseButton  btn;
            bool            pressed;
            ubyte           clicks;
        }

        // Mouse scroll event
        struct SioMouseScrollEv {
        align(4):

            // Whether X and Y are flipped
            bool directionFlipped;
            
            // Amount scrolled on the X axis
            float x;

            // Amount scrolled on the Y axis
            float y;
        }

        // Mouse scroll event
        struct SioMouseMotionEv {
        align(4):

            /**
                Current mouse button state
            */
            uint buttonState;

            /// Mouse X relative motion
            int relX;

            /// Mouse Y relative motion
            int relY;
        }

        SioMouseButtonEv button;
        SioMouseScrollEv scroll;
        SioMouseMotionEv motion;
    }
}