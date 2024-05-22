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
    A box blur effect
*/
class SbBoxBlurEffect : SbEffect {
nothrow @nogc:
private:
    uint blurSigma;

    // SIMD
    void blurSSE(bool direction)(ref SbCanvas canvas, recti area)  {
        ptrdiff_t alignment = canvas.getAlign();
        ptrdiff_t stride = canvas.getStride();
        ubyte* data = canvas.lock();

        foreach(y; area.top..area.bottom) {
            foreach(x; area.left..area.right) {
                
                int sumCount = 1;
                __m128i sum = getPixelSSE(data, vec2i(x, y), alignment, stride);

                foreach(i; 0..blurSigma) {
                    ptrdiff_t offset = (i+1);
                    __m128i pixp = _mm_set1_epi32(0);

                    static if (direction) {

                        ptrdiff_t up = cast(ptrdiff_t)y-cast(ptrdiff_t)offset;
                        ptrdiff_t down = cast(ptrdiff_t)y+cast(ptrdiff_t)offset;
                        if (up >= area.top) {
                            pixp = _mm_add_epi32(pixp, getPixelSSE(data, vec2i(x, cast(int)up), alignment, stride));
                            sumCount++;
                        }

                        if (down <= area.bottom) {
                            pixp = _mm_add_epi32(pixp, getPixelSSE(data, vec2i(x, cast(int)down), alignment, stride));
                            sumCount++;
                        }
                    } else {
                        
                        ptrdiff_t left = cast(ptrdiff_t)x-cast(ptrdiff_t)offset;
                        ptrdiff_t right = cast(ptrdiff_t)x+cast(ptrdiff_t)offset;
                        if (left >= area.left) {
                            pixp = _mm_add_epi32(pixp, getPixelSSE(data, vec2i(cast(int)left, y), alignment, stride));
                            sumCount++;
                        }

                        if (right <= area.right) {
                            pixp = _mm_add_epi32(pixp, getPixelSSE(data, vec2i(cast(int)right, y), alignment, stride));
                            sumCount++;
                        }  
                    }

                    // Set sum
                    sum = _mm_add_epi32(sum, pixp);
                }

                __m128 fsum = _mm_castsi128_ps(sum);
                __m128 fcount = _mm_set1_ps(cast(float)sumCount);
                __m128 result = _mm_div_ps(fsum, fcount);
                setPixelSSE(data, vec2i(x, y), _mm_castps_si128(result), alignment, stride);
            }
        }

        canvas.unlock();
    }

    // NO SIMD
    void blur(bool direction)(ref SbCanvas canvas, recti area) {
        ptrdiff_t alignment = canvas.getAlign();
        ptrdiff_t stride = canvas.getStride();
        ubyte* data = canvas.lock();

        foreach(y; area.top..area.bottom) {
            foreach(x; area.left..area.right) {

                // Largest pixel size possible is 4-byte aligned.
                int sumCount = 1;
                int[4] sum;
                ubyte[4] acc;

                foreach(i, pix; getPixel(data, vec2i(x, y), alignment, stride)) {
                    sum[i] = cast(int)pix;
                }

                foreach(i; 1..blurSigma) {
                    ptrdiff_t offset = (i+1);
                    int[4] pixp;


                    static if (direction) {

                        ptrdiff_t up = cast(ptrdiff_t)y-cast(ptrdiff_t)offset;
                        ptrdiff_t down = cast(ptrdiff_t)y+cast(ptrdiff_t)offset;
                        if (up >= area.top) {
                            auto pixel = getPixel(data, vec2i(x, cast(int)up), alignment, stride);
                            foreach(ix; 0..alignment) pixp[ix] += pixel[ix];
                            sumCount++;
                        }

                        if (down <= area.bottom) {
                            auto pixel = getPixel(data, vec2i(x, cast(int)down), alignment, stride);
                            foreach(ix; 0..alignment) pixp[ix] += pixel[ix];
                            sumCount++;
                        }
                    } else {
                        
                        ptrdiff_t left = cast(ptrdiff_t)x-cast(ptrdiff_t)offset;
                        ptrdiff_t right = cast(ptrdiff_t)x+cast(ptrdiff_t)offset;
                        if (left >= area.left) {
                            auto pixel = getPixel(data, vec2i(cast(int)left, y), alignment, stride);
                            foreach(ix; 0..alignment) pixp[ix] += pixel[ix];
                            sumCount++;
                        }

                        if (right <= area.right) {
                            auto pixel = getPixel(data, vec2i(cast(int)right, y), alignment, stride);
                            foreach(ix; 0..alignment) pixp[ix] += pixel[ix];
                            sumCount++;
                        }  
                    }

                    // Set sum
                    sum[0..4] += pixp[0..4];
                }

                sum[0..4] /= sumCount;
                foreach(i; 0..sum.length) {
                    acc[i] = cast(ubyte)sum[i];
                }

                setPixel(data, vec2i(x, y), acc[0..alignment], alignment, stride);
            }
        }
        canvas.unlock();
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
        static if (!SSESizedVectorsAreEmulated) {
            this.blurSSE!true(canvas, clipArea);
            this.blurSSE!false(canvas, clipArea);
        } else {
            this.blur!true(canvas, clipArea);
            this.blur!false(canvas, clipArea);
        }
    }
}

