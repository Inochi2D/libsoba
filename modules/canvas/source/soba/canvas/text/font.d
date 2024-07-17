/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.text.font;
import soba.canvas.text.fontface;
import harfbuzz;
import numem.all;
import inmath;

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

    int size;
    bool doGrading;

public:
    ~this() {
        hb_font_destroy(font);
        font = null;
    }

    this(SbFontFace face, int size) {
        this.face = face;
        this.size = size;

        font = hb_font_create(face.getHandle());
        hb_font_set_scale(font, cast(int)size*64, cast(int)size*64);
    }

    /**
        Gets the underlying handle for the font.
    */
    hb_font_t* getHandle() nothrow {
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
    int getSize() {
        return this.size;
    }

    /**
        Sets the size of the font
    */
    void setSize(int size) {
        this.size = size;
        hb_font_set_scale(font, cast(int)size*64, cast(int)size*64);
    }

    /**
        Gets the font scale
    */
    final
    vec2i getScale() nothrow {
        
        int xScale, yScale;
        hb_font_get_scale(font, &xScale, &yScale);
        return vec2i(xScale, yScale);
    }

    /**
        Gets the font scale
    */
    void setScale(vec2i scale) nothrow {
        hb_font_set_scale(font, scale.x*64, scale.y*64);
    }

    /**
        Gets the font slant
    */
    final
    float getSlant() nothrow {
        return hb_font_get_synthetic_slant(font);
    }

    /**
        Gets the font slant
    */
    void setSlant(float slant) nothrow {
        hb_font_set_synthetic_slant(font, slant); 
    }

    /**
        Gets the font boldness
    */
    final
    vec2 getBoldness() nothrow {
        float x, y;
        int inplace; // unused
        hb_font_get_synthetic_bold(font, &x, &y, &inplace);

        return vec2(x, y);
    }

    /**
        Gets the font boldness
    */
    void setBoldness(vec2 boldness) nothrow {
        hb_font_set_synthetic_bold (font, boldness.x, boldness.y, doGrading); 
    }

    /**
        Gets whether boldness of a font should be done via grading
    */
    final
    bool getIsGrading() nothrow {
        return doGrading;
    }

    /**
        Gets whether boldness of a font should be done via grading
    */
    final
    void setIsGrading(bool grading) nothrow {

        // Changing grading will automatically redo the boldness.
        doGrading = grading;
        this.setBoldness(this.getBoldness());
    }

    /**
        Static helper function which creates a context using the same backend as the canvas
    */
    static SbFont create(SbFontFace face, int size) {
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