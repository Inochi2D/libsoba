/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module soba.canvas.blend2d.font;
import soba.canvas.text.font;
import soba.canvas.text.fontface;
import numem.all;
import blend2d;
import harfbuzz;

/**
    A font face, usable for rendering text.
*/
class SbBLFont : SbFont {
@nogc:
private:
    BLGlyphBuffer backingBuffer;
    
    BLFontData data;
    BLFontFace face;
    BLFont font;

public:

    /**
        Constructor
    */
    this(SbFontFace pface, int size) {
        this.setScaleFactor(1);
        super(pface, size);


        // Get font data from harfbuzz
        ubyte[] fontData = pface.getData();
        blFontDataInit(&data);
        blFontDataCreateFromData(&data, fontData.ptr, fontData.length, null, null);
        
        // Create a font face for rendering.
        blFontFaceInit(&face);
        blFontFaceCreateFromData(&face, &data, pface.getFaceIndex());

        blFontInit(&font);
        blFontCreateFromFace(&font, &face, size);
    }

    /**
        Sets the size of the font
    */
    override
    void setSize(int size) {
        super.setSize(size);
        blFontSetSize(&font, size);
    }

    override
    void* getDrawHandle() {
        return &font;
    }
}

@nogc nothrow:

void cnvInitBLFontRendering() {
    if (!sbBLDrawFuncs) {
        sbBLDrawFuncs = hb_draw_funcs_create();
        hb_draw_funcs_set_move_to_func(sbBLDrawFuncs, &sbBLMoveTo, null, null);
        hb_draw_funcs_set_line_to_func(sbBLDrawFuncs, &sbBLLineTo, null, null);
        hb_draw_funcs_set_cubic_to_func(sbBLDrawFuncs, &sbBLCubicTo, null, null);
        hb_draw_funcs_set_quadratic_to_func(sbBLDrawFuncs, &sbBLQuadTo, null, null);
        hb_draw_funcs_set_close_path_func(sbBLDrawFuncs, &sbBLClosePath, null, null);
        hb_draw_funcs_make_immutable(sbBLDrawFuncs);
    }
}

void cnvPathAppendGlyph(SbFont font, BLPath* path, uint glyph, vec2 position) {
    __glyph_intermediate i;
    i.path = path;
    i.position = position;

    hb_font_draw_glyph(font.getHandle(), cast(uint)glyph, sbBLDrawFuncs, &i);
}

private:

struct __glyph_intermediate {
    BLPath* path;
    vec2 position;
}

// Harfbuzz-blend2d interface
extern(C):

// drawfunc store
__gshared hb_draw_funcs_t* sbBLDrawFuncs;


// BASIC Blend2D RENDERING FUNCTIONS.

void sbBLMoveTo(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, float x, float y, void* userData) {

    __glyph_intermediate* i = cast(__glyph_intermediate*) drawData;
    blPathMoveTo(i.path, i.position.x+cast(double) x, i.position.y-cast(double) y);
}

void sbBLLineTo(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, float x, float y, void* userData) {

    __glyph_intermediate* i = cast(__glyph_intermediate*) drawData;
    blPathLineTo(i.path, i.position.x+cast(double) x, i.position.y-cast(double) y);
}

void sbBLCubicTo(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, float c1x, float c1y, float c2x, float c2y, float x, float y, void* userData) {

    __glyph_intermediate* i = cast(__glyph_intermediate*) drawData;
    blPathCubicTo(
        i.path,
        i.position.x+cast(double) c1x,   i.position.y-cast(double) c1y,
        i.position.x+cast(double) c2x,   i.position.y-cast(double) c2y,
        i.position.x+cast(double) x,     i.position.y-cast(double) y
    );
}

void sbBLQuadTo(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, float c1x, float c1y, float c2x, float c2y, void* userData) {

    __glyph_intermediate* i = cast(__glyph_intermediate*) drawData;
    blPathQuadTo(
        i.path,
        i.position.x+cast(double) c1x,   i.position.y-cast(double) c1y,
        i.position.x+cast(double) c2x,   i.position.y-cast(double) c2y
    );
}

void sbBLClosePath(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, void* userData) {

    __glyph_intermediate* i = cast(__glyph_intermediate*) drawData;
    blPathClose(i.path);
}
