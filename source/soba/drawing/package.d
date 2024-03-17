module soba.drawing;
import cairo;
import numem.all;

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

abstract
class SbDrawingContext {
nothrow @nogc:
protected:
    ubyte* dst;
    size_t width;
    size_t height;
    float scale;

public:

    /**
        Instantiates the buffer
    */
    this(size_t width, size_t height) {
        this.width = width;
        this.height = height;
        this.scale = 1;
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
    abstract void setGradientLinear(float[4][] stops, float x0, float y0, float x1, float y1);

    /**
        Sets a radial gradient as the current rendering style
    */
    abstract void setGradientRadial(float[4][] stops, float x, float y, float radius);

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
        Strokes the path without removing it
    */
    abstract void strokePreserve();

    /**
        Fills the path without removing it
    */
    abstract void fillPreserve();

    /**
        Draws a string of text
    */
    abstract void drawText(nstring text, float x, float y);

    /**
        Saves the content of the drawing context to a PNG
    */
    abstract void saveToPNG(nstring path);
}