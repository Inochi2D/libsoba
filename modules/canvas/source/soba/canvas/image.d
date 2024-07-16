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
    RGB32,

    /**
        RGBA image, aligned to a 4 byte boundary
        
        Stored in ARGB order.
    */
    RGBA32
}

/**
    A structure which allows modifying a texture once locked.
*/
struct SbImageLock {
@nogc:
private:
    SbImage parent;
    bool acquired;

public:
    ubyte* data;
    size_t dataLength;
    int width;
    int height;
    size_t stride;

    this(SbImage parent) {
        this.parent = parent;
        this.acquired = false;
    }
}

class SbImage {
@nogc:
private:
    SbImageLock rwLock;

    vector!ubyte pixels;
    uint width, height;
    uint channels;
    uint alignment;

    SbImageFormat fmt;
    
    void setFmt() {
        switch(channels) {
            default:    fmt = SbImageFormat.None;   return;
            case 1:     fmt = SbImageFormat.A8;     return;
            case 3:     fmt = SbImageFormat.RGB32;    return;
            case 4:
                fmt = SbImageFormat.RGBA32;
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

    // Sets buffer from PNG aligned data
    void setFromBuffer(ref ubyte[] buffer, int channels, int width, int height) {
        
        // Dangerous operation!
        if (buffer.length != width*height*channels) return;

        // Alignment
        size_t realAlign = getAlignmentForChannels(channels);
        ubyte[] destination;
        ubyte[] source;

        // Temporary buffer
        // This temporary buffer is here to allow conversion.
        vector!ubyte tmp;

        // Realign data
        if (realAlign != 1 && realAlign % buffer.length != 0) {

            // Proper alignment
            tmp.resize(width*height*realAlign);
            destination = tmp.toSlice();

            foreach(i; 0..width*height) {

                // Realign the data
                size_t srcOffset = channels*i;
                size_t dstOffset = realAlign*i;
                foreach(c; 0..channels) {
                    destination[dstOffset+c] = buffer[srcOffset+c];
                }
            }

        } else {

            // No realignment
            tmp.resize(buffer.length);
            destination = tmp.toSlice();

            // Copy data over
            destination[0..$] = buffer[0..$];
        }

        // Copy data over
        pixels = vector!ubyte(tmp);

        // Premult alpha and bgra conversion.
        if (realAlign == 4) {

            // Source/destination changes in this case for bgra and premult calculation.
            source = tmp.toSlice();
            destination = pixels.toSlice(); 

            // Premultiply alpha
            this.premult(source);
            // conv_rgba2bgra(source, destination);
        }

        // Aaaand we're done.
        this.alignment = cast(uint)realAlign;
        this.width = width;
        this.height = height;
        this.channels = channels;
        this.setFmt();

        // Done with tmp buffer.
        nogc_delete(tmp);
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
        size_t realAlign = getAlignmentForChannels(channels);
        this.alignment = cast(uint)realAlign;

        this.width = width;
        this.height = height;
        this.channels = channels;
        this.rwLock = SbImageLock(this);
        
        this.setFmt();

        if(this.fmt != SbImageFormat.None) {        
            pixels.resize(width*height*realAlign);
        }
    }

    /**
        Creates an 8 bit image
    */
    this(ubyte[] data, uint width, uint height, uint channels) {
        this.rwLock = SbImageLock(this);
        this.setFromBuffer(data, channels, width, height);
    }

    /**
        Creates an image from file
    */
    this(nstring file) {
        this.rwLock = SbImageLock(this);

        IFInfo info = read_info(file.toDString());
        if (info.e == 0) {

            // Read the image
            IFImage img = read_image(file.toDString, this.alignment);
            if (img.e == 0) {
                this.setFromBuffer(img.buf8, info.c, info.w, info.h);
            }

            // This setFmt call is here to catch error states.
            this.setFmt();
            img.free();
        }
    }

    /**
        Frees the image
    */
    ~this() {
        nogc_delete(pixels);
    }

    /**
        Gets the stride in bytes for the image
    */
    final
    uint getStride() {
        return width*alignment;
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
        Attempts to resize the image.
        Note: the image needs to be unlocked before it can be resized.

        Returns whether this action succeded.
    */
    final
    bool resize(uint width, uint height) {
        SbImageLock* lock = acquire();
        if (lock) {
            
            this.width = width;
            this.height = height;
            this.pixels.resize(width*height*alignment);

            release(lock);
            return true;
        }

        return false;
    }

    /**
        Attempts to acquire the lock for the image

        Returns a reference to the image lock if successful.
        Returns null otherwise.
    */
    final
    SbImageLock* acquire() {
        if (!rwLock.acquired && rwLock.parent is this) {
            rwLock.acquired = true;
            rwLock.data = pixels.data;
            rwLock.dataLength = pixels.size();

            // Data needed by context
            rwLock.width = width;
            rwLock.height = height;
            rwLock.stride = width*alignment;
            return &rwLock;
        }

        return null;
    }

    /**
        Releases the image lock
    */
    final
    void release(ref SbImageLock* lock) {
        if (lock && lock.acquired) {
            (*lock).acquired = false;
            lock = null;
        }
    }

    /**
        Gets whether the lock for the image has been acquired
    */
    final
    bool isLocked() {
        return rwLock.acquired;
    }

    /**
        Writes content of the canvas to file
    */
    final
    void writeToFile(nstring name) {
        this.writeToFile(name.toDString());
    }

    /**
        Writes content of the canvas to file
    */
    final
    void writeToFile(string name) {
        SbImageLock* lock = this.acquire();
        if (lock) {

            // Converts textures to appropriate format for writing.
            vector!ubyte tmp;
            tmp.resize(width*height*channels);
            if (alignment != channels) {
                conv8 convfunc = cast(conv8) getconv(alignment, channels, 8);
                convfunc(pixels.toSlice(), tmp.toSlice());
            }

            write_image(name, width, height, tmp.toSlice(), channels);

            nogc_delete(tmp);
            this.release(lock);
        }
    }
}