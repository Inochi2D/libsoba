/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Internal blend2d implementation for soba vector
*/
module soba.canvas.blend2d;
import blend2d;
import soba.canvas.image;

@nogc:

/**
    Converts the soba image format to Blend2D format.
*/
BLFormat toBLFormat(SbImageFormat fmt) {
    final switch(fmt) {
        case SbImageFormat.A8:      return BLFormat.BL_FORMAT_A8;
        case SbImageFormat.RGB32:   return BLFormat.BL_FORMAT_XRGB32;
        case SbImageFormat.RGBA32:  return BLFormat.BL_FORMAT_PRGB32;
        case SbImageFormat.None:    return BLFormat.BL_FORMAT_NONE;
    }
}