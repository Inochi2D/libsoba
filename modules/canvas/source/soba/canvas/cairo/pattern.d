/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.cairo.pattern;
import soba.canvas.cairo;
import soba.canvas.pattern;
import soba.canvas.image;
import cairo;
import inmath.linalg;
import numem.all;

mixin template SbCairoPatternImpl() {
private:
    cairo_pattern_t* pattern;

public:

    // Destructor
    ~this() {
        cairo_pattern_destroy(pattern);
    }

    /**
        Gets the sampling mode
    */
    override
    SbPatternSampleMode getSampleMode() {
        final switch(cairo_pattern_get_extend(pattern)) {
            case cairo_extend_t.CAIRO_EXTEND_NONE: return SbPatternSampleMode.none;
            case cairo_extend_t.CAIRO_EXTEND_REPEAT: return SbPatternSampleMode.repeat;
            case cairo_extend_t.CAIRO_EXTEND_REFLECT: return SbPatternSampleMode.mirror;
            case cairo_extend_t.CAIRO_EXTEND_PAD: return SbPatternSampleMode.borderClamp;
        }
    }

    /**
        Sets the sampling mode
    */
    override
    void setSampleMode(SbPatternSampleMode mode) {
        final switch(mode) {
            case SbPatternSampleMode.none:          cairo_pattern_set_extend(pattern, cairo_extend_t.CAIRO_EXTEND_NONE); return;
            case SbPatternSampleMode.repeat:        cairo_pattern_set_extend(pattern, cairo_extend_t.CAIRO_EXTEND_REPEAT); return;
            case SbPatternSampleMode.mirror:        cairo_pattern_set_extend(pattern, cairo_extend_t.CAIRO_EXTEND_REFLECT); return;
            case SbPatternSampleMode.borderClamp:   cairo_pattern_set_extend(pattern, cairo_extend_t.CAIRO_EXTEND_PAD); return;
        }
    }

    /**
        Gets the filtering mode
    */
    override
    SbPatternFilter getFiltering() {
        final switch(cairo_pattern_get_filter(pattern)) {
            case cairo_filter_t.CAIRO_FILTER_FAST:
            case cairo_filter_t.CAIRO_FILTER_NEAREST:
                return SbPatternFilter.nearest;
            
            case cairo_filter_t.CAIRO_FILTER_GOOD:
            case cairo_filter_t.CAIRO_FILTER_BILINEAR:
                return SbPatternFilter.bilinear;

            case cairo_filter_t.CAIRO_FILTER_BEST:
            case cairo_filter_t.CAIRO_FILTER_GAUSSIAN:
                return SbPatternFilter.gaussian;
        }
    }

    /**
        Sets the filtering mode
    */
    override
    void setFiltering(SbPatternFilter filter) {
        final switch(filter) {
            case SbPatternFilter.nearest:   cairo_pattern_set_filter(pattern, cairo_filter_t.CAIRO_FILTER_NEAREST); return;
            case SbPatternFilter.bilinear:  cairo_pattern_set_filter(pattern, cairo_filter_t.CAIRO_FILTER_BILINEAR); return;
            case SbPatternFilter.gaussian:  cairo_pattern_set_filter(pattern, cairo_filter_t.CAIRO_FILTER_GAUSSIAN); return;
        }
    }

    /**
        Gets the dithering mode
    */
    override
    SbPatternDither getDither() {
        return SbPatternDither.none;
    }

    /**
        Sets the dithering mode
    */
    override
    void setDither(SbPatternDither filter) { }

    /**
        Gets the matrix
    */
    override
    mat3 getMatrix() {
        cairo_matrix_t mat;
        cairo_pattern_get_matrix(pattern, &mat);

        return mat3(
            mat.xx, mat.xy, mat.x0,
            mat.yx, mat.yy, mat.y0,
            0,      0,      1
        );
    }

    /**
        Sets the matrix
    */
    override
    void setMatrix(mat3 matrix) {

        cairo_matrix_t mat;
        cairo_matrix_init_identity (&mat);

        // Affine translation
        mat.x0 = -matrix[0][2];
        mat.y0 = -matrix[1][2];

        mat.xx = matrix[0][0];
        mat.xy = matrix[0][1];
        mat.yx = matrix[1][0];
        mat.yy = matrix[1][1];

        cairo_pattern_set_matrix(pattern, &mat);
    }

    /**
        Clears the pattern's matrix
    */
    override
    void clearMatrix() {
        cairo_matrix_t mat;
        cairo_matrix_init_identity(&mat);
        cairo_pattern_set_matrix(pattern, &mat);
    }

    /**
        Returns the backing handle
    */
    override
    void* getHandle() {
        return pattern;
    }
}

class SbCairoGradient : SbGradient {
@nogc:
private:
    mixin SbCairoPatternImpl;

public:
    this(SbGradientType type) {
        super(type);
    }

    static
    SbCairoGradient linearGradient(vec2 start, vec2 end) {
        SbCairoGradient grad = nogc_new!SbCairoGradient(SbGradientType.linear);
        grad.pattern = cairo_pattern_create_linear(start.x, start.y, end.x, end.y);
        return grad;
    }

    static
    SbCairoGradient radialGradient(vec2 inner, float innerRadius, vec2 outer, float outerRadius) {
        SbCairoGradient grad = nogc_new!SbCairoGradient(SbGradientType.linear);
        grad.pattern = cairo_pattern_create_radial(
            inner.x, 
            inner.y, 
            innerRadius, 
            outer.x, 
            outer.y, 
            outerRadius
        );
        return grad;
    }


    override
    void addStop(float offset, vec4 color) {
        cairo_pattern_add_color_stop_rgba(
            pattern, 
            offset,
            color.x,
            color.y,
            color.z,
            color.w
        );
    }


    override
    void addStop(float offset, vec3 color) {
        cairo_pattern_add_color_stop_rgb(
            pattern, 
            offset,
            color.x,
            color.y,
            color.z
        );
    }

    override
    uint getStopCount() {
        int stops;
        cairo_pattern_get_color_stop_count(pattern, &stops);
        return stops;
    }
}


class SbCairoImagePattern : SbImagePattern {
@nogc:
private:
    mixin SbCairoPatternImpl;
    cairo_surface_t* surface;

    void refresh() {
        ubyte[] source = this.getData();
        auto destination = cairo_image_surface_get_data(this.surface);

        // Copy to surface
        destination[0..source.length] = source[0..$];
        cairo_surface_mark_dirty(this.surface);
    }

public:

    ~this() {
        if (surface) {
            cairo_surface_destroy(surface);
        }
    }

    this(SbImage image) {
        super(image);

        this.surface = cairo_image_surface_create(
            this.getFormat().toCairoFormat(), 
            image.getWidth(), 
            image.getHeight()
        );
        this.refresh();

        this.pattern = cairo_pattern_create_for_surface(surface);
    }
}