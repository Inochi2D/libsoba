module soba.drawing.cairo;
import soba.drawing;
import cairo;
import std.math;
import numem.all;

class SbCairoContext : SbDrawingContext {
nothrow @nogc:
private:
    cairo_t* cairo;
    cairo_surface_t* surface;
    cairo_pattern_t* pattern;

    float brTL, brTR, brBL, brBR;

public:
    this(size_t width, size_t height) {
        super(width, height);
        surface = cairo_image_surface_create(cairo_format_t.CAIRO_FORMAT_RGB24, cast(int)width, cast(int)height);
        cairo = cairo_create(surface);

        this.dst = cairo_image_surface_get_data(surface);
    }

    override
    void resize(size_t width, size_t height) {
        int oldWidth = cast(int)this.width;
        int oldHeight = cast(int)this.height;
        super.resize(width, height);

        cairo_surface_t* newSurface = cairo_image_surface_create(cairo_format_t.CAIRO_FORMAT_RGB24, cast(int)width, cast(int)height);
        cairo_t* newCairo = cairo_create(newSurface);

        cairo_set_source_surface(newCairo, surface, 0, 0);
        cairo_rectangle(newCairo, 0, 0, oldWidth, oldHeight);
        cairo_fill(newCairo);

        cairo_destroy(cairo);
        cairo_surface_destroy(surface);

        cairo = newCairo;
        surface = newSurface;

        cairo_surface_set_device_scale(surface, this.scale, this.scale);
        this.dst = cairo_image_surface_get_data(surface);
    }

    override
    void setScale(float scale) {
        super.setScale(scale);
        cairo_surface_set_device_scale(surface, scale, scale);
    }

    override
    void rectangle(float x, float y, float width, float height) {
        cairo_rectangle(cairo, x, y, width, height);   
    }

    override
    void rectangleRounded(float x, float y, float width, float height) {
        double degrees = PI / 180.0;

        cairo_new_sub_path (cairo);
        cairo_arc (cairo, x + width - brTL, y + brTL, brTL, -90 * degrees, 0 * degrees);
        cairo_arc (cairo, x + width - brTR, y + height - brTR, brTR, 0 * degrees, 90 * degrees);
        cairo_arc (cairo, x + brBL, y + height - brBL, brBL, 90 * degrees, 180 * degrees);
        cairo_arc (cairo, x + brBR, y + brBR, brBR, 180 * degrees, 270 * degrees);
        cairo_close_path (cairo);
    }

    override
    void setBorderRadius(float topLeft, float topRight, float bottomLeft, float bottomRight) {
        this.brTL = topLeft;
        this.brTR = topRight;
        this.brBL = bottomLeft;
        this.brBR = bottomRight;
    }

    override
    void setColor(float r, float g, float b, float a) {
        cairo_set_source_rgba(cairo, r, g, b, a);
    }

    override
    void setGradientLinear(float[4][] stops, float x0, float y0, float x1, float y1) {
        
        // Handle refcount
        if (pattern) {
            cairo_pattern_destroy(pattern);
            pattern = null;
        }

        pattern = cairo_pattern_create_linear(x0, y0, x1, y1);
        foreach(i, stop; stops) {
            float stopIdx = cast(float)i/cast(float)(stops.length-1);
            cairo_pattern_add_color_stop_rgba(pattern, stopIdx, stop[0], stop[1], stop[2], stop[3]);
        }

        cairo_set_source(cairo, pattern);
    }

    override
    void setGradientRadial(float[4][] stops, float x, float y, float radius) {
        
        // Handle refcount
        if (pattern) {
            cairo_pattern_destroy(pattern);
            pattern = null;
        }

        pattern = cairo_pattern_create_radial(x, y, 0, x, y, radius);
        foreach(i, stop; stops) {
            float stopIdx = cast(float)i/cast(float)(stops.length-1);
            cairo_pattern_add_color_stop_rgba(pattern, stopIdx, stop[0], stop[1], stop[2], stop[3]);
        }

        cairo_set_source(cairo, pattern);
    }

    override
    void setStrokeWidth(float width) {
        cairo_set_line_width(cairo, width);
    }

    override
    void setLineCap(SbLineCap cap) {
        
    }

    override
    void setLineJoin(SbLineJoin join) {
        
    }

    override
    void setFontSize(float size) {
        cairo_set_font_size(cairo, size);
    }

    override
    void drawText(nstring text, float x, float y) {
        cairo_move_to(cairo, x, y);
        cairo_show_text(cairo, text.toCString());
    }

    override
    void startPath(float x, float y) {
        cairo_new_sub_path(cairo);
    }

    override
    void closePath() {
        cairo_close_path(cairo);
    }

    override
    void stroke() {
        cairo_stroke(cairo);
    }

    override
    void fill() {
        cairo_fill(cairo);
    }

    override
    void strokePreserve() {
        cairo_stroke_preserve(cairo);
    }

    override
    void fillPreserve() {
        cairo_fill_preserve(cairo);
    }

    override
    void saveToPNG(nstring path) {
        cairo_surface_write_to_png(surface, path.toCString());
    }
}
