module soba.ui.window;
import soba.ui.widget;
import soba.core.gpu;
import soba.core.gpu.surface;
import soba.core.app;
import bindbc.sdl;
import std.string;
import std.exception;

abstract class SbWindow : SbWidget, SbGPUCreationTargetI {
private:
    // Close requested
    bool isCloseRequested = false;

    // GPU Variables
    SbGPUCreationTargetI parentTarget;
    SbGPUContext context;
    SbGPUSurface surface;

    // SDL Variables
    uint createFlags;
    uint requestedWidth, requestedHeight;
    uint windowID;
    SDL_Window* handle;
    const(char)* title;

protected:
    /**
        Creates an underlying SDL window for the SbWindow
        This will create a context and a surface.

        Calling this function while the window has a parent will
        result in an exception.
    */
    void createNativeWindow(uint windowFlags) {
        enforce(!getParent(), "Cannot create a native window while parented to a widget!");

        createFlags = windowFlags;
        handle = sbGPUCreateCompatibleSDLWindow(this.title, requestedWidth, requestedHeight, windowFlags | SDL_WINDOW_ALLOW_HIGHDPI, sbGPUGetGlobalContextType());
        windowID = SDL_GetWindowID(handle);
        context = sbGPUNewContext(this, sbGPUGetGlobalContextType());
        surface = context.getSurface();
    }

    /**
        Sets the parent of this node
    */
    override
    void setParent(SbWidget widget) {
        SbGPUContext previous = this.context;
        SbGPUContext next;

        super.setParent(widget);
        
        // Handle context change
        if (widget) {

            SbWidget currentTest = widget;
            while(currentTest) {
                if (SbGPUCreationTargetI newtarget = cast(SbGPUCreationTargetI)currentTest) {
                    parentTarget = newtarget;
                    next = newtarget.gpuContext();
                    break;
                }

                currentTest = currentTest.getParent();
            }

            // Destroys context
            // Parent's context will be reused.
            if (hasContext()) {
                SDL_DestroyWindow(handle);
                this.handle = null;
                this.context = null;
                this.surface = null;
            }
        } else {

            // Creates a context if one doesn't exist already
            if (!hasContext()) {
                parentTarget = null;
                this.createNativeWindow(createFlags);
            } else {

                // NOTE: We don't want to needlessly recreate the context
                //       as such when a context is already present
                //       and we repearent to null, we just do nothing.
                return;
            }
        }

        // NOTE: In this case something changed significantly enough that we should
        //       Notify the app to recreate its context objects.
        this.isCloseRequested = false;
        this.onContextChanged(previous, next);
    }

    /**
        Constructs a window parented to a widget
    */
    this(SbWidget parent, string title, uint width, uint height) {

        // NOTE: we don't neccesarily want to open the window yet,
        // So we just set it here.
        super.setParent(parent);
        this.title = title.toStringz;
        this.requestedWidth = width;
        this.requestedHeight = height;
    }

    /**
        Constructs a window
    */
    this(string title, uint width, uint height) {
        this(null, title, width, height);
    }

public:

    /**
        Whether the creation target already has a valid context
    */
    bool hasContext() { return context !is null; }
    
    /**
        The GPU context of the target
    */
    ref SbGPUContext gpuContext() { return parentTarget ? parentTarget.gpuContext() : context; }

    /**
        The GPU surface of the target
    */
    ref SbGPUSurface gpuSurface() { return parentTarget ? gpuContext.getSurface() : surface; }

    /**
        The handle to the underlying SDL window
    */
    SDL_Window* getHandle() { return handle; }

    /**
        Called during a window event
    */
    void onWindowEvent(SDL_WindowEvent event) {

        // Handle basic window events automatically
        // Can be overwritten
        if (!getParent()) {
            switch(event.event) {
                case SDL_WINDOWEVENT_CLOSE:
                    this.close();
                    break;
                case SDL_WINDOWEVENT_SIZE_CHANGED:
                    gpuSurface().onResize(event.data1, event.data2);
                    break;
                case SDL_WINDOWEVENT_DISPLAY_CHANGED:

                    // NOTE: If the display is changed resize the surface
                    //       this should ensure that the window handles
                    //       dragging across displays with differing DPIs
                    //       correctly.
                    uint dwidth, dheight;
                    SDL_GetWindowSize(handle, cast(int*)&dwidth, cast(int*)&dheight);
                    gpuSurface().onResize(dwidth, dheight);
                    break;
                default: break;
            }
        }
    }

    /**
        Called when the window context is destroyed

        This should re-initialize any data created under the old context
        And recreate it under the new context.
    */
    abstract void onContextChanged(SbGPUContext previous, SbGPUContext current);

    /**
        Closes the window

        Does nothing if the window is a child of another widget
    */
    void close() {
        if (!getParent()) {

            // Destroy window and set handle to null
            isCloseRequested = true;
            SDL_DestroyWindow(handle);
            handle = null;
        }
    }

    /**
        Gets the underlying ID of the window
    */
    uint getID() {
        return windowID;
    }

    /**
        Gets whether the window is closed
    */
    bool isClosed() {
        return isCloseRequested && !handle;
    }

    /**
        Gets the width of the widget in Soba Units
    */
    override
    uint getWidth() {
        return gpuSurface ? requestedWidth : gpuSurface.getWidthPx();
    }
    
    /**
        Gets the height of the widget in Soba Units
    */
    override
    uint getHeight() {
        return gpuSurface ? requestedHeight : gpuSurface.getHeightPx();
    }
}