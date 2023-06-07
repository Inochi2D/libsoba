/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Textures
*/
module soba.core.gpu.texture;

import imagefmt;

enum SbGPUTextureWrapMode {
    Repeat,
    MirroredRepeat,
    ClampToEdge
}

enum SbGPUTextureFilter {

    /**
        Nearest Neighbour filtering
    */
    Nearest = 0x0000000,

    /**
        Linear filtering
    */
    Linear = 0x00000001,

    /**
        Linear filtering
    */
    Mipmapped = 0x00000002,
}

/**
    Texture formats supported by soba
*/
enum SbGPUTextureFormat {

    /**
        Red
    */
    Red,

    /**
        Red and Green
    */
    RG,

    /**
        (Will be auto converted to RGBA from RGB)
    */
    RGB,

    /**
        8-bit unsigned RGBA
    */
    RGBA
}

/**
    A 2D texture
*/
abstract class SbGPUTexture {
public:
    abstract uint getWidthPx();
    abstract uint getHeightPx();
    abstract void setSubData(ref IFImage data, int x, int y, int width, int height);
    abstract void setData(ref IFImage data);
}