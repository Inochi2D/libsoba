/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module soba.canvas.effects.blur;
import soba.canvas.effect;
import soba.canvas.canvas;
import numem.all;
import inmath;
import core.stdc.stdio : printf;

// SSE 2
import inteli.emmintrin;


/**
    A blur effect
*/
class SbBlurEffect : SbEffect {
nothrow @nogc:
private:
    uint blurSigma;

    static if (!SSESizedVectorsAreEmulated) {

        pragma(inline, true)
        __m128i getPixel(ubyte* data, vec2i pos, ptrdiff_t alignment, ptrdiff_t stride) {

            // TODO: use _mm_load?
            ptrdiff_t offset = (pos.y*stride)+(pos.x*alignment);
            ubyte[] pixels = data[offset..offset+alignment];
            int[4] values;

            foreach(i; 0..alignment) {
                values[i] = pixels[i];
            }

            return _mm_setr_epi32(values[0], values[1], values[2], values[3]);
        }

        pragma(inline, true)
        void setPixel(ubyte* data, vec2i pos, __m128i value, ptrdiff_t alignment, ptrdiff_t stride) {

            size_t offset = (pos.y*stride)+(pos.x*alignment);
            foreach(i; 0..alignment) {
                data[offset+i] = cast(ubyte)value.array[i];
            }

            // Flush cache
            _mm_clflush(data);
        }

        // SIMD
        void blur(bool direction)(ref SbCanvas canvas, recti area)  {
            ptrdiff_t alignment = canvas.getAlign();
            ptrdiff_t stride = canvas.getStride();
            ubyte* data = canvas.lock();

            foreach(y; area.top..area.bottom) {
                foreach(x; area.left..area.right) {
                    
                    int sumCount = 1;
                    __m128i sum = getPixel(data, vec2i(x, y), alignment, stride);

                    foreach(i; 1..blurSigma) {
                        __m128i pixp = _mm_set1_epi32(0);

                        static if (direction) {

                            ptrdiff_t up = cast(ptrdiff_t)y-cast(ptrdiff_t)i;
                            ptrdiff_t down = cast(ptrdiff_t)y+cast(ptrdiff_t)i;
                            if (up >= area.top) {
                                pixp = _mm_add_epi32(pixp, getPixel(data, vec2i(x, cast(int)up), alignment, stride));
                                sumCount++;
                            }

                            if (down <= area.bottom) {
                                pixp = _mm_add_epi32(pixp, getPixel(data, vec2i(x, cast(int)down), alignment, stride));
                                sumCount++;
                            }
                        } else {
                            
                            ptrdiff_t left = cast(ptrdiff_t)x-cast(ptrdiff_t)i;
                            ptrdiff_t right = cast(ptrdiff_t)x+cast(ptrdiff_t)i;
                            if (left >= area.left) {
                                pixp = _mm_add_epi32(pixp, getPixel(data, vec2i(cast(int)left, y), alignment, stride));
                                sumCount++;
                            }

                            if (right <= area.right) {
                                pixp = _mm_add_epi32(pixp, getPixel(data, vec2i(cast(int)right, y), alignment, stride));
                                sumCount++;
                            }  
                        }

                        // Set sum
                        sum = _mm_add_epi32(sum, pixp);
                    }

                    __m128 fsum = _mm_castsi128_ps(sum);
                    __m128 fcount = _mm_set1_ps(cast(float)sumCount);
                    __m128 result = _mm_div_ps(fsum, fcount);
                    setPixel(data, vec2i(x, y), _mm_castps_si128(result), alignment, stride);
                }
            }

            canvas.unlock();
        }
    } else {

        // NO SIMD
        void blur(ref SbCanvas canvas, recti area) {

        }
    }



public:
    this(uint blurSigma) {
        this.blurSigma = blurSigma;
    }

    /**
        Sets the blur sigma (essentially radius)
    */
    void setBlurSigma(uint sigma) {
        this.blurSigma = sigma;
    }

    /**
        Gets the blur sigma (essentially radius)
    */
    uint getBlurSigma() {
        return blurSigma;
    }

    /**
        Applies the blur
    */
    override
    void apply(ref SbCanvas canvas, recti clipArea) {

        // Make sure we don't try reading pixels in invalid memory
        clipArea.clip(recti(0, 0, canvas.getWidth(), canvas.getHeight()));
        this.blur!true(canvas, clipArea);
        this.blur!false(canvas, clipArea);
    }
}