/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.ctx;
import soba.canvas.canvas;
import soba.canvas.pattern;
import soba.canvas;
import inmath.linalg;
import numem.all;

import soba.canvas.cairo.ctx;

/**
    Fill rule
*/
enum SbFillRule {
    winding,
    evenOdd
}

/**
    Line cap style
*/
enum SbLineCap {
    butt,
    round,
    square
}

/**
    Line join style
*/
enum SbLineJoin {
    miter,
    round,
    bevel
}

/**
    Blending operator
*/
enum SbBlendOperator {
    clear,
    source,
    sourceOver,
    sourceIn,
    sourceOut,
    sourceAtop,
    dest,
    destOver,
    destIn,
    destOut,
    destAtop,
    xor,
    add,
    saturate,
    multiply,
    screen,
    overlay,
    darken,
    lighten,
    colorDodge,
    colorBurn,
    hardLight,
    softLight,
    difference,
    exclusion,
    hslHue,
    hslSaturation,
    hslColor,
    hslLuminosity
}

/**
    A rendering context
*/
abstract
class SbContext {
nothrow @nogc:
private:
    SbCanvas target;

public:

    /**
        Creates a context for the specified canvas
    */
    this(SbCanvas target) {
        this.target = target;
    }

    /**
        Static helper function which creates a context using the same backend as the canvas
    */
    static SbContext create(SbCanvas canvas) {
        switch(canvas.getBackend()) {
            case SbCanvasBackend.cairo:
                return nogc_new!SbCairoContext(canvas);
            default:
                return null;
        }
    }

    /**
        Returns the target of this context's drawing operations
    */
    final
    SbCanvas getTarget() {
        return target;
    }

    /**
        Sets the fill rule
    */
    abstract void setFillRule(SbFillRule cap);

    /**
        Gets the fill rule
    */
    abstract SbFillRule getFillRule();

    /**
        Sets the line cap style
    */
    abstract void setLineCap(SbLineCap cap);

    /**
        Gets the line cap style
    */
    abstract SbLineCap getLineCap();

    /**
        Sets the line join style
    */
    abstract void setLineJoin(SbLineJoin join);

    /**
        Gets the line join style
    */
    abstract SbLineJoin getLineJoin();

    /**
        Sets the blending operator
    */
    abstract void setBlendOperator(SbBlendOperator op);

    /**
        Gets the blending operator
    */
    abstract SbBlendOperator getBlendOperator();

    /**
        Sets the current line width
    */
    abstract void setLineWidth(float width);

    /**
        Gets the current line width
    */
    abstract float getLineWidth(float width);

    /**
        Fills the current path
    */
    abstract void fill();

    /**
        Fills the current path
    
        Preserves the path for reuse
    */
    abstract void fillPreserve();

    /**
        Strokes the current path
    */
    abstract void stroke();

    /**
        Strokes the current path
    
        Preserves the path for reuse
    */
    abstract void strokePreserve();

    /**
        Clears the current path
    */
    abstract void clearPath();

    /**
        Moves the path cursor to the specified point
    */
    abstract void moveTo(vec2 pos);

    /**
        Draws a line from the current cursor position to the specified point
    */
    abstract void lineTo(vec2 pos);

    /**
        Draws a cubic bézier spline curve from the current cursor position to the specified point
        using ctrl1 and ctrl2 as control points
    */
    abstract void curveTo(vec2 pos, vec2 ctrl1, vec2 ctrl2);

    /**
        Creates an arc from the cursor to the specified point
    */
    abstract void arcTo(vec2 point);

    /**
        Creates a rectangle path
    */
    abstract void rect(inmath.linalg.rect r);

    /**
        Creates a rounded rectangle path
    */
    abstract void roundRect(inmath.linalg.rect r, float borderRadius);

    /**
        Creates a rounded rectangle path with individual border radii
    */
    abstract void roundRect(inmath.linalg.rect r, float borderRadiusTL, float borderRadiusTR, float borderRadiusBL, float borderRadiusBR);

    /**
        Creates a squircle
    */
    abstract void squircle(inmath.linalg.rect r, float elasticity);

    /**
        Closes the path
    */
    abstract void closePath();

    /**
        Returns the position of the cursor in the current path.
    */
    abstract vec2 getPathCursorPos();

    /**
        Gets the extents of the current path
    */
    abstract inmath.linalg.rect getPathExtents();

    /**
        Sets the color of the sourde
    */
    abstract void setSource(vec4 color);

    /**
        Sets the color of the sourde
    */
    abstract void setSource(vec3 color);

    /**
        Sets the source for rendering
    */
    abstract void setSource(SbPattern pattern);

    /**
        Sets the source for rendering
    */
    abstract void setSource(SbCanvas canvas, vec2 offset=vec2(0));
}