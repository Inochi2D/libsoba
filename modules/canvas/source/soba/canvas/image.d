/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Soba Canvas Bitmaps
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
        RGB image, aligned to a 4 byte boundary
    */
    RGB,

    /**
        RGBA image, aligned to a 4 byte boundary
        
        Stored in ARGB order.
    */
    RGBA
}

class SbImage {
@nogc:
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
            case 4:
                fmt = SbImageFormat.RGBA;
                return;
        }
    }

    void premult(ubyte[] data) {
        for (int k;   k < data.length; k+=4) {
            float r = cast(float)data[k  ]/255.0;
            float g = cast(float)data[k+1]/255.0;
            float b = cast(float)data[k+2]/255.0;
            float a = cast(float)data[k+3]/255.0;

            data[k  ] = cast(ubyte)((r*a)*255.0);
            data[k+1] = cast(ubyte)((g*a)*255.0);
            data[k+2] = cast(ubyte)((b*a)*255.0);
            data[k+3] = data[k+3];
        }
    }

    void setFromImage(ref IFImage img) {
        if (img.c == 4) {

            // Premultiply alpha
            this.premult(img.buf8);

            // Align to ARGB
            pixels.resize(img.buf8.length);
            conv_rgba2bgra(img.buf8, pixels.toSlice());
        } else {
            this.pixels = vector!ubyte(img.buf8);
        }
    }

protected:

    /**
        Gets the amount of bytes the specified amount of channels
        is aligned to.
    */
    uint getAlignmentForChannels(uint channels) {
        if (channels <= 1)
            return channels;
        return 4;
    }

public:

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
        if (info.e == 0) {
            this.channels = info.c;
            this.width = info.w;
            this.height = info.h;

            this.alignment = this.getAlignmentForChannels(info.c);

            // Read the image
            IFImage img = read_image(file.toDString, this.alignment);
            if (img.e == 0) {
                import core.stdc.stdio : printf;
                printf("awawa!\n");
                this.setFmt();
                this.setFromImage(img);
            }

            img.free();
        }
    }

    ~this() {
        nogc_delete(pixels);
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
        Gets the amount of channels in the image
    */
    final
    uint getChannels() {
        return channels;
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
}