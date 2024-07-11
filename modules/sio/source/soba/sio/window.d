module soba.siok.window;
import numem.all;
import bindbc.sdl;
import inmath.linalg;

/**
    Window style
*/
enum SIOWindowStyle {
    /**
        A SIO window, a SIO window is always "borderless" by SDL2 standards,
        but additionally allows the onWindowHitTest event to be called.
    */
    sioWindow,

    /**
        System-native window.
        onWindowHitTest is never called for this window, and the OS draws the window chrome.
    */
    nativeWindow
}

/**
    The result of doing a hittest on a SIO Window
*/
enum SIOHitResult : int {
    /**
        Pass through mouse input to the window.
    */
	passthrough         = SDL_HITTEST_NORMAL,

    /**
        Drag the window
    */
	drag                = SDL_HITTEST_DRAGGABLE,

    /**
        Resize window from the top left
    */
	resizeTopLeft       = SDL_HITTEST_RESIZE_TOPLEFT,

    /**
        Resize window from the top
    */
	resizeTop           = SDL_HITTEST_RESIZE_TOP,
    
    /**
        Resize window from the top right
    */
	resizeTopRight      = SDL_HITTEST_RESIZE_TOPRIGHT,
    
    /**
        Resize window from the right
    */
	resizeRight         = SDL_HITTEST_RESIZE_RIGHT,
    
    /**
        Resize window from the bottom right
    */
	resizeBottomRight   = SDL_HITTEST_RESIZE_BOTTOMRIGHT,
    
    /**
        Resize window from the bottom
    */
	resizeBottom        = SDL_HITTEST_RESIZE_BOTTOM,
    
    /**
        Resize window from the bottom left
    */
	resizeBottomLeft    = SDL_HITTEST_RESIZE_BOTTOMLEFT,
    
    /**
        Resize window from the left
    */
	resizeLeft          = SDL_HITTEST_RESIZE_LEFT,
}

/**
    Tells SIO to center the window on open.
*/
enum uint SIOWindowCenter = SDL_WINDOWPOS_CENTERED;

/**
    Info needed to create a window
*/
struct SIOWindowCreateInfo {
    /**
        Information about the surface to be created on the window
    */
    SIOSurfaceCreateInfo surfaceInfo;

    /**
        Style of the window to be created.
    */
    SIOWindowStyle windowStyle = SIOWindowStyle.sioWindow;

    /**
        Title of the window
    */
    nstring title;

    /**
        X coordinate of the window
    */
    uint x = SIOWindowCenter;

    /**
        Y coordinate of the window
    */
    uint y = SIOWindowCenter;

    /**
        Width of the Window
    */
    uint width;

    /**
        Height of the Window
    */
    uint height;

    /**
        Whether the window is borderless
    */
    bool borderless = false;

    /**
        Whether the window is resizable
    */
    bool resizable = true;
}

/**
    The type of surface associated with the window
*/
enum SIOWindowSurfaceType {
    /// OpenGL
    GL,

    /// OpenGL ES
    GLES,

    /// Apple Metal
    metal,

    // TODO: Add software rendering?
}

/**
    Creation info for surfaces.
*/
struct SIOSurfaceCreateInfo {

    /**
        The type of surface to create
    */
    SIOWindowSurfaceType type;

    union {

        struct SIOSurfaceCreateInfoGL {
            uint major;
            uint minor;
        }

        /**
            Context creation info for OpenGL + GLES
        */
        SIOSurfaceCreateInfoGL gl;
    }
}

alias evOnWindowHitFunc = SIOHitResult function(SIOWindow window, vec2i mousePosition) nothrow;

/**
    A window
*/
class SIOWindow {
@nogc:
private:
    SDL_Window* handle;
    SIOWindowStyle wStyle;
    nstring title;
    bool _borderless;
    bool _resizable;

    // Surface
    SIOSurfaceCreateInfo surfaceInfo;
    void* surfaceHandle;

    SDL_WindowFlags setupWindowFlags(SIOWindowCreateInfo info) {

        SDL_WindowFlags flags;
        flags |= SDL_WINDOW_HIDDEN;

        if (info.borderless) flags |= SDL_WINDOW_BORDERLESS;
        if (info.resizable) flags |= SDL_WINDOW_RESIZABLE;
        version(OSX) flags |= SDL_WINDOW_ALLOW_HIGHDPI;

        // Attribute and flag setup
        final switch(info.surfaceInfo.type) {
            case SIOWindowSurfaceType.GL:
            case SIOWindowSurfaceType.GLES:
                flags |= SDL_WINDOW_OPENGL;

                SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, info.surfaceInfo.gl.major );
                SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, info.surfaceInfo.gl.minor );
                SDL_GL_SetAttribute(
                    SDL_GL_CONTEXT_PROFILE_MASK, 
                    info.surfaceInfo.type == SIOWindowSurfaceType.GL ? 
                        SDL_GL_CONTEXT_PROFILE_CORE :
                        SDL_GL_CONTEXT_PROFILE_ES
                );
                break;

