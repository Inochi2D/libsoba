/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.text.font;
import soba.canvas.text.fontface;
import harfbuzz;
import numem.all;

import soba.canvas;
import soba.canvas.blend2d.font;
import soba.canvas.cairo.font;

/**
    A font face, usable for rendering text.
*/
abstract
class SbFont {
@nogc:
private:
    SbFontFace face;
    hb_font_t* font;

    float size;

public:
    ~this() {
        hb_font_destroy(font);
        font = null;
    }

    this(SbFontFace face, float size) {
        this.face = face;
        this.size = size;

        font = hb_font_create(face.getHandle());
    }

    /**
        Gets the underlying handle for the font.
    */
    hb_font_t* getHandle() {
        return font;
    }

    /**
        Gets the underlying handle for rendering the font.
    */
    abstract void* getDrawHandle();

    /**
        Gets the size of the font
    */
    final
    float getSize() {
        return this.size;
    }

    /**
        Sets the size of the font
    */
    void setSize(float size) {
        this.size = size;
    }

    /**
        Static helper function which creates a context using the same backend as the canvas
    */
    static SbFont create(SbFontFace face, float size) {
        switch(cnvBackendGet()) {
            case SbCanvasBackend.blend2D:
                return nogc_new!SbBLFont(face, size); 
            case SbCanvasBackend.cairo:
                return nogc_new!SbCairoFont(face, size);
            default:
                return null;
        }
    }
}