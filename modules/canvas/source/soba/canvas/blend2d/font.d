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