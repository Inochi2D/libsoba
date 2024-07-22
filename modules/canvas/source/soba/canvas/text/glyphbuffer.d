/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.text.glyphbuffer;
import soba.canvas.text.font;
import harfbuzz;
import numem.all;
import inmath;

/// GlyphId of the character
alias SbGlyphId = uint;

@nogc:

/**
    Text shaping direction
*/
enum SbTextDirection : uint {
    invalid = 0,

    /**
        Left-to-right
    */
    ltr = 4,
    
    /**
        Right-to-left
    */
    rtl,
    
    /**
        Top-to-bottom
    */
    ttb,
    
    /**
        Bottom-to-top
    */
    btt
}

/**
    Gets whether the direction is horizontal
*/
bool isHorizontal(SbTextDirection direction) {
    return (((cast(uint)direction) & ~1U) == 4);
}

/**
    Gets whether the direction is vertical
*/
bool isVertical(SbTextDirection direction) {
    return (((cast(uint)direction) & ~1U) == 6);
}

/**
    Gets whether the direction is forward
*/
bool isForward(SbTextDirection direction) {
    return (((cast(uint)direction) & ~2U) == 4);
}

/**
    Gets whether the direction is backward
*/
bool isBackward(SbTextDirection direction) {
    return (((cast(uint)direction) & ~2U) == 5);
}

/**
    Reverses the given text direction
*/
SbTextDirection reverse(SbTextDirection direction) {
    return cast(SbTextDirection)((cast(uint)direction) ^ 1);
}

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
        Guess segment properties
    */
    void guessSegmentProperties() {
        
        // We're not sure what the properties of the segment is
        // For now, we'll let harfbuzz guess.
        hb_buffer_guess_segment_properties(buf);
    }

    /**
        Gets the text direction
    */
    SbTextDirection getDirection() {
        return cast(SbTextDirection)hb_buffer_get_direction(buf);
    }

    /**
        Sets the text direction
    */
    void setDirection(SbTextDirection textDirection) {
        hb_buffer_set_direction(buf, cast(hb_direction_t)textDirection);
    }

    /**
        Sets the text direction
    */
    void setLanguage(string code) {
        hb_buffer_set_language(buf, hb_language_from_string(code.ptr, cast(int)code.length));
    }

    /**
        Sets the text direction
    */
    nstring getLanguage() {
        const(char)* str = hb_language_to_string(hb_buffer_get_language(buf));
        return nstring(str);
    }

    /**
        Gets the script used in the buffer
    */
    uint getScript() {
        return hb_buffer_get_script(buf);
    }

    /**
        Gets the script used in the buffer
    */
    void setScript(uint script) {
        hb_buffer_set_script(buf, cast(hb_script_t)script);
    }

    /**
        Shapes the text using the specified font
    */
    final
    void shape(SbFont font) {
        if (!font) return;
        
        hb_shape(font.getHandle(), buf, null, 0);

        // Build SbGlyph buffer up
        uint count;
        hb_glyph_info_t *glyph_info     = hb_buffer_get_glyph_infos(buf, &count);
        hb_glyph_position_t *glyph_pos  = hb_buffer_get_glyph_positions(buf, &count);
        
        SbTextDirection direction = this.getDirection();
        float tracking = font.getTracking();
        int offsetY = cast(int)font.getBaseline();

        if (direction.isForward() && font.getTopLeftOrigin()) {
            offsetY += cast(int)font.getSize();
        }

        foreach(i; 0..count) {
            float xadvance = glyph_pos[i].x_advance*tracking;
            float yadvance = -glyph_pos[i].y_advance;

            SbGlyph glyph;
            glyph.glyphId = glyph_info[i].codepoint;
            glyph.xAdvance = cast(int)xadvance;
            glyph.yAdvance = cast(int)yadvance;
            
            glyph.xOffset = glyph_pos[i].x_offset;
            glyph.yOffset = (glyph_pos[i].y_offset-offsetY);

            shaped ~= glyph;
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