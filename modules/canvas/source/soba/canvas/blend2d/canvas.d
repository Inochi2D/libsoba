/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module soba.canvas.blend2d.canvas;
import soba.canvas.blend2d.ctx;
import soba.canvas.canvas;
import soba.canvas;
import numem.all;
import blend2d;

class SbBLCanvas : SbCanvas {
@nogc:
private:
    BLImage image;
    BLImageData data;
    SbBLContext parent;

    BLPattern pattern;

    void createImage(SbCanvasFormat fmt, uint width, uint height) {

        // Create the underlying surface
        final switch(fmt) {
            case SbCanvasFormat.RGB32:
                blImageInitAs(&image, width, height, BLFormat.BL_FORMAT_XRGB32);
                break;
                
            case SbCanvasFormat.ARGB32:
                blImageInitAs(&image, width, height, BLFormat.BL_FORMAT_PRGB32);
                break;

            case SbCanvasFormat.A8:
                blImageInitAs(&image, width, height, BLFormat.BL_FORMAT_A8);
                break;
        }

        blImageMakeMutable(&image, &data);
        blPatternInitAs(&pattern, &image, null, BLExtendMode.BL_EXTEND_MODE_PAD, null);
    }

protected:

    override
    ubyte* getData() {
        return cast(ubyte*)data.pixelData;
    }

public:

    ~this() {
        blPatternDestroy(&pattern);
        blImageDestroy(&image);
    }

    this(SbCanvasFormat fmt, uint width, uint height) {
        super(SbCanvasBackend.blend2D, fmt, width, height);
        this.createImage(fmt, width, height);
    }

    override
    void resize(uint w, uint h) {
        super.resize(w, h);
        if (image.pixelData) {
            blImageDestroy(&image);
            this.createImage(this.getFormat(), w, h);
        }
    }

    override
    void unlock() {
        super.unlock();
    }

    override
    void* getHandle() {
        return &image;
    }

    BLPattern* getPatternHandle() {
        return &pattern;
    }

    override
    void writeToFile(nstring name) {
        blImageWriteToFile(&image, name.toCString(), null);
    }
}