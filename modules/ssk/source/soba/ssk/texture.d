module soba.ssk.texture;
import soba.canvas.image;

@nogc:

enum SskTextureKind {
    /**
        Texture is an image updated from the CPU.
    */
    image,
    
    /**
        Texture is a framebuffer rendered to by the GPU.
    */
    framebuffer
}

enum SskTextureFormat {
    /**
        No or invalid texture format
    */
    None,

    /**
        RGB texture
    */
    RGB,

    /**
        BGRA texture
    */
    BGRA,
}

SskTextureFormat fromImageFormat(SbImageFormat fmt) {
    switch(fmt) {
        default: return SskTextureFormat.None;
        case SbImageFormat.RGB32:
            return SskTextureFormat.RGB;
        case SbImageFormat.RGBA32:
            return SskTextureFormat.BGRA;
    }
}

/**
    Reference to underlying texture
*/
alias SskTextureRef = void*;

/**
    A texture
*/
abstract
class SskTexture {
@nogc:
private:
    SskTextureKind kind;
    SskTextureFormat format;

public:
    this(SskTextureFormat format, SskTextureKind kind, uint width, uint height) {
        this.kind = kind;
        this.format = format;
    }

    /**
        Gets the render-api specific handle
    */
    abstract SskTextureRef getHandle();

    /**
        Resizes the texture
    */
    abstract void resize(uint width, uint height);

    /**
        Gets the width of the texture
    */
    abstract uint getWidth();

    /**
        Gets the height of the texture
    */
    abstract uint getHeight();

    /**
        Gets the format of the texture
    */
    final
    SskTextureFormat getFormat() {
        return format;
    }

    /**
        Gets the kind of texture
    */
    final
    SskTextureKind getKind() {
        return kind;
    }

    /**
        Upload texture data

        Only available on image textures.
    */
    abstract void upload(SskTextureFormat format, ubyte[] data, uint width, uint height);
}