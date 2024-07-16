/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.text.fontface;
import harfbuzz;
import numem.all;

/**
    A font face, usable for rendering text.
*/
class SbFontFace {
@nogc:
private:
    hb_blob_t* blob;
    hb_face_t* face;
    uint index;

public:

    /**
        Deconstructor
    */
    ~this() {
        hb_face_destroy(face);
        hb_blob_destroy(blob);
        face = null;
        blob = null;
    }

    /**
        Creates a new font
    */
    this(nstring file, uint index = 0) {
        this.index = index;
        blob = hb_blob_create_from_file(file.toCString());
        face = hb_face_create(blob, index);
    }

    /**
        Gets the underlying handle for the font face.
    */
    final
    hb_face_t* getHandle() {
        return face;
    }

    /**
        Gets a slice of the binary data of the font.
    */
    final
    ubyte[] getData() {
        uint len;
        ubyte* data = cast(ubyte*)hb_blob_get_data(blob, &len);
        return data[0..len];
    }

    /**
        Gets the face index the fontface was created with.
    */
    final
    uint getFaceIndex() {
        return index;
    }
}