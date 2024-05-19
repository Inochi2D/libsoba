/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module soba.canvas.image;
import imagefmt;
import numem.all;

enum SbImageFormat {
    A8,
    RG,
    RGB,
    RGBA
}

class SbImage {
nothrow @nogc:
private:
    vector!ubyte pixels;
    uint width, height;
    uint channels;

    SbImageFormat fmt;

public:

    this(uint width, uint height, uint channels) {
        this.width = width;
        this.height = height;
        this.channels = channels;
        pixels.reserve(width*height*channels);
    }

    /**
        Gets the stride in bytes for the image
    */
    uint getStride() {
        return width*channels;
    }
}