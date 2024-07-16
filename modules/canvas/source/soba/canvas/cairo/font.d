/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.cairo.font;
import soba.canvas.text.font;
import soba.canvas.text.fontface;
import numem.all;
import blend2d;

/**
    A font face, usable for rendering text.
*/
class SbCairoFont : SbFont {
@nogc:
private:


public:

    /**
        Constructor
    */
    this(SbFontFace face, float size) {
        super(face, size);

    }

    /**
        Sets the size of the font
    */
    override
    void setSize(float size) {
        super.setSize(size);
    }

    override
    void* getDrawHandle() {
        return null;
    }
}