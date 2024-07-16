/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.text.glyphbuffer;
import soba.canvas.text.font;
import harfbuzz;
import numem.all;

/// GlyphId of the character
alias SbGlyphId = uint;

/**
    A glyph
*/
struct SbGlyph {
    /**
        The Id of the glyph
    */
    SbGlyphId glyphId;

    /**
        The X offset
    */
    int xOffset;

    /**
        The Y offset
    */
    int yOffset;

    /**
        The X advance
    */
    int xAdvance;
    
    /**
        The Y advance
    */
    int yAdvance;
}

class SbGlyphBuffer {
@nogc:
private:
    hb_buffer_t* buf;
    weak_vector!SbGlyph shaped;

public:

    this() {
        buf = hb_buffer_create();
    }

    /**
        Adds text to the buffer to be shaped.
    */
    final
    void addText(nstring str) {
        hb_buffer_add_utf8(buf, str.ptr, cast(int)str.size, 0, -1);
    }

    /**
        Shapes the text using the specified font
    */
    final
    void shape(SbFont font) {
        
        // We're not sure what the properties of the segment is
        // For now, we'll let harfbuzz guess.
        hb_buffer_guess_segment_properties(buf);

        // TODO: allow specifying properties.
        hb_shape(font.getHandle(), buf, null, 0);

        // Build SbGlyph buffer up
        uint count;
        hb_glyph_info_t *glyph_info     = hb_buffer_get_glyph_infos(buf, &count);
        hb_glyph_position_t *glyph_pos  = hb_buffer_get_glyph_positions(buf, &count);
        
        shaped.resize(count);
        foreach(i; 0..count) {
            SbGlyph glyph;
            glyph.glyphId = glyph_info[i].codepoint;
            glyph.xAdvance = glyph_pos[i].x_advance;
            glyph.yAdvance = glyph_pos[i].y_advance;
            glyph.xOffset = glyph_pos[i].x_offset;
            glyph.yOffset = glyph_pos[i].y_offset;

            shaped[i] = glyph;
        }
    }

    /**
        Gets list of glyphs
    */
    final
    SbGlyph[] getGlyphs() {
        return shaped.toSlice();
    }

    /**
        Resets the glyph buffer
    */
    final
    void reset() {
        hb_buffer_clear_contents(buf);
        shaped.resize(0);
    }
}