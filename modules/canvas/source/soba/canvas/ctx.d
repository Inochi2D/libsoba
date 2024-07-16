/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Soba Canvas Rendering Context
*/
module soba.canvas.ctx;
import soba.canvas.image;
import soba.canvas.pattern;
import soba.canvas;
import inmath.linalg;
import numem.all;

import soba.canvas.cairo.ctx;
import soba.canvas.blend2d.ctx;
import soba.canvas.mask;
import soba.canvas.effect;

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

alias SbContextCookie = void*;

/**
    A rendering context
*/
abstract
class SbContext {
@nogc:
private:
    SbImagePattern imageSource;

    SbImage target;
    SbImageLock* lock;
    vector!(recti) clipRects;

    bool acquire(SbImage img) {
        lock = img.acquire();
        if (lock) target = img;
        return lock !is null;
    } 

    bool release() {
        if (lock) {
            target.release(lock);
            target = null;
            return true;
        }
        return false;
    }

protected:

    shared_ptr!SbMask currentMask;
    bool hasMask = false;

    /**
        Gets whether the lock is acquired
    */
    final
    bool hasLock() {
        return lock !is null;
    }

    /**
        Gets the destination image lock
    */
    final
    SbImageLock* getLock() {
        return lock;
    }

    /**
        Clears the image source currently attached.
    */
    final
    void clearImageSource() {
        if (imageSource) {
            nogc_delete(imageSource);
            imageSource = null;
        }
    }

    /**
        Sets the source color for rendering
    */
    abstract void setSourceImpl(vec4 color);

    /**
        Sets the source color for rendering
    */
    abstract void setSourceImpl(vec3 color);

    /**
        Sets the source pattern for rendering
    */
    abstract void setSourceImpl(SbPattern pattern, vec2 offset=vec2(0));

public:

    ~this() {
        this.clearImageSource();
        nogc_delete(clipRects);
    }

    /**
        Creates a context for the specified canvas
    */
    this() {
        imageSource = null;
    }

    /**
        Static helper function which creates a context using the same backend as the canvas
    */
    static shared_ptr!SbContext create() {
        switch(cnvBackendGet()) {
            case SbCanvasBackend.blend2D:
                return shared_ptr!SbContext.fromPtr(nogc_new!SbBLContext()); 
            case SbCanvasBackend.cairo:
                return shared_ptr!SbContext.fromPtr(nogc_new!SbCairoContext());
            default:
                shared_ptr!SbContext ctx;
                return ctx;
        }
    }

    /**
        Returns the target of this context's drawing operations
    */
    final
    SbImage getTarget() {
        return target;
    }

    /**
        Begins drawing to the image
    */
    bool begin(SbImage target) {
        return this.acquire(target);
    }

    /**
        Ends drawing to the image, removing the lock to it
    */
    bool end() {
        return this.release();
    }

    /**
        Returns the underlying handle of this context
    */
    abstract void* getHandle();

    /**
        Saves state of context
    */
    abstract SbContextCookie save();

    /**
        Restores state of context
    */
    abstract void restore(SbContextCookie);

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
        Clears the contents of the destination
    */
    abstract void clearAll();

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
        Creates a mask for the current path.

        Use setMask to use it.
    */
    abstract shared_ptr!SbMask fillMask();

    /**
        Uses the specified mask for rendering.
    */
    abstract void setMask(shared_ptr!SbMask mask);

    /**
        Clears the mask
    */
    abstract void clearMask();

    /**
        Gets whether the specified point is within the clipping region
    */
    abstract bool isInMask(vec2 point);

    /**
        Gets whether the specified point is within the clipping region
    */
    abstract bool isInMask(vec2i point);

    /**
        Gets whether a mask is currently active
    */
    abstract bool isMasked();

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
        Translate the drawn elements
    */
    abstract void translate(vec2 pos);

    /**
        Rotate the drawn elements
    */
    abstract void rotate(float radians);

    /**
        Scale the drawn elements
    */
    abstract void scale(vec2 scale);

    /**
        Resets the transform
    */
    abstract void resetTransform();

    /**
        Returns the position of the cursor in the current path.
    */
    abstract vec2 getPathCursorPos();

    /**
        Gets the extents of the current path
    */
    abstract inmath.linalg.rect getPathExtents();

    /**
        Sets the source color for rendering
    */
    final
    void setSource(vec4 color) {
        this.clearImageSource();
        this.setSourceImpl(color);
    }

    /**
        Sets the source color for rendering
    */
    final
    void setSource(vec3 color) {
        this.clearImageSource();
        this.setSourceImpl(color);
    }

    /**
        Sets the source pattern for rendering
    */
    final
    void setSource(SbPattern pattern, vec2 offset=vec2(0)) {
        this.clearImageSource();
        this.setSourceImpl(pattern, offset);
    }

    /**
        Sets the source image for rendering

        This is a convenience function which automatically
        creates a SbImagePattern.

        The image will be locked until the source is changed.
        Setting the source to a null image will set the source
        to the default black color.
    */
    final
    void setSource(SbImage image, vec2 offset=vec2(0)) {
        this.clearImageSource();

        if (image) {
            
            // Set new image source through a pattern.
            imageSource = SbImagePattern.fromImage(image);
            this.setSourceImpl(imageSource, offset);
        } else {
            this.setSourceImpl(vec4(0, 0, 0, 1));
        }
    }

    /**
        Adds a clipping rectangle
    */
    void pushClipRect(recti area) {
        recti diff = area;

        if (clipRects.size() > 0) {
            recti lastClip = clipRects[$-1];
            
            diff.clip(lastClip);
        }

        clipRects ~= diff;
    }

    /**
        Pops clipping rectangle
    */
    void popClipRect() {
        clipRects.popBack();
    }

    /**
        Clears clipping rectangle
    */
    void clearClipRects() {
        clipRects.clear();
    }

    /**
        Gets the amount of clipping rectangles active
    */
    final
    uint getClipRectsActive() {
        return cast(uint)clipRects.size();
    }

    /**
        Returns a slice of active clipping rectangles

        This memory is owned by the context and should not be freed manually.
    */
    final
    recti[] getClipRects() {
        return clipRects[0..$];
    }

    /**
        Returns the current clipping area

        If no clipping is enabled, returns an infinitely big rectangle.
    */
    final
    recti getCurrentClip() {
        return clipRects.size > 0 ? clipRects[$-1] : recti(-1, -1, -1, -1);
    }

    /**
        Applies the specified effect to the specified area irrespective of clip rects
    */
    final
    void applyEffect(SbEffect effect, recti clip=recti(-1, -1, -1, -1)) {
        effect.apply(this, clip);
    }

    /**
        Applies the specified effect 
    */
    final
    void applyEffect(SbEffect effect) {
        if (getClipRectsActive() > 0) {
            effect.apply(this, getCurrentClip());
        } else {
            effect.apply(this, recti(0, 0, target.getWidth(), target.getHeight()));
        }
    }
}