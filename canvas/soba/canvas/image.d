/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module soba.canvas.image;
import soba.canvas.pattern;
import imagefmt;
import numem.all;

enum SbImageFormat {
    /**
        No or invalid image format
    */
    None,

    /**
        Alpha-only image, aligned to 1 byte boundary
    */
    A8,

    /**
        Alpha-only image, aligned to 4 byte boundary
    */
    RGB,

    /**
        Alpha-only image, aligned to 4 byte boundary
    */
    RGBA
}

class SbImage {
nothrow @nogc:
private:
    vector!ubyte pixels;
    uint width, height;
    uint channels;
    uint alignment;

    SbImageFormat fmt;

    void setFmt() {
        switch(channels) {
            default:    fmt = SbImageFormat.None;   return;
            case 1:     fmt = SbImageFormat.A8;     return;
            case 3:     fmt = SbImageFormat.RGB;    return;
            case 4:     fmt = SbImageFormat.RGBA;   return;
        }
    }

protected:

    /**
        Creates a blank image
    */
    this(uint width, uint height, uint channels) {
        this.width = width;
        this.height = height;
        this.channels = channels;
        pixels.reserve(width*height*channels);
        this.setFmt();
    }

    /**
        Creates an image from file
    */
    this(nstring file) {

        IFInfo info = read_info(file.toDString());
        if (info.e != 0) {
            this.channels = info.c;
            this.width = info.w;
            this.height = info.h;

            this.alignment = this.getAlignmentForChannels(info.c);

            // Read the image
            IFImage img = read_image(file.toDString, this.alignment);
            if (img.e != 0) {
                this.pixels = nogc_new!(vector!ubyte)(img.buf8);
                this.setFmt();
            }

            img.free();
        }
    }

    abstract uint getAlignmentForChannels(uint channels);

public:

    ~this() {
        nogc_delete(pixels);
    }

    static SbImage create(uint width, uint height, uint channels) {
        SbImage img;

        return img;
    }

    static SbImage create(nstring file) {
        SbImage img;

        return img;
    }

    /**
        Gets the stride in bytes for the image
    */
    final
    uint getStride() {
        return width*channels;
    }
    /**
        Gets the width of the image
    */
    final
    uint getWidth() {
        return width;
    }

    /**
        Gets the height of the image
    */
    final
    uint getHeight() {
        return height;
    }

    /**
        Gets the alingment of the image data in bytes
    */
    final
    uint getAlignment() {
        return alignment;
    }

    /**
        Gets the format of the image
    */
    final
    SbImageFormat getFormat() {
        return fmt;
    }

    /**
        Gets a pointer to the data

        This data is owned by the SbImage and should not be freed.
    */
    final
    ubyte[] getData() {
        return pixels[0..$];
    }

    /**
        Gets the underlying handle
    */
    abstract void* getHandle();
}