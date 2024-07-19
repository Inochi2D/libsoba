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

module soba.sio.events.textedit;
import numem.all;

enum SioTextEditEventID : ubyte {

    /**
        User is composing text
    */
    compose,

    /**
        User is submitting text
    */
    submit
}

struct SioTextEditEvent {
align(4):
    
    /**
        Event ID
    */
    SioTextEditEventID event;

    /**
        Current text slice
    */
    SioTextEntry* entry;
}


/**
    Text entry, this is owned by the event loop
    and should NOT be freed.
*/
struct SioTextEntry {
@nogc:

    /// Current text in buffer
    nstring text;

    /// The cursor position in the text
    int cursor;

    /// The length of text selection
    int selectionLength;

    /// Whether the text is currently being edited.
    bool editing;

package(soba.sio):

    uint textIdx;

    uint target;

    void reset() {
        textIdx = 0;
    }

    void addText(char[] data, uint composition, uint length) {
        if (textIdx == 0) {
            text.clear();
        }

        text ~= data[0..$];
        textIdx += data.length;

        cursor = composition;
        selectionLength = length;
    }

    bool shouldSubmit() {
        return textIdx > 0;
    }
}