/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.cairo.image;
import soba.canvas.image;
import numem.all;
import cairo;

class SbCairoImage : SbImage {
nothrow @nogc:
private:
    cairo_pattern_t pattern;

    cairo_content_t getCairoContentType() {
        if (this.getAlignment() == 1)
            return cairo_content_t.CAIRO_CONTENT_ALPHA;
        else if (this.getChannels() <= 3)
            return cairo_content_t.CAIRO_CONTENT_COLOR;
        return cairo_content_t.CAIRO_CONTENT_COLOR_ALPHA;
    }

    cairo_format_t getCairoFormatType() {
        final switch(this.getFormat()) {
            case SbImageFormat.None:    return cairo_format_t.CAIRO_FORMAT_INVALID;
            case SbImageFormat.A8:      return cairo_format_t.CAIRO_FORMAT_A8;
            case SbImageFormat.RGB:     return cairo_format_t.CAIRO_FORMAT_RGB24;
            case SbImageFormat.RGBA:    return cairo_format_t.CAIRO_FORMAT_ARGB32;
        }
    }

protected:

    override
    uint getAlignmentForChannels(uint channels) {
        if (channels <= 1)
            return channels;
        return 4;
    }

public:

    this(uint width, uint height, uint channels) {
        super(width, height, channels);
        pattern = cairo_pattern_create_raster_source(this, this.getCairoContentType(), width, height);
    }

    this(nstring file) {
        super(file);
        pattern = cairo_pattern_create_raster_source(this, this.getCairoContentType(), width, height);
    }

    override
    void* getHandle() {
        return pattern;
    }
}


private:
    
extern(C)
cairo_surface_t* cairo_img_acq_func_impl(cairo_pattern_t* pattern, void* callback_data, cairo_surface_t* target, const(cairo_rectangle_int_t)* extents) {
    SbCairoImage cimg = cast(SbCairoImage)callback_data;
    cairo_surface_t* surface = cairo_surface_create_similar_image(target, cimg.getCairoFormatType(), cimg.getWidth(), cimg.getHeight());
    auto data = cairo_image_surface_get_data(surface);
    cairo_surface_set_device_offset(surface, extents.x, extents.y);

    // TODO: write pixel data
}

extern(C)
void cairo_img_rel_func_impl(cairo_pattern_t* pattern, void* callback_data, cairo_surface_t* surface) {
    cairo_surface_destroy(surface);
}