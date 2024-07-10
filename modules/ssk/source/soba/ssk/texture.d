module soba.ssk.texture;
import soba.ssk.ctx;
import numem.all;
import inmath.linalg;

enum SSKTextureFormat {
    /**
        32-bit RGBA texture
    */
    rgba32,

    /**
        32-bit ARGB texture

        Also known as BGRA
    */
    argb32,

    /**
        32-bit RGB texture, alpha channel is ignored
    */
    rgb32,

    /**
        8-bit Red-only channel
    */
    r8,
}

/**
    A texture
*/
abstract
class SSKTexture {
@nogc:
private:
    SSKContext ctx;
    SSKTextureFormat fmt;

protected:
    /**
        Width of the texture
    */
    uint width;

    /**
        Height of the texture
    */
    uint height;

public:

    this(SSKContext ctx, SSKTextureFormat fmt, uint width, uint height) {
        this.ctx = ctx;
        this.fmt = fmt;
        this.width = width;
        this.height = height;
    }

    /**
        Gets the context this texture belongs to
    */
    final
    SSKContext getContext() {
        return ctx;
    }

    /**
        Gets the format of the texture
    */
    final
    SSKTextureFormat getFormat() {
        return fmt;
    }

    /**
        Gets the width of the texture
    */
    final
    uint getWidth() {
        return width;
    }

    /**
        Gets the height of the texture
    */
    final
    uint getHeight() {
        return height;
    }

    /**
        Gets the underlying texture handle
    */
    abstract void* getHandle();

    /**
        Resizes the texture
    */
    abstract void resize(uint width, uint height);

    /**
        Blits texture data on to the texture
    */
    abstract void blit(ubyte* data, SSKTextureFormat fmt, uint width, uint height, uint stride);
}