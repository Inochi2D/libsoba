/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.pattern;
import numem.all;
import inmath.linalg;
import soba.canvas;

import soba.canvas.cairo.pattern;

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
nothrow @nogc:
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
nothrow @nogc:
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

// TODO: Add image source