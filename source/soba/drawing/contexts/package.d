module soba.drawing.contexts;
import soba.drawing.surfaces;
import soba.drawing.common;
import cairo;
import numem.all;
import inmath;

enum SbLineCap {
    Square,
    Round,
    Butt
}

enum SbLineJoin {
    Miter,
    Bevel,
    Round
}

struct SbGradientStop {
    float stop;
    vec4 color;
}

/**
    A context used for drawing on to a surface
*/
abstract
class SbDrawingContext {
nothrow @nogc:
protected:
    ubyte* dst;
    size_t width;
    size_t height;
    float scale;
    SbSurfaceFormat format;
    SbSurface target;

public:

    /**
        Instantiates the buffer
    */
    this(SbSurfaceFormat format, size_t width, size_t height) {
        this.format = format;
        this.width = width;
        this.height = height;
        this.scale = 1;
    }

    /**
        Sets the target to be rendered to
    */
    void setTarget(SbSurface target) {

        // If we have a target already, decouple from it
        if (this.target) 
            this.target.aquire(null);
        
        // Then apply our new target
        this.target = target;
        if (target) {
            target.aquire(this);
            this.resize(target.getWidth(), target.getHeight());
        }
    }

    /**
        Resizes the canvas of the drawing context
    */
    void resize(size_t width, size_t height) {
        this.width = width;
        this.height = height;
    }

    /**
        Sets the rendering scale
    */
    void setScale(float scale) {
        this.scale = scale;
    }

    /**
        Gets the width of the drawing context canvas.
    */
    size_t getWidth() {
        return width;
    }

    /**
        Gets the width of the drawing context canvas.
    */
    size_t getHeight() {
        return height;
    }

    /**
        Gets a handle to the color buffer
    */
    ubyte* getBufferHandle() {
        return dst;
    }

    /**
        Gets the stride of the underlying buffer
    */
    abstract size_t getStride();

    /**
        Draws a rectangle path
    */
    abstract void rectangle(float x, float y, float width, float height);

    /**
        Draws a rounded rectangle path
    */
    abstract void rectangleRounded(float x, float y, float width, float height);

    /**
        Sets the border radius of a rounded rectangle
    */
    abstract void setBorderRadius(float topLeft, float topRight, float bottomLeft, float bottomRight);

    /**
        Sets a solid color as the current rendering style
    */
    abstract void setColor(float r, float g, float b, float a);

    /**
        Sets a linear gradient as the current rendering style
    */
    abstract void setGradientLinear(SbGradientStop[] stops, float x0, float y0, float x1, float y1);

    /**
        Sets a radial gradient as the current rendering style
    */
    abstract void setGradientRadial(SbGradientStop[] stops, float x, float y, float radius);

    /**
        Sets the width of a stroke
    */
    abstract void setStrokeWidth(float width);

    /**
        Sets the stroke line cap style
    */
    abstract void setLineCap(SbLineCap cap);

    /**
        Sets the stroke line join cap style
    */
    abstract void setLineJoin(SbLineJoin join);

    /**
        Sets the font size
    */
    abstract void setFontSize(float size);

    /**
        Starts a path at the specified location
    */
    abstract void startPath(float x, float y);

    /**
        Closes the specified path
    */
    abstract void closePath();

    /**
        Strokes the path
    */
    abstract void stroke();

    /**
        Fills the path
    */
    abstract void fill();

    /**
        Clips with the current shape
    */
    abstract void clip();

    /**
        Strokes the path without removing it
    */
    abstract void strokePreserve();

    /**
        Fills the path without removing it
    */
    abstract void fillPreserve();

    /**
        Clips with the current path without removing it
    */
    abstract void clipPreserve();

    /**
        Draws a string of text
    */
    abstract void drawText(nstring text, float x, float y);

    /**
        Measures a string of text
    */
    abstract void measureText(nstring text, out float w, out float h);

    /**
        Sets clip rectangle
    */
    abstract void clipRectangle(float x, float y, float width, float height);

    /**
        Resets the clipping state
    */
    abstract void resetClip();

    /**
        Saves the current state
    */
    abstract void save();

    /**
        Restores state from a saved state
    */
    abstract void restore();

    /**
        Flushes the contents to the target (if possible)
    */
    abstract bool flush();

    /**
        Flushes the contents to the target (if possible)
    */
    abstract bool flush(recti src);

    /**
        Saves the content of the drawing context to a PNG
    */
    abstract void saveToPNG(nstring path);
}

nothrow @nogc:

/**
    Creates a new drawing context as a shared pointer
*/
shared_ptr!SbDrawingContext createContext(SbSurfaceFormat format, size_t width, size_t height) {
    import soba.drawing.contexts.cairo : SbCairoContext;
    return shared_ptr!SbDrawingContext.fromPtr(nogc_new!SbCairoContext(format, width, height));
}