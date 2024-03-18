module soba.core.window;
import soba.drawing.compositors;
import bindbc.sdl;
import numem.all;
import numem.mem.map;
import inmath;

public import bindbc.sdl : SDL_HitTestResult;

version(SbMetal) import metal;
else import bindbc.opengl;

private {
    extern(C) SDL_HitTestResult _SDL_HitTest_Impl(SDL_Window* win, const(SDL_Point)* area, void* data) nothrow {
        SbBackingWindow window = cast(SbBackingWindow)data;
        return window.HitTestFunc(window, vec2i(area.x, area.y));
    }
}

alias WindowHitTestFunc = SDL_HitTestResult function(SbBackingWindow window, vec2i point) nothrow @nogc;

/**
    The backing window for a logical Soba Window widget.
*/
class SbBackingWindow {
nothrow @nogc:
private:
    SDL_Window* window;
    WindowHitTestFunc HitTestFunc;
    SbCompositor compositor;

    // Metal specific implementation
    version(SbMetal) {
        import soba.drawing.compositors.metal : SbMetalCompositor;

        MTLDevice device;
        SDL_MetalView view;
        CAMetalLayer layer;

        void initWindowCtx() {
            view = SDL_Metal_CreateView(window);
            layer = cast(CAMetalLayer)SDL_Metal_GetLayer(view);

            device = MTLCreateSystemDefaultDevice();
            layer.device = device;

            auto fbSize = getFramebufferSize();
            compositor = nogc_new!SbMetalCompositor(this, cast(size_t)fbSize.x, cast(size_t)fbSize.y);
        }
        
        void uninitWindowCtx() {
            nogc_delete(compositor);
            device.release();
            layer.release();
            (cast(NSObject)view).release();

            layer = null;
            view = null;
            device = null;
            compositor = null;
        }

    // OpenGL specific implementation
    } else {
        SDL_GLContext ctx;
        
        void initWindowCtx() {
            ctx = SDL_GL_CreateContext(window);
        }
        
        void uninitWindowCtx() {
            SDL_GL_DeleteContext(ctx);
        }
    }
public:
    ~this() {
        SDL_SetWindowHitTest(window, null, null);
        uninitWindowCtx();
        SDL_DestroyWindow(window);
    }

    /**
        Constructs a new backing window
    */
    this(nstring title, int x, int y, int width, int height, uint flags) {
        version(SbMetal) {
            flags |= SDL_WINDOW_METAL;
        } else {
            flags |= SDL_WINDOW_OPENGL;
        }

        flags |= SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_HIDDEN;
        window = SDL_CreateWindow(title.toCString(), x, y, width, height, flags);

        this.initWindowCtx();
    }

    /**
        Sets the title of the window
    */
    void setTitle(nstring title) {
        SDL_SetWindowTitle(window, title.toCString());
    }

    /**
        Shows the window
    */
    void show() {
        SDL_ShowWindow(window);
    }

    /**
        Hides the window
    */
    void hide() {
        SDL_HideWindow(window);
    }

    /**
        Sets the hit testing function
    */
    void setHitTestFunc(WindowHitTestFunc func) {
        this.HitTestFunc = func;
        SDL_SetWindowHitTest(window, &_SDL_HitTest_Impl, cast(void*)this);
    }

    /**
        Makes the window's context current
    */
    void makeCurrent() {
        version(SbMetal) { }
        else SDL_GL_MakeCurrent(window, ctx);
    }

    /**
        Gets the size of the window
    */
    final
    vec2 getSize() {
        int w, h;
        SDL_GetWindowSize(window, &w, &h);
        return vec2(w, h);
    }

    /**
        Gets the compositor of the window
    */
    final
    SbCompositor getCompositor() {
        return compositor;
    }

    /**
        Gets the ID of the window
    */
    final
    uint getID() {
        return SDL_GetWindowID(window);
    }

    /**
        Sets the size of the window framebuffer
    */
    final
    void setFramebufferSize(float width, float height) {
        version(SbMetal) {
            layer.drawableSize.width = width;
            layer.drawableSize.height = height;
        }
    }

    /**
        Gets the size of the window framebuffer
    */
    final
    vec2 getFramebufferSize() {
        version(SbMetal) {
            int w, h;
            SDL_Metal_GetDrawableSize(window, &w, &h);
            return vec2(w, h);
        }
        return vec2(0, 0); // TODO: GL path
    }

    /**
        Gets the UI scale of the window
    */
    final
    vec2 getUIScale() {
        vec2 size = this.getSize();
        vec2 fbSize = this.getFramebufferSize();
        return vec2(fbSize.x/size.x, fbSize.y/size.y);
    }

    version(SbMetal) {
        /**
            Returns the underlying device
        */
        MTLDevice getDevice() {
            return device;
        }

        /**
            Returns the underlying layer
        */
        CAMetalLayer getLayer() {
            return layer;
        }
    }
}