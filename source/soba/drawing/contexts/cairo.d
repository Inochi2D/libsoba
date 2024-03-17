module soba.drawing.contexts.cairo;
import soba.drawing.contexts;
import soba.drawing.common;
import cairo;
import std.math;
import numem.all;
import inmath;

class SbCairoContext : SbDrawingContext {
nothrow @nogc:
private:
    cairo_t* cairo;
    cairo_surface_t* surface;
    cairo_pattern_t* pattern;

    float brTL, brTR, brBL, brBR;

    final cairo_format_t toCairoSurfaceFormat() {
        final switch(format) {
            case SbSurfaceFormat.ARGB:
            case SbSurfaceFormat.ARGB_HDR:
                return cairo_format_t.CAIRO_FORMAT_ARGB32;
            case SbSurfaceFormat.RGB:
            case SbSurfaceFormat.RGB_HDR:
                return cairo_format_t.CAIRO_FORMAT_RGB24;
        }
    }

public:
    ~this() {
        cairo_destroy(cairo);
        cairo_surface_destroy(surface);

        if (pattern)
            cairo_pattern_destroy(pattern);
    }

    this(SbSurfaceFormat format, size_t width, size_t height) {
        super(format, width, height);
        surface = cairo_image_surface_create(toCairoSurfaceFormat(), cast(int)width, cast(int)height);
        cairo = cairo_create(surface);

        this.dst = cairo_image_surface_get_data(surface);
    }

    override
    void resize(size_t width, size_t height) {
        int oldWidth = cast(int)this.width;
        int oldHeight = cast(int)this.height;
        super.resize(width, height);

        cairo_surface_t* newSurface = cairo_image_surface_create(toCairoSurfaceFormat(), cast(int)width, cast(int)height);
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
    size_t getStride() {
        return cairo_format_stride_for_width(toCairoSurfaceFormat(), cast(int)width);
    }

    override
    ubyte* getBufferHandle() {
        cairo_surface_flush(surface);
        return super.getBufferHandle();
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
    void setGradientLinear(SbGradientStop[] stops, float x0, float y0, float x1, float y1) {
        
        // Handle refcount
        if (pattern) {
            cairo_pattern_destroy(pattern);
            pattern = null;
        }

        pattern = cairo_pattern_create_linear(x0, y0, x1, y1);
        foreach(i, ref stop; stops) {
            cairo_pattern_add_color_stop_rgba(pattern, stop.stop, stop.color.x, stop.color.y, stop.color.z, stop.color.w);
        }

        cairo_set_source(cairo, pattern);
    }

    override
    void setGradientRadial(SbGradientStop[] stops, float x, float y, float radius) {
        
        // Handle refcount
        if (pattern) {
            cairo_pattern_destroy(pattern);
            pattern = null;
        }

        pattern = cairo_pattern_create_radial(x, y, 0, x, y, radius);
        foreach(i, ref stop; stops) {
            cairo_pattern_add_color_stop_rgba(pattern, stop.stop, stop.color.x, stop.color.y, stop.color.z, stop.color.w);
        }

        cairo_set_source(cairo, pattern);
    }

    override
    void setStrokeWidth(float width) {
        cairo_set_line_width(cairo, width);
    }

    override
    void setLineCap(SbLineCap cap) {
        cairo_line_cap_t ccap;
        final switch(cap) {
            case SbLineCap.Butt:
                ccap = cairo_line_cap_t.CAIRO_LINE_CAP_BUTT;
                break;
            case SbLineCap.Round:
                ccap = cairo_line_cap_t.CAIRO_LINE_CAP_ROUND;
                break;
            case SbLineCap.Square:
                ccap = cairo_line_cap_t.CAIRO_LINE_CAP_SQUARE;
                break;
        }
        cairo_set_line_cap(cairo, ccap);
    }

    override
    void setLineJoin(SbLineJoin join) {
        cairo_line_join_t cjoin;
        final switch(join) {
            case SbLineJoin.Bevel:
                cjoin = cairo_line_join_t.CAIRO_LINE_JOIN_BEVEL;
                break;
            case SbLineJoin.Round:
                cjoin = cairo_line_join_t.CAIRO_LINE_JOIN_MITER;
                break;
            case SbLineJoin.Miter:
                cjoin = cairo_line_join_t.CAIRO_LINE_JOIN_ROUND;
                break;
        }
        cairo_set_line_join(cairo, cjoin);
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
    void measureText(nstring text, out float w, out float h) {
        cairo_text_extents_t extents;
        cairo_text_extents(cairo, text.toCString(), &extents);

        w = extents.width;
        h = extents.height;
    }

    override
    void startPath(float x, float y) {
        cairo_move_to(cairo, x, y);
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
    void clipRectangle(float x, float y, float width, float height) {
        this.rectangle(x, y, width, height);
        this.clip();
    }

    override
    void clip() {
        cairo_clip(cairo);
    }

    override
    void clipPreserve() {
        cairo_clip_preserve(cairo);
    }

    override
    void resetClip() {
        cairo_reset_clip(cairo);
    }

    override
    void save() {
        cairo_save(cairo);
    }

    override
    void restore() {
        cairo_restore(cairo);
    }

    override
    void saveToPNG(nstring path) {
        cairo_surface_write_to_png(surface, path.toCString());
    }
}
