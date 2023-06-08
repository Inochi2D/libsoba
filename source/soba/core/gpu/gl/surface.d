module soba.core.gpu.gl.surface;
import soba.core.gpu.gl;
import soba.core.gpu.surface;
import soba.core.gpu;
import bindbc.opengl;
import bindbc.sdl;


/**
    A surface for a window.
*/
class SbGLSurface : SbGPUSurface {
private:
    uint width_, height_;
    float dpiScaleX_, dpiScaleY_;

protected:
    SbGPUCreationTargetI target;
    SbGLContext context;

public:
    this(SbGPUContext context, SbGPUCreationTargetI target) {
        super(context, target);
        context = cast(SbGLContext)context;
        
        // Screen coordinate width/height
        uint swidth, sheight;
        SDL_GetWindowSize(target.getHandle(), cast(int*)&swidth, cast(int*)&sheight);

        // Gets size of window in pixels.
        SDL_GetWindowSizeInPixels(target.getHandle(), cast(int*)&width_, cast(int*)&height_);

        // Calculate DPI scale
        dpiScaleX_ = cast(float)width_/cast(float)swidth;
        dpiScaleY_ = cast(float)height_/cast(float)sheight;
    }

    /**
        Gets the width of the surface in pixels
    */
    override
    uint getWidthPx() { return width_; }
    
    /**
        Gets the Height of the surface in pixels
    */
    override
    uint getHeightPx() { return height_; }

    /**
        Gets the horizontal DPI scale of the surface
    */
    override
    float dpiScaleX() { return dpiScaleX_; }

    /**
        Gets the vertical DPI scale of the surface
    */
    override
    float dpiScaleY() { return dpiScaleY_; }

    /**
        Called when the surface should be resized
    */
    override
    void onResize(uint width, uint height) {
        width_ = width;
        height_ = height;

        context.makeCurrent();
        glViewport(0, 0, width_, height_);
    }

    /**
        Called when the surface starts being rendered to
    */
    override
    void onSurfaceBeginRender() {
        context.makeCurrent();
    }
    
    /**
        Called when the surface starts stops being rendered to
    */
    override
    void onSurfaceEndRender() {
        this.present();

        // TODO: Restore previous context
    }

    /**
        Rebuilds the swapchain

        NOOP in OpenGL    
    */
    override void rebuildSwapchain() { }

    /**
        Sets the swap interval
    */
    override
    void setSwapInterval(int swapinterval) {
        SDL_GL_SetSwapInterval(swapinterval);
    }

    /**
        Presents the surface
    */
    override
    void present() {
        SDL_GL_SwapWindow(target.getHandle());
    }
}