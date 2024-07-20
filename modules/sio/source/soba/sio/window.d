/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.sio.window;
import numem.all;
import bindbc.sdl;
import inmath.linalg;

import soba.sio.events;

/**
    Window style
*/
enum SioWindowStyle {
    /**
        A SIO window, a SIO window is always "borderless" by SDL2 standards,
        but additionally allows the onWindowHitTest event to be called.
    */
    sioWindow,

    /**
        System-native window.
        onWindowHitTest is never called for this window, and the OS draws the window chrome.
    */
    nativeWindow,

    /**
        Window should be treated as a utility window
    */
    utilityWindow,
    
    /**
        Window should be treated as a popup window
    */
    popupWindow,
    
    /**
        Window should be treated as a tooltip
    */
    tooltipWindow
}

/**
    The result of doing a hittest on a SIO Window
*/
enum SioHitResult : int {
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
    A window ID
*/
alias SioWindowID = uint;

/**
    A window ID indicating events should be passed to all windows.
*/
enum SioWindowID SioWindowAll = uint.max;

/**
    A special window ID, this window does not exist, but allows events to be
    handled app-wide.
*/
enum SioWindowID SioWindowGlobal = uint.max-1;

/**
    Tells SIO to center the window on open.
*/
enum uint SioWindowCenter = SDL_WINDOWPOS_CENTERED;

/**
    Info needed to create a window
*/
struct SioWindowCreateInfo {
    /**
        Information about the surface to be created on the window
    */
    SioSurfaceCreateInfo surfaceInfo;

    /**
        Style of the window to be created.
    */
    SioWindowStyle windowStyle = SioWindowStyle.sioWindow;

    /**
        Title of the window
    */
    nstring title;

    /**
        X coordinate of the window
    */
    uint x = SioWindowCenter;

    /**
        Y coordinate of the window
    */
    uint y = SioWindowCenter;

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
enum SioWindowSurfaceType {
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
struct SioSurfaceCreateInfo {

    /**
        The type of surface to create
    */
    SioWindowSurfaceType type;

    union {

        struct SioSurfaceCreateInfoGL {
            uint major;
            uint minor;
        }

        /**
            Context creation info for OpenGL + GLES
        */
        SioSurfaceCreateInfoGL gl;
    }
}

alias OnWindowHit = SioHitResult function(SioWindow window, vec2i mousePosition) nothrow @nogc;
alias OnWindowEvent = void function(SioWindow window, SioEvent event) @nogc;
alias OnWindowSwap = void function(SioWindow window) @nogc;

/**
    A window
*/
class SioWindow : SioIEventHandler {
@nogc:
private:
    SDL_Window* handle;
    SioWindowID wID;
    SioWindowStyle wStyle;
    nstring title;
    bool _borderless;
    bool _resizable;

    // Surface
    SioSurfaceCreateInfo surfaceInfo;
    void* surfaceHandle;

    SDL_WindowFlags setupWindowFlags(SioWindowCreateInfo info) {

        SDL_WindowFlags flags;
        flags |= SDL_WINDOW_HIDDEN;

        if (info.borderless) flags |= SDL_WINDOW_BORDERLESS;
        if (info.resizable) flags |= SDL_WINDOW_RESIZABLE;
        version(OSX) flags |= SDL_WINDOW_ALLOW_HIGHDPI;

        // Show IME Composition window
        // Allow long compositions
        SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");
        SDL_SetHint(SDL_HINT_IME_SUPPORT_EXTENDED_TEXT, "1");

        // Allow windows to take focus on Windows
        SDL_SetHint(SDL_HINT_FORCE_RAISEWINDOW, "1");

        // Attribute and flag setup
        final switch(info.surfaceInfo.type) {
            case SioWindowSurfaceType.GL:
            case SioWindowSurfaceType.GLES:
                flags |= SDL_WINDOW_OPENGL;

                SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, info.surfaceInfo.gl.major );
                SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, info.surfaceInfo.gl.minor );
                SDL_GL_SetAttribute(
                    SDL_GL_CONTEXT_PROFILE_MASK, 
                    info.surfaceInfo.type == SioWindowSurfaceType.GL ? 
                        SDL_GL_CONTEXT_PROFILE_CORE :
                        SDL_GL_CONTEXT_PROFILE_ES
                );
                break;

            case SioWindowSurfaceType.metal:
                flags |= SDL_WINDOW_METAL;
                break;
        }

        return flags;
    }

    bool setupSurface(SDL_Window* window, SioWindowSurfaceType type) {
        final switch(type) {
            case SioWindowSurfaceType.GL:
            case SioWindowSurfaceType.GLES:
                surfaceHandle = cast(void*)SDL_GL_CreateContext(window);
                SDL_GL_MakeCurrent(window, cast(SDL_GLContext)surfaceHandle);
                return true;

            case SioWindowSurfaceType.metal:
                surfaceHandle = SDL_Metal_CreateView(window);
                return true;
        }
    }

