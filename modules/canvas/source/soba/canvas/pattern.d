/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Soba Canvas Patterns
*/
module soba.canvas.pattern;
import numem.all;
import inmath.linalg;
import soba.canvas;
import soba.canvas.image;

import soba.canvas.cairo.pattern;
import soba.canvas.blend2d.pattern;

/**
    The sampling mode for patterns
*/
enum SbPatternSampleMode {
    none,
    repeat,
    mirror,
    borderClamp
}

/**
    Which filter to be used
*/
enum SbPatternFilter {
    nearest,
    bilinear,
    gaussian
}

/**
    Dithering algorithm to use.
*/
enum SbPatternDither {
    none,
    fast,
    good,
    best
}

/**
    A pattern which can be used to render to the canvas.
*/
abstract
class SbPattern {
@nogc:
public:
    /**
        Gets the sampling mode
    */
    abstract SbPatternSampleMode getSampleMode();

    /**
        Sets the sampling mode
    */
    abstract void setSampleMode(SbPatternSampleMode mode);

    /**
        Gets the filtering mode
    */
    abstract SbPatternFilter getFiltering();

    /**
        Sets the filtering mode
    */
    abstract void setFiltering(SbPatternFilter filter);

    /**
        Gets the dithering mode
    */
    abstract SbPatternDither getDither();

    /**
        Sets the dithering mode
    */
    abstract void setDither(SbPatternDither filter);

    /**
        Gets the matrix
    */
    abstract mat3 getMatrix();

    /**
        Sets the matrix
    */
    abstract void setMatrix(mat3 matrix);

    /**
        Clears the pattern's matrix
    */
    abstract void clearMatrix();

    /**
        Returns the backing handle
    */
    abstract void* getHandle();
}

/**
    A gradient type
*/
enum SbGradientType {
    linear,
    radial
}

/**
    A gradient
*/
abstract
class SbGradient : SbPattern {
@nogc:
private:
    SbGradientType type;

public:
    this(SbGradientType type) {
        this.type = type;
    }

    /**
        Creates a linear gradient
    */
    static shared_ptr!SbGradient linearGradient(vec2 start, vec2 end) {
        switch(cnvBackendGet()) {
            default:
                shared_ptr!SbGradient grad;
                return grad;

            case SbCanvasBackend.blend2D:
                return shared_ptr!SbGradient.fromPtr(SbBLGradient.linearGradient(start, end));

            case SbCanvasBackend.cairo:
                return shared_ptr!SbGradient.fromPtr(SbCairoGradient.linearGradient(start, end));
        }
    }

    /**
        Creates a radial gradient
    */
    static shared_ptr!SbGradient radialGradient(vec2 inner, float innerRadius, vec2 outer, float outerRadius) {
        switch(cnvBackendGet()) {
            default:
                shared_ptr!SbGradient grad;
                return grad;

            case SbCanvasBackend.blend2D:
                return shared_ptr!SbGradient.fromPtr(SbBLGradient.radialGradient(inner, innerRadius, outer, outerRadius));
            
            case SbCanvasBackend.cairo:
                return shared_ptr!SbGradient.fromPtr(SbCairoGradient.radialGradient(inner, innerRadius, outer, outerRadius));
        }
    }

    /**
        Adds a color stop to the gradient
    */
    abstract void addStop(float offset, vec4 color);

    /**
        Adds a color stop to the gradient
    */
    abstract void addStop(float offset, vec3 color);

    /**
        Gets the amount of stops in this gradient
    */
    abstract uint getStopCount();
    
    /**
        Gets the type of the gradient
    */
    final
    SbGradientType getType() {
        return type;
    }
}

/**
    A pattern which allows an image to be drawn.
    The pattern acquires the lock for the image,
    and it can not be written to while being used as a pattern.

    To unlock the image, simply delete/destroy the SbImagePattern instance.
*/
abstract
class SbImagePattern : SbPattern {
@nogc:
private:
    SbImage image;
    SbImageLock* lock;

protected:

    /// Allows getting the address to the pixel data.
    ubyte[] getData() {
        return lock.data[0..lock.dataLength];
    }

public:

    ~this() {

        // Just in case that D thinks it should delete image.
        image.release(lock);
        image = null;
    }

    /**
        Constructor
    */
    this(SbImage image) {
        this.image = image;
        lock = image.acquire();
    }

    /**
        Gets the image this pattern is reading from
    */
    ref SbImage getImage() {
        return image;
    }

    /**
        Gets the width of the image
    */
    uint getWidth() {
        return image.getWidth();
    }

    /**
        Gets the height of the image
    */
    uint getHeight() {
        return image.getHeight();
    }

    /**
        Creates a image pattern
    */
    static shared_ptr!SbImagePattern fromImage(SbImage image) {
        switch(cnvBackendGet()) {
            default:
                shared_ptr!SbImagePattern grad;
                return grad;

            case SbCanvasBackend.blend2D:
                return shared_ptr!SbImagePattern.fromPtr(nogc_new!SbBLImagePattern(image));

            case SbCanvasBackend.cairo:
                return shared_ptr!SbImagePattern.fromPtr(nogc_new!SbCairoImagePattern(image));
        }
    }
}