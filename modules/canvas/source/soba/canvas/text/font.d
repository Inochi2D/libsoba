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

/**
    Font extents
*/
struct SbFontExtents {
    float ascender;
    float descender;
    float lineGap;
}

/**
    Glyph extents
*/
struct SbGlyphExtents {
    float xBearing;
    float yBearing;
    float width;
    float height;
}

/**
    A font face, usable for rendering text.
*/
class SbFont {
@nogc:
private:
    SbFontFace face;
    hb_font_t* font;

    int size;
    bool doGrading;
    float scaleFactor = 64.0;

    bool topLeftOrigin = true;
    float tracking = 1;
    float baseline = 0;

    bool underline = false;

protected:
    final
    void setScaleFactor(float factor) {
        scaleFactor = factor;
    }

public:
    ~this() {
        hb_font_destroy(font);
        font = null;
    }

    this(SbFontFace face, int size) {
        this.face = face;
        this.size = size;

        font = hb_font_create(face.getHandle());
        hb_font_set_scale(font, cast(int)(size), cast(int)(size));
    }

    /**
        Gets the underlying handle for the font.
    */
    hb_font_t* getHandle() nothrow {
        return font;
    }

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
        hb_font_set_scale(font, cast(int)(size), cast(int)(size));
    }

    /**
        Gets the scaling factor to be used.
    */
    float getScaleFactor() {
        return scaleFactor;
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
        hb_font_set_scale(font, cast(int)(scale.x*scaleFactor), cast(int)(scale.y*scaleFactor));
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
        Gets the font tracking
    */
    final
    float getTracking() nothrow {
        return tracking;
    }

    /**
        Gets the font tracking
    */
    void setTracking(float tracking) nothrow {
        this.tracking = tracking;
    }

    /**
        Gets the font baseline
    */
    final
    float getBaseline() nothrow {
        return baseline;
    }

    /**
        Gets the font baseline
    */
    void setBaseline(float baseline) nothrow {
        this.baseline = baseline;
    }

    /**
        Gets whether the font's origin should be on its reported "top left"
    */
    final
    bool getTopLeftOrigin() nothrow {
        return topLeftOrigin;
    }

    /**
        Sets whether the font's origin should be on its reported "top left"
    */
    void setTopLeftOrigin(bool origin) nothrow {
        this.topLeftOrigin = origin;
    }

    /**
        Gets the font underline
    */
    final
    bool getUnderline() nothrow {
        return underline;
    }

    /**
        Gets the font underline
    */
    void setUnderline(bool underline) nothrow {
        this.underline = underline;
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
        Gets the pixels-per-em of the font
    */
    final
    vec2i getPpem() {
        vec2i ppem;
        hb_font_get_ppem(font, cast(uint*)&ppem.vector[0], cast(uint*)&ppem.vector[1]);
        return ppem;
    }

    /**
        Sets the pixels-per-em of the font
    */
    final
    void setPpem(vec2i ppem) {
        hb_font_set_ppem(font, ppem.x, ppem.y);
    }

    /**
        Gets the point size of the font
    */
    final
    float getPointSize() {
        return hb_font_get_ptem(font);
    }

    /**
        Sets the point size of the font
    */
    final
    void setPointSize(float ptem) {
        hb_font_set_ptem(font, ptem);
    }

    /**
        Gets the vertical extents of the font
    */
    final
    SbFontExtents getVerticalExtents() {
        hb_font_extents_t ext;
        hb_font_get_v_extents(font, &ext);
        return SbFontExtents(ext.ascender, ext.descender, ext.line_gap);
    }

    /**
        Gets the horizontal extents of the font
    */
    final
    SbFontExtents getHorizontalExtents() {
        hb_font_extents_t ext;
        hb_font_get_h_extents(font, &ext);
        return SbFontExtents(ext.ascender, ext.descender, ext.line_gap);
    }

    /**
        Gets the glyph extents of the specified codepoint
    */
    final
    SbGlyphExtents getGlyphExtents(uint codepoint) {
        hb_glyph_extents_t extents;
        hb_font_get_glyph_extents(font, codepoint, &extents);

        return SbGlyphExtents(
            extents.x_bearing,
            extents.y_bearing,
            extents.width,
            extents.height,
        );
    }
}




// Font rendering subsystem
@nogc:

void cnvInitFontRendering() {
    if (!sbBLDrawFuncs) {
        import numem.mem.utils : assumeNothrowNoGC;
        sbBLDrawFuncs = hb_draw_funcs_create();
        hb_draw_funcs_set_move_to_func(sbBLDrawFuncs, assumeNothrowNoGC(&sbMoveTo), null, null);
        hb_draw_funcs_set_line_to_func(sbBLDrawFuncs, assumeNothrowNoGC(&sbLineTo), null, null);
        hb_draw_funcs_set_cubic_to_func(sbBLDrawFuncs, assumeNothrowNoGC(&sbCubicTo), null, null);
        hb_draw_funcs_set_quadratic_to_func(sbBLDrawFuncs, assumeNothrowNoGC(&sbQuadTo), null, null);
        hb_draw_funcs_set_close_path_func(sbBLDrawFuncs, assumeNothrowNoGC(&sbClosePath), null, null);
        hb_draw_funcs_make_immutable(sbBLDrawFuncs);
    }
}

void cnvPathAppendGlyph(SbFont font, SbContext context, uint glyph, vec2 position) {
    __glyph_intermediate i;
    i.context = context;
    i.position = position;

    hb_font_draw_glyph(font.getHandle(), cast(uint)glyph, sbBLDrawFuncs, &i);
}

private extern(C):

struct __glyph_intermediate {
    SbContext context;
    vec2 position;
}

// drawfunc store
__gshared hb_draw_funcs_t* sbBLDrawFuncs;

void sbMoveTo(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, float x, float y, void* userData) {

    __glyph_intermediate* i = cast(__glyph_intermediate*) drawData;
    i.context.moveTo(i.position.x+cast(double) x, i.position.y-cast(double) y);
}

void sbLineTo(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, float x, float y, void* userData) {

    __glyph_intermediate* i = cast(__glyph_intermediate*) drawData;
    i.context.lineTo(i.position.x+cast(double) x, i.position.y-cast(double) y);
}

void sbCubicTo(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, float c1x, float c1y, float c2x, float c2y, float x, float y, void* userData) {

    __glyph_intermediate* i = cast(__glyph_intermediate*) drawData;
    i.context.cubicTo(
        i.position.x+cast(double) c1x,   i.position.y-cast(double) c1y,
        i.position.x+cast(double) c2x,   i.position.y-cast(double) c2y,
        i.position.x+cast(double) x,     i.position.y-cast(double) y
    );
}

void sbQuadTo(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, float c1x, float c1y, float c2x, float c2y, void* userData) {

    __glyph_intermediate* i = cast(__glyph_intermediate*) drawData;
    i.context.quadTo(
        i.position.x+cast(double) c1x,   i.position.y-cast(double) c1y,
        i.position.x+cast(double) c2x,   i.position.y-cast(double) c2y
    );
}

void sbClosePath(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, void* userData) {

    __glyph_intermediate* i = cast(__glyph_intermediate*) drawData;
    i.context.closePath();
}
