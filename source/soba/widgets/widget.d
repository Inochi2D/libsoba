module soba.widgets.widget;
import soba.core.math;
import soba.sio.events;
import soba.sio;
import soba.ssk;

import numem.all;

/**
    The base of all widgets
*/
abstract
class SbWidget : SioIAnimationHandler {
@nogc:
private:
    bool shown;
    recti bounds;
    vec2i requestedSize;
    vec2i minSize = vec2i(0, 0);
    vec2i maxSize = vec2i(int.max, int.max);

    SbWidget parent;
    weak_vector!SbWidget children;

    void setParent(SbWidget parent) {

        // Disassociate with old
        if (this.parent) {
            foreach(i; 0..this.parent.children.size()) {
                if (cast(void*)this.parent.children[i] == cast(void*)this) {
                    this.parent.removeChild(i);
                    break;
                }
            }
        }

        // We want to fit our parent
        this.setRequestedSize(parent.bounds.dimensions);
        this.parent = parent;
    }

    SskSurface surface;

protected:

    /**
        Sets the surface of this widget.
    */
    void setSurface(SskSurface surface) {
        
        // Replaces the surface.
        if (this.surface) {
            if (auto parent = this.surface.getParent()) {
                parent.addChild(surface);
                parent.removeChild(this.surface);
            }
            nogc_delete(this.surface);
        }

        this.surface = surface;
    }
    
    /**
        Adds a child to the widget
    */
    size_t addChild(bool front = true)(SbWidget widget) {
        widget.setParent(this);
        widget.onReparent(this);

        static if (front) {
            children.pushFront(widget);
        } else {
            children ~= widget;
        }

        widget.requestRedraw();
        this.reflow();
        return children.size();
    }

    /**
        Removes a child by its offset
    */
    final
    bool removeChild(size_t offset) {
        if (offset >= children.size())
            return false;

        children.remove(offset);
        this.reflow();
        return true;
    }

    /**
        Removes a child
    */
    final
    SbWidget removeChild(SbWidget toRemove) {
        ptrdiff_t idx = -1;
        foreach(i, child; children) {
            if (toRemove is child) {
                idx = i;
            }
        }

        if (idx < 0) return null;
        SbWidget toReturn = children[idx];
        this.removeChild(idx);
        toReturn.parent = null;
        return toReturn;
    }

    /**
        Gets the child widgets to this widget
    */
    final
    SbWidget[] getChildren() {
        return this.children[0..$];
    }

    /**
        Gets the parent widget
    */
    SbWidget getParent() {
        return parent;
    }

    /**
        Gets the surface this widget is rendering on to
    */
    final
    SskSurface getSurface() {
        if (surface) {
            return surface;
        } else if (parent) {
            return parent.getSurface();
        } else return null;
    }

    /**
        Called when a change happens that'd require reflowing the widget.
    */
    void onReflow() {
        if (surface) {
            surface.setBounds(this.getBounds());
            this.requestRedraw();
        }

        foreach(child; children) {
            child.onReflow();
        }
    }


    /**
        Called when this node has a new parent
    */
    void onReparent(SbWidget new_) {
        if (new_) {
            new_.surface.addChild(this.getSurface());
        }
    }

    /**
        Puts this widget into the event loop's animation queue

        Implement the animation via the runFrame function.
    */
    final
    void animate() {
        SioEventLoop.instance().addAnimation(this);
    }

    /**
        Event handler
    */
    void onEvent(SioEvent event) {
        foreach(SbWidget child; children) {
            if (child.isVisible()) {
                child.onEvent(event);
            }
        }
    }

    /**
        Event called when visibility is changed.
    */
    void onVisibilityChanged(bool newState) { }

    /**
        Event called when redraw was requested.
    */
    void onRedrawRequested() { }

public:

    this() {

        // Widget is dirty the first time it exists
        this.requestRedraw();
    }

    /**
        Shows this widget and all subwidgets
    */
    SbWidget showAll() {
        this.show();

        foreach(child; children) {
            child.showAll();
        }

        return this;
    }

    final
    void reflow() {
        this.onReflow();
    }

    /**
        Shows the widget
    */
    SbWidget show() {
        if (!shown) {
            shown = true;
            
            this.onVisibilityChanged(true);
            this.reflow();
            this.requestRedraw();
        }

        return this;
    }

    /**
        Hides the widget
    */
    SbWidget hide() {
        if (shown) {
            shown = false;
            
            this.onVisibilityChanged(false);
            this.requestRedraw();
        }
        return this;
    }

    /**
        Gets the rectangle bounds of the widget
    */
    recti getBounds() {
        return bounds;
    }

    /**
        Sets the bounds of the widget
    */
    SbWidget setBounds(recti bounds) {

        // Force the bounds to be within min-max
        bounds.width = clamp(bounds.width, minSize.x, maxSize.x);
        bounds.height = clamp(bounds.height, minSize.y, maxSize.y);
        this.bounds = bounds;
        this.requestRedraw();

        return this;
    }

    /**
        Gets the requested size of the widget
    */
    vec2i getRequestedSize() {
        return requestedSize;
    }

    /**
        Sets the requested size of the widget
    */
    SbWidget setRequestedSize(vec2i requestedSize) {
        this.requestedSize = requestedSize;
        return this;
    }

    /**
        Gets the requested size of the widget
    */
    vec2i getMinimumSize() {
        return minSize;
    }

    /**
        Sets the requested size of the widget
    */
    SbWidget setMinimumSize(vec2i minSize) {
        this.minSize = minSize;
        return this;
    }

    /**
        Gets the requested size of the widget
    */
    vec2i getMaximumSize() {
        return maxSize;
    }

    /**
        Sets the requested size of the widget
    */
    SbWidget setMaximumSize(vec2i maxSize) {
        this.maxSize = maxSize;
        return this;
    }

    /**
        Requesting the widget be redrawn
    */
    final
    void requestRedraw() {
        this.onRedrawRequested();

        if (surface) {
            surface.markDirty();
        }
        
        if (parent) {
            parent.requestRedraw();
        }
    }

    /**
        Gets whether the widget needs to be redrawn
    */
    final
    bool isDirty() {
        return surface ? surface.isDirty() : false;
    }

    /**
        Gets whether the widget is visible
    */
    final
    bool isVisible() {
        return shown;
    }

    /**
        Animates the widget.

        Return true to indicate that the animation is stopped.
        Return false to indicate that the animation is still running.

        This may also be used for continuous updates.
        Remember to call requestRedraw() when done with a frame.
    */
    bool runFrame(float currTime, float deltaTime) { return true; }
}
