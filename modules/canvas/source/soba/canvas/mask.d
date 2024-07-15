/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Soba Canvas Masking
*/
module soba.canvas.mask;
import soba.canvas.image;
import soba.canvas.ctx;

/**
    A mask path which can be used during rendering to mask out areas
*/
abstract
class SbMask {
@nogc:
private:
    SbImageFormat fmt;
    SbContext parent;

protected: 
    uint width, height;

public:

    // Constructor
    this(SbImageFormat fmt, SbContext parent) {
        this.fmt = fmt;
        this.parent = parent;
    }

    /**
        Gets the width of the mask
    */
    uint getWidth() {
        return width;
    }
    
    /**
        Gets the height of the mask
    */
    uint getHeight() {
        return height;
    }

    /**
        Gets the parent of the mask
    */
    SbContext getParent() {
        return parent;
    }

    /**
        Gets the underlying handle of the clipping mask
    */
    abstract void* getHandle();
}