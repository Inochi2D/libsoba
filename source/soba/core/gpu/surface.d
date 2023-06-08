/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Window Surfaces
*/
module soba.core.gpu.surface;
import soba.core.gpu;
import bindbc.sdl;

/**
    A surface for a window.
*/
abstract class SbGPUSurface {
protected:
    SbGPUCreationTargetI target;

    this(SbGPUContext context, SbGPUCreationTargetI target) {
        this.target = target;
    }
    
public:

    /**
        Gets the width of the surface in pixels
    */
    abstract uint getWidthPx();
    
    /**
        Gets the Height of the surface in pixels
    */
    abstract uint getHeightPx();

    /**
        Gets the horizontal DPI scale of the surface
    */
    abstract float dpiScaleX();

    /**
        Gets the vertical DPI scale of the surface
    */
    abstract float dpiScaleY();

    /**
        Called when the surface should be resized
    */
    abstract void onResize(uint width, uint height);

    /**
        Called when the surface starts being rendered to
    */
    abstract void onSurfaceBeginRender();
    
    /**
        Called when the surface starts stops being rendered to
    */
    abstract void onSurfaceEndRender();

    /**
        Rebuilds the swapchain
    */
    abstract void rebuildSwapchain();
    
    /**
        Sets the swap interval
    */
    abstract void setSwapInterval(int swapinterval);
    
    /**
        Presents the surface
    */
    abstract void present();
}