/**
    A (slower) gaussian blur effect
*/
class SbGaussianBlurEffect : SbEffect {
nothrow @nogc:
private:
    uint radius;

    enum SB_MIN_GAUSSIAN_RADIUS = 3;
    enum SB_MAX_GAUSSIAN_RADIUS = 32;
    vector!float gaussianKernel;

    void regenerateGaussianMatrix() {
        gaussianKernel.resize(radius * 2 + 1);
        double radSquare2 = 1.0 / (2.0 * radius * radius);
        double sqrt2PiTimesRad = 1.0 / (sqrt(2.0 * PI) * radius);

        // Generate general kernel
        int r = -radius;
        double sum = 0;
        foreach(i; 0..gaussianKernel.size) {
            double x = r;
            x *= x;
            gaussianKernel[i] = sqrt2PiTimesRad * exp(-x * radSquare2);
            sum += gaussianKernel[i];
            r++;
        }

        // Normalize to 0..1
        foreach(i; 0..gaussianKernel.size) {
            gaussianKernel[i] /= sum;
        }
    }


    // SIMD
    void blurSSE(bool direction)(ref SbCanvas canvas, recti area)  {
        ptrdiff_t alignment = canvas.getAlign();
        ptrdiff_t stride = canvas.getStride();
        ubyte* data = canvas.lock();

        foreach(y; area.top..area.bottom) {
            foreach(x; area.left..area.right) {
                ptrdiff_t kernelCenter = radius;
                // __m128 sum = _mm_castsi128_ps(getPixelSSE(data, vec2i(x, y), alignment, stride));
                __m128 sum = _mm_mul_ps(
                    _mm_castsi128_ps(getPixelSSE(data, vec2i(x, y), alignment, stride)), 
                    gaussianKernel[kernelCenter]
                );

                foreach(i; 0..radius) {
                    ptrdiff_t offset = (i+1);

                    static if (direction) {
                        ptrdiff_t up = cast(ptrdiff_t)y-cast(ptrdiff_t)offset;
                        ptrdiff_t down = cast(ptrdiff_t)y+cast(ptrdiff_t)offset;
                        
                        ptrdiff_t kup = kernelCenter-offset;
                        ptrdiff_t kdown = kernelCenter+offset;

                        if (up >= area.top) {
                            __m128 px = _mm_castsi128_ps(getPixelSSE(data, vec2i(x, cast(int)up), alignment, stride));
                            __m128 gaussianV = _mm_set1_ps(gaussianKernel[kup]);

                            sum = _mm_add_ps(sum, _mm_mul_ps(px, gaussianV));
                        }

                        if (down <= area.bottom) {
                            __m128 px = _mm_castsi128_ps(getPixelSSE(data, vec2i(x, cast(int)down), alignment, stride));
                            __m128 gaussianV = _mm_set1_ps(gaussianKernel[kdown]);

                            sum = _mm_add_ps(sum, _mm_mul_ps(px, gaussianV));
                        }
                    } else {
                        ptrdiff_t left = cast(ptrdiff_t)x-offset;
                        ptrdiff_t right = cast(ptrdiff_t)x+offset;

                        ptrdiff_t kleft = kernelCenter-offset;
                        ptrdiff_t kright = kernelCenter+offset;

                        if (left >= area.left) {
                            __m128 px = _mm_castsi128_ps(getPixelSSE(data, vec2i(cast(int)left, y), alignment, stride));
                            __m128 gaussianV = _mm_set1_ps(gaussianKernel[kleft]);

                            sum = _mm_add_ps(sum, _mm_mul_ps(px, gaussianV));
                        }

                        if (right <= area.right) {
                            __m128 px = _mm_castsi128_ps(getPixelSSE(data, vec2i(cast(int)right, y), alignment, stride));
                            __m128 gaussianV = _mm_set1_ps(gaussianKernel[kright]);

                            sum = _mm_add_ps(sum, _mm_mul_ps(px, gaussianV));
                        }
                    }
                }

                setPixelSSE(data, vec2i(x, y), _mm_castps_si128(sum), alignment, stride);
            }
        }

        canvas.unlock();
    }

public:

    this(uint radius) {
        this.setKernelRadius(radius);
    }

    /**
        Gets the radius of the gaussian kernel
    */
    uint getKernelRadius() {
        return radius;
    }

    /**
        Sets the radius of the gaussian kernel
    */
    final
    uint setKernelRadius(uint value) {
        value = clamp(value, SB_MIN_GAUSSIAN_RADIUS, SB_MAX_GAUSSIAN_RADIUS);
        if (value != this.radius) {
            this.radius = value;
            this.regenerateGaussianMatrix();
        }
        return radius;
    }

    /**
        Applies the blur
    */
    override
    void apply(ref SbCanvas canvas, recti clipArea) {

        // Make sure we don't try reading pixels in invalid memory
        clipArea.clip(recti(0, 0, canvas.getWidth(), canvas.getHeight()));
        static if (!SSESizedVectorsAreEmulated) {
            this.blurSSE!true(canvas, clipArea);
            this.blurSSE!false(canvas, clipArea);
        }
    }
}