            case SIOWindowSurfaceType.metal:
                flags |= SDL_WINDOW_METAL;
                break;
        }

        return flags;
    }

    bool setupSurface(SDL_Window* window, SIOWindowSurfaceType type) {
        final switch(type) {
            case SIOWindowSurfaceType.GL:
            case SIOWindowSurfaceType.GLES:
                surfaceHandle = cast(void*)SDL_GL_CreateContext(window);
                SDL_GL_MakeCurrent(window, cast(SDL_GLContext)surfaceHandle);
                return true;

            case SIOWindowSurfaceType.metal:
                surfaceHandle = SDL_Metal_CreateView(window);
                return true;
        }
    }

    void createWindow(SIOWindowCreateInfo info) {
        SDL_Window* window;

        SDL_WindowFlags flags = this.setupWindowFlags(info);

        handle = SDL_CreateWindow(title.toCString(), info.x, info.y, info.width, info.height, flags);
        enforce(handle !is null, nstring("Basic window creation failed!"));
        enforce(this.setupSurface(window, info.surfaceInfo.type), nstring("Rendering context creation failed!"));

        this.handle = window;
        this.title = info.title;
        this.wStyle = info.windowStyle;
        this.surfaceInfo = info.surfaceInfo;
    }

    // Events
    evOnWindowHitFunc evOnWindowHit;
public:

    ~this() {

        // Destroy metal handle if need be
        if (surfaceInfo.type == SIOWindowSurfaceType.metal) {
            SDL_Metal_DestroyView(cast(SDL_MetalView)surfaceHandle);
        }

        // Destroy window
        SDL_DestroyWindow(handle);
    }

    /**
        Creates a window
    */
    this(SIOWindowCreateInfo windowInfo) {
        this.createWindow(windowInfo);
    }

    /**
        Gets the underlying window handle
    */
    final
    SDL_Window* getHandle() {
        return handle;
    }

    /**
        Gets the native window handle.

        Returns one of the following:
            * X11 window ID
            * Wayland surface
            * Win32 HWND handle
            * Cocoa window handle
        Returns null if the native window handle isn't obtainable.
    */
    final
    void* getNativeHandle() {
        SDL_SysWMinfo info;
        if (SDL_GetWindowWMInfo(handle, &info)) {
            switch(info.subsystem) {
                version(linux) {
                    case SDL_SYSWM_X11:
                        return cast(void*)info.info.x11.window;
                    case SDL_SYSWM_WAYLAND:
                        return cast(void*)info.info.wl.surface;
                }

                version(Windows) {
                    case SDL_SYSWM_WINDOWS:
                        return cast(void*)info.info.win.window;
                }

                version(OSX) {
                    case SDL_SYSWM_COCOA:
                        return cast(void*)info.info.cocoa.window;
                }
                default: return null;
            }
        }

        return null;
    }

    /**
        Gets the type of surface created
    */
    final
    SIOWindowSurfaceType getSurfaceType() {
        return surfaceInfo.type;
    }

    /**
        Gets the handle of the surface
    */
    final
    void* getSurfaceHandle() {
        return surfaceHandle;
    }

    /**
        Gets the title of the window
    */
    final
    nstring getTitle() {
        return title;
    }

    /**
        Sets the title of the window
    */
    final
    void setTitle(nstring newTitle) {
        this.title = newTitle;
        SDL_SetWindowTitle(handle, newTitle.toCString());
    }

    /**
        Gets whether the window is borderless
    */
    final
    bool getBorderless() {
        return _borderless;
    }

    /**
        Gets whether the window is resizable
    */
    final
    bool getResizable() {
        return _resizable;
    }

    /**
        Maximizes the window
    */
    final
    void maximize() {
        SDL_MaximizeWindow(handle);
    }

    /**
        Maximizes the window
    */
    final
    void minimize() {
        SDL_MinimizeWindow(handle);
    }

    /**
        Restores the window
    */
    final
    void restore() {
        SDL_RestoreWindow(handle);
    }

    /**
        Shows the window
    */
    final
    void show() {
        SDL_ShowWindow(handle);
    }

    /**
        Hides the window
    */
    final
    void hide() {
        SDL_HideWindow(handle);
    }

    /**
        Raises the window and forces input focus on it.
    */
    final
    void focus() {
        SDL_RaiseWindow(handle);
    }

    /**
        Make this window a modal window for another
    */
    final
    void setModalFor(SIOWindow other) {
        SDL_SetWindowModalFor(handle, other ? other.handle : null);
    }

    /**
        Set a function called when a window hit test is requested.
        Only is called for SIO windows.

        NOTE: The window hit event may not throw exceptions.
    */
    final
    void setOnWindowHitTest(evOnWindowHitFunc func) {
        if (wStyle == SIOWindowStyle.sioWindow) {
            this.evOnWindowHit = func;
            SDL_SetWindowHitTest(handle, func ? &_SDL_HitTest_Impl : null, cast(void*)this);
        }
    }
}

//
//              PRIVATE CALLBACK DELEGATION
//
private {
    extern(C) SDL_HitTestResult _SDL_HitTest_Impl(SDL_Window* win, const(SDL_Point)* area, void* data) nothrow {
        SIOWindow window = cast(SIOWindow)data;
        return window.evOnWindowHit(window, vec2i(area.x, area.y));
    }
}