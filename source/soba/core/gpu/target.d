module soba.core.gpu.target;

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
}