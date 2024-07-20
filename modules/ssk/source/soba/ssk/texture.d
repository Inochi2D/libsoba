module soba.ssk.texture;

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
        RGB texture
    */
    RGB,

    /**
        ARGB texture
    */
    ARGB,
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

        // Discarded in this case.
        _ = width;
        _ = height;
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