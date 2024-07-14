/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Soba Canvas Effects
*/
module soba.canvas.effect;
import soba.canvas.canvas;
import soba.canvas.ctx;
import numem.all;
import inmath;
import inteli.emmintrin;

/**
    A graphical effect applied to a surface
*/
abstract
class SbEffect {
@nogc:
private:
protected:

    /**
        Gets a pixel as a 128 bit SSE value
    */
    pragma(inline, true)
    __m128i getPixelSSE(ubyte* data, vec2i pos, ptrdiff_t alignment, ptrdiff_t stride) {

        // TODO: use _mm_load?
        ptrdiff_t offset = (pos.y*stride)+(pos.x*alignment);
        ubyte[] pixels = data[offset..offset+alignment];
        int[4] values;

        foreach(i; 0..alignment) {
            values[i] = pixels[i];
        }

        return _mm_setr_epi32(values[0], values[1], values[2], values[3]);
    }

    /**
        Sets a pixel as a 128 bit SSE value
    */
    pragma(inline, true)
    void setPixelSSE(ubyte* data, vec2i pos, __m128i value, ptrdiff_t alignment, ptrdiff_t stride) {

        size_t offset = (pos.y*stride)+(pos.x*alignment);
        foreach(i; 0..alignment) {
            data[offset+i] = cast(ubyte)value.array[i];
        }

        // Flush cache
        _mm_clflush(data);
    }

    /**
        Gets a pixel as a byte slice
    */
    ubyte[] getPixel(ubyte* data, vec2i pos, ptrdiff_t alignment, ptrdiff_t stride) {
        ptrdiff_t offset = (pos.y*stride)+(pos.x*alignment);
        return data[offset..offset+alignment];
    }

    /**
        Sets a pixel as a byte slice
    */
    void setPixel(ubyte* data, vec2i pos, ubyte[] value, ptrdiff_t alignment, ptrdiff_t stride) {

        size_t offset = (pos.y*stride)+(pos.x*alignment);
        foreach(i; 0..min(alignment, value.length)) {
            data[offset+i] = value[i];
        }
    }
public:
    abstract void apply(SbContext context, recti clipArea=recti(0, 0, int.max, int.max));
}