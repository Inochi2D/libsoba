/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.cairo.font;
import soba.canvas.text.font;
import soba.canvas.text.fontface;
import numem.all;
import cairo;
import harfbuzz;

nothrow @nogc:

/**
    A font face, usable for rendering text.
*/
class SbCairoFont : SbFont {
@nogc:
private:
    cairo_font_face_t* face;

public:

    /**
        Destructor
    */
    ~this() {
        cairo_font_face_destroy(face);
    }

    /**
        Constructor
    */
    this(SbFontFace face, int size) {
        super(face, size);
        this.face = cnvCreateFontFace(this);
    }

    override
    void* getDrawHandle() {
        return face;
    }
}

void cnvInitHarfbuzzFontRendering() {
    if (!sbCairoDrawFuncs) {
        sbCairoDrawFuncs = hb_draw_funcs_create();
        hb_draw_funcs_set_move_to_func(sbCairoDrawFuncs, &sbCairoMoveTo, null, null);
        hb_draw_funcs_set_line_to_func(sbCairoDrawFuncs, &sbCairoLineTo, null, null);
        hb_draw_funcs_set_cubic_to_func(sbCairoDrawFuncs, &sbCairoCubicTo, null, null);
        hb_draw_funcs_set_close_path_func(sbCairoDrawFuncs, &sbCairoClosePath, null, null);
        hb_draw_funcs_make_immutable(sbCairoDrawFuncs);
    }
}

private:

cairo_font_face_t* cnvCreateFontFace(SbCairoFont font) {
    cairo_font_face_t* face = cairo_user_font_face_create();
    cairo_font_face_set_user_data(face, &sbFontKey, cast(void*)font, null);
    cairo_user_font_face_set_render_glyph_func(face, &sbCairoRenderGlyph);
    return face;
}

// Harfbuzz-cairo interface
extern(C):

// drawfunc store
__gshared hb_draw_funcs_t* sbCairoDrawFuncs;
__gshared cairo_user_data_key_t sbFontKey;



// Glyph rendering
cairo_status_t sbCairoRenderGlyph(cairo_scaled_font_t* scaledFont, ulong glyph, cairo_t* cr, cairo_text_extents_t* extents) {
    auto face = cairo_scaled_font_get_font_face (scaledFont);
    SbCairoFont font = cast(SbCairoFont) cairo_font_face_get_user_data(face, &sbFontKey);
    auto scale = font.getScale();
    
    cairo_scale(cr, +1.0/cast(float)scale.x, -1.0/cast(float)scale.y);
    hb_font_draw_glyph(font.getHandle(), cast(uint)glyph, sbCairoDrawFuncs, cr);
    cairo_fill (cr);
    
    return cairo_status_t.CAIRO_STATUS_SUCCESS;
}

// BASIC CAIRO RENDERING FUNCTIONS.

void sbCairoMoveTo(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, float x, float y, void* userData) {

    cairo_t* cr = cast(cairo_t*) drawData;
    cairo_move_to(cr, cast(double) x, cast(double) y);
}

void sbCairoLineTo(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, float x, float y, void* userData) {

    cairo_t* cr = cast(cairo_t*) drawData;
    cairo_line_to(cr, cast(double) x, cast(double) y);
}

void sbCairoCubicTo(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, float c1x, float c1y, float c2x, float c2y, float x, float y, void* userData) {

    cairo_t* cr = cast(cairo_t*) drawData;
    cairo_curve_to(
        cr,
        cast(double) c1x,   cast(double) c1y,
        cast(double) c2x,   cast(double) c2y,
        cast(double) x,     cast(double) y
    );
}

void sbCairoClosePath(hb_draw_funcs_t* drawFuncs, void* drawData, hb_draw_state_t* drawState, void* userData) {
    cairo_t* cr = cast(cairo_t*) drawData;
    cairo_close_path(cr);
}
