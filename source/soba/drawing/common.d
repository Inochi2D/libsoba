module soba.drawing.common;
import inmath;

public import soba.core.math;

/**
    Texture format for surface and drawing context creation
*/
enum SbSurfaceFormat {
    /**
        24 bit RGB data, aligned to 32 bits.

        Upper 8 bits are unused.
    */
    RGB,

    /**
        32 bit ARGB data, aligned to 32 bits.
    */
    ARGB,

    /**
        HDR compatible RGB data
    */
    RGB_HDR,

    /**
        HDR compatible ARGB data
    */
    ARGB_HDR
}