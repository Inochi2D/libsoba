module soba.core.gpu.target;

/**
    The type of the target
*/
enum SbGPURenderTargetType {
    Framebuffer,
    Surface
}

/**
    A render target
*/
abstract class SbGPURenderTarget {
public:

    /**
        Gets the render targets width in pixels
    */
    abstract uint getWidthPx();
    
    /**
        Gets the render targets height in pixels
    */
    abstract uint getHeightPx();

    /**
        Gets the type of the render target
    */
    abstract SbGPURenderTargetType getType();

    /**
        Whether the render target has a depth and stencil texture
    */
    abstract bool hasDepthStencil();
}