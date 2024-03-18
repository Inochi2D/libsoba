module soba.widgets.widget;
import soba.core.math;
import soba.core.events;
import soba.drawing;
import numem.all;

abstract class SbWidget {
nothrow @nogc:
private:
    bool shown;
    bool dirty;
    recti bounds;
    vec2i requestedSize;
    vec2i minSize;

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

protected:
    
    /**
        Adds a child to the widget
    */
    size_t addChild(bool front = true)(SbWidget widget) {
        widget.setParent(this);

        static if (front) {
            children.pushFront(widget);
        } else {
            children ~= widget;
        }

        widget.markDirty();
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
    ref SbSurface getSurface() {
        return parent.getSurface();
    }

    /**
        Gets the drawing context this widget is rendering with
    */
    ref SbDrawingContext getDrawingContext() {
        return parent.getDrawingContext();
    }

    /**
        Called when a change happens that'd require reflowing the widget.
    */
    void onReflow() {
        
        if (bounds.width < minSize.x) {
            bounds.width = minSize.x;
        }

        if (bounds.height < minSize.y) {
            bounds.height = minSize.y;
        }
        
        foreach(child; children) {
            child.onReflow();
        }
    }

    /**
        Called when a widget requests a redraw.
    */
    void onDraw(ref SbDrawingContext context) { }


    /**
        Called when the window is resized
    */
    void onResize(float width, float height) { }

    /**
        Called when the mouse moves within the window

        Returns whether the input event was handled.
    */
    bool onMouseMove(float x, float y) {
        foreach(SbWidget child; children) {
            if (child && child.shown) {
                if (this.getBounds().intersects(vec2(x, y))) {
                    if (child.onMouseMove(x, y)) break;
                }
            }
        }
        return false;
    }

    /**
        Called when the mouse clicks within the window

        Returns whether the input event was handled.
    */
    bool onMouseClicked(float x, float y, SbMouseButton button) { 
        foreach(child; children) {
            if (child && child.shown) {
                if (child.getBounds().intersects(vec2(x, y))) {
                    if (child.onMouseClicked(x, y, button)) break;
                }
            }
        }
        return false;
    }

    /**
        Called when the mouse double clicks within the window

        Returns whether the input event was handled.
    */
    bool onMouseDoubleClicked(float x, float y, SbMouseButton button) { 
        foreach(child; children) {
            if (child && child.shown) {
                if (child.getBounds().intersects(vec2(x, y))) {
                    if (child.onMouseDoubleClicked(x, y, button)) break;
                }
            }
        }
        return false;
    }

    /**
        Called when the mouse is released within the window

        Returns whether the input event was handled.
    */
    bool onMouseReleased(float x, float y, SbMouseButton button) { 
        foreach(child; children) {
            if (child && child.shown) {
                if (child.getBounds().intersects(vec2(x, y))) {
                    if (child.onMouseReleased(x, y, button)) break;
                }
            }
        }
        return false;
    }

public:

    this() {

        // Widget is dirty the first time it exists
        this.markDirty();
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
        shown = true;
        this.markDirty();
        this.reflow();

        return this;
    }

    /**
        Hides the widget
    */
    SbWidget hide() {
        shown = false;
        this.markDirty();

        return this;
    }

    /**
        Draws the widget

        Returns the amount of widgets redrawn
    */
    int draw() {
        
        // If the root node is hiddden then we won't draw it anyways
        if (!this.shown) return 0;

        // TODO: Is this the right thing to do?
        int acc = 0;
        if (this.dirty) {
        
            this.reflow();

            // We're cleaning it now.
            this.dirty = false;
            this.onDraw(this.getDrawingContext());
            acc++;


            // Draw children
            foreach (SbWidget child; children) {

                // We only want to re-draw dirty and shown widgets
                if (child && child.shown && child.dirty) {
                    acc += child.draw();
                }
            }
        }

        return acc;
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
        this.bounds = bounds;
        this.markDirty();
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
        Marks the widget dirt, setting it up for redrawing
    */
    final
    void markDirty() {
        this.dirty = true;

        if (parent && !parent.isDirty()) {
            parent.markDirty();
        }

        foreach(child; children) {
            child.markDirty();
        }
    }

    /**
        Gets whether the widget is dirty
    */
    final
    bool isDirty() {
        return dirty;
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
    */
    bool onAnimate(float time) { return true; }
}
