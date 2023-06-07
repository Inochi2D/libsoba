module soba.ui.widget;
import soba.drawing;
import std.algorithm.searching;
import std.algorithm.mutation;
import sdl.events;
import soba.ui.window;

/**
    A libsoba widget
*/
class SbWidget {
private:
    SbWindow topLevelWindow;
    SbWidget parent;
    SbWidget[] children;
    bool shown_ = false;

protected:
    void setParent(SbWidget parent) {
        SbWidget prevParent = this.parent;

        // Remove from previous parent's children list
        if (prevParent) {
            ptrdiff_t idx = prevParent.children.countUntil(this);
            if (idx != -1) {
                prevParent.children = prevParent.children.remove(idx);
            }
        }

        // Re-parent
        this.parent = parent;

        if (parent) {
            this.parent.children ~= this;

            // Find the top level window
            SbWidget widget = parent;
            while (widget) {

                // NOTE: We don't want to return early as we want to top-level window
                //       if a window is not a top level window we'll have a performance
                //       penalty of multiple indirections before finding the real surface
                //       
                //       The surface is needed to convert Soba Units to pixels.
                if (SbWindow window = cast(SbWindow)widget) topLevelWindow = window;
                widget = widget.parent;
            }
        }
    }

    /**
        Gets the parent widget
    */
    SbWidget getParent() {
        return parent;
    }

public:
    /**
        Show the widget
    */
    void show() {
        shown_ = true;
        onShown();
    }

    /**
        Show the widget and all subwidgets
    */
    void showAll() {
        show();
        foreach(child; children) {
            child.showAll();
        }
    }

    /**
        Hide the widget
    */
    void hide() {
        shown_ = false;
        onHidden();
    }

    /**
        Called when the widget renders
    */
    void onRender(SbDrawingContext drawing) {

        // TODO: add vector rendering context
        foreach(child; children) {
            child.onRender(drawing);
        }
    }

    /**
        On update of a singular widget
    */
    void onUpdate() {
        foreach(child; children) {
            child.onUpdate();
        }
    }

    /**
        Invoked when a mouse button event is recieved
    */
    void onMouseButtonEvent(SDL_MouseButtonEvent ev) {
        foreach(child; children) {
            child.onMouseButtonEvent(ev);
        }
    }
    
    /**
        Invoked when a mouse motion event is recieved
    */
    void onMouseMotionEvent(SDL_MouseMotionEvent ev) {
        foreach(child; children) {
            child.onMouseMotionEvent(ev);
        }
    }

    /**
        Invoked when a touch event is recieved
    */
    void onTouchEvent(SDL_TouchFingerEvent ev) {
        foreach(child; children) {
            child.onTouchEvent(ev);
        }
    }

    /**
        Invoked when a keyboard event is received
    */
    void onKeyboardEvent(SDL_KeyboardEvent ev) {
        foreach(child; children) {
            child.onKeyboardEvent(ev);
        }
    }

    void onShown() { }
    void onHidden() { }

    /**
        Gets the width of the widget in pixels
    */
    uint getWidthPx() {
        return cast(uint)(cast(double)getWidth()*cast(double)topLevelWindow.gpuSurface().dpiScaleX);
    }
    
    /**
        Gets the height of the widget in pixels
    */
    uint getHeightPx() {
        return cast(uint)(cast(double)getHeight()*cast(double)topLevelWindow.gpuSurface().dpiScaleY);
    }

    /**
        Gets whether the widget is shown
    */
    bool getShown() {
        return parent ? parent.getShown() : shown_;
    }

    /**
        Gets the width of the widget in Soba Units
    */
    abstract uint getWidth();
    
    /**
        Gets the height of the widget in Soba Units
    */
    abstract uint getHeight();
}