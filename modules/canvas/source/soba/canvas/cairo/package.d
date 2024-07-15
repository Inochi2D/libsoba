/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Internal cairo implementation for soba vector
*/
module soba.canvas.cairo;
import cairo;
import soba.canvas.image;

@nogc:

/**
    Converts the soba image format to cairo format.
*/
cairo_format_t toCairoFormat(SbImageFormat fmt) {
    final switch(fmt) {
        case SbImageFormat.None:      return cairo_format_t.CAIRO_FORMAT_INVALID;
        case SbImageFormat.A8:        return cairo_format_t.CAIRO_FORMAT_A8;
        case SbImageFormat.RGB32:     return cairo_format_t.CAIRO_FORMAT_RGB24;
        case SbImageFormat.RGBA32:    return cairo_format_t.CAIRO_FORMAT_ARGB32;
    }
}