/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Textures
*/
module soba.core.gpu.texture;

import imagefmt;
import soba.core.gpu.target;

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

    /**
        Gets the texture width in pixels
    */
    abstract uint getWidthPx();
    
    /**
        Gets the texture height in pixels
    */
    abstract uint getHeightPx();
    
    /**
        Sets the texture sub-data
    */
    abstract void setSubData(ref IFImage data, int x, int y, int width, int height);

    /**
        Sets the texture data
    */
    abstract void setData(ref IFImage data);

    /**
        Sets the wrapping mode of the texture
    */
    abstract SbGPUTexture setWrapping(SbGPUTextureWrapMode u, SbGPUTextureWrapMode v);

    /**
        Sets the anisotropy level
    */
    abstract SbGPUTexture setAnisotropy(ushort anisotropy=1);

    /**
        Sets the minifcation filter
    */
    abstract SbGPUTexture setMinFilter(SbGPUTextureFilter filter);

    /**
        Sets the magnification filter
    */
    abstract SbGPUTexture setMagFilter(SbGPUTextureFilter filter);
    
    /**
        Returns the format of this texture
    */
    abstract SbGPUTextureFormat getFormat();

    /**
        Gets a render target from the texture
    */
    abstract SbGPURenderTarget toRenderTarget();
}