    void createWindow(SioWindowCreateInfo info) {
        this.title = info.title;
        this.wStyle = info.windowStyle;
        this.surfaceInfo = info.surfaceInfo;
        
        SDL_WindowFlags flags = this.setupWindowFlags(info);

        handle = SDL_CreateWindow(title.toCString(), info.x, info.y, info.width, info.height, flags);
        enforce(handle !is null, nstring("Basic window creation failed!"));
        enforce(this.setupSurface(handle, info.surfaceInfo.type), nstring("Rendering context creation failed!"));

        this.wID = SDL_GetWindowID(handle);
    }

    // Events
    OnWindowHit evOnWindowHit;
    OnWindowEvent evOnWindowEvent;
    OnWindowSwap evOnWindowSwap;
public:

    ~this() {

        SioEventLoop.instance().removeAllHandlersFor(wID);

        // Destroy metal handle if need be
        if (surfaceInfo.type == SioWindowSurfaceType.metal) {
            SDL_Metal_DestroyView(cast(SDL_MetalView)surfaceHandle);
        }

        // Destroy window
        SDL_DestroyWindow(handle);
    }

    /**
        Creates a window
    */
    this(SioWindowCreateInfo windowInfo) {
        this.createWindow(windowInfo);

        SioEventLoop.instance().addHandler(wID, this);
    }

    /**
        Gets the numeric ID of the Window
    */
    final
    SioWindowID getId() {
        return wID;
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
    SioWindowSurfaceType getSurfaceType() {
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
        Gets the size of the window in pixels
    */
    vec2i getFramebufferSize() {
        vec2i ret;
        SDL_GetWindowSizeInPixels(handle, &ret.vector[0], &ret.vector[1]);
        return ret;
    }

    /**
        Gets the size of the window in screen units
    */
    vec2i getWindowSize() {
        vec2i ret;
        SDL_GetWindowSize(handle, &ret.vector[0], &ret.vector[1]);
        return ret;
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
        Makes OpenGL(ES) context current for this window

        Does nothing on Metal
    */
    final
    void makeCurrent() {
        final switch(surfaceInfo.type) {
            case SioWindowSurfaceType.GL:
            case SioWindowSurfaceType.GLES:
                SDL_GL_MakeCurrent(handle, cast(SDL_GLContext)surfaceHandle);
                break;
            case SioWindowSurfaceType.metal: break;
        }
    }

    /**
        Execute a framebuffer swap on the window.

        This will be called automatically on redraw events.
    */
    final
    void swap() {
        switch(surfaceInfo.type) {
            case SioWindowSurfaceType.GL:
            case SioWindowSurfaceType.GLES:
                SDL_GL_SwapWindow(handle);
                break;

            default: break;
        }

        if (this.evOnWindowSwap) {
            this.evOnWindowSwap(this);
        }
    }

    /**
        Make this window a modal window for another
    */
    final
    void setModalFor(SioWindow other) {
        SDL_SetWindowModalFor(handle, other ? other.handle : null);
    }

    /**
        Set a function called when a window hit test is requested.
        Only is called for SIO windows.

        NOTE: The window hit event may not throw exceptions.
    */
    final
    void setOnWindowHitTest(OnWindowHit func) {
        if (wStyle == SioWindowStyle.sioWindow) {
            this.evOnWindowHit = func;
            SDL_SetWindowHitTest(handle, func ? &_SDL_HitTest_Impl : null, cast(void*)this);
        }
    }

    /**
        Sets a function which is called whenever the window swaps.
    */
    final
    void setOnWindowSwap(OnWindowSwap func) {
        this.evOnWindowSwap = func;
    }

    /**
        Set a function called when a window hit test is requested.
        Only is called for SIO windows.

        NOTE: The window hit event may not throw exceptions.
    */
    final
    void setEventHandler(OnWindowEvent func) {
        this.evOnWindowEvent = func;
    }

    /**
        Pushes an event to the window
    */
    final
    void processEvent(SioEvent event) {
        
        if (this.evOnWindowEvent) {
            this.evOnWindowEvent(this, event);
        }

        // Automatically swap on redraw.
        if (event.type == SioEventType.window && 
            event.window.event == SioWindowEventID.redraw) {
            this.swap();
        }
    }

    /**
        Request a redraw by pushing it on to the event queue
    */
    final
    void requestRedraw() {
        SioEvent event;
        event.target = wID;
        event.type = SioEventType.window;
        event.window.event = SioWindowEventID.redraw;

        SioEventLoop.instance().pushEvent(event);
    }
}

//
//              PRIVATE CALLBACK DELEGATION
//
private {
    extern(C) SDL_HitTestResult _SDL_HitTest_Impl(SDL_Window* win, const(SDL_Point)* area, void* data) nothrow {
        SioWindow window = cast(SioWindow)data;
        return window.evOnWindowHit(window, vec2i(area.x, area.y));
    }
}