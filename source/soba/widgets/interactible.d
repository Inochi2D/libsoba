module soba.widgets.interactible;
import soba.widgets.widget;
import soba.canvas;
import soba.ssk;
import soba.sio;
import numem.all;

abstract
class SbInteractible : SbWidget {
@nogc:
private:

protected:

    /**
        Called when the widget is being drawn to
    */
    void onDraw(SbContext ctx) { }

    override
    void onRedrawRequested() {
        if (SskCanvasSurface ctx = cast(SskCanvasSurface)this.getSurface()) {
            SbContext sbctx = ctx.begin();
            this.onDraw(sbctx);
            ctx.end();
            this.getSurface().markDirty();
        }
    }

    /**
        Called when a change happens that'd require reflowing the widget.
    */
    override
    void onReflow() {
        if (this.getParent()) {
            this.setBounds(this.getParent().getBounds());
            super.onReflow();
        }
    }

public:
    this() {
        this.setSurface(nogc_new!SskSurface());
        this.requestRedraw();
    }

    /**
        Called when a widget requests a redraw.
    */
    // void onDraw(ref SbDrawingContext context) { }


    // /**
    //     Called when the window is resized
    // */
    // void onResize(float width, float height) { }

    // /**
    //     Called when the mouse moves within the window

    //     Returns whether the input event was handled.
    // */
    // bool onMouseMove(float x, float y) {
    //     foreach(SbWidget child; children) {
    //         if (child && child.shown) {
    //             if (this.getBounds().intersects(vec2(x, y))) {
    //                 if (child.onMouseMove(x, y)) break;
    //             }
    //         }
    //     }
    //     return false;
    // }

    // /**
    //     Called when the mouse clicks within the window

    //     Returns whether the input event was handled.
    // */
    // bool onMouseClicked(float x, float y, SioMouseButton button) { 
    //     foreach(child; children) {
    //         if (child && child.shown) {
    //             if (child.getBounds().intersects(vec2(x, y))) {
    //                 if (child.onMouseClicked(x, y, button)) break;
    //             }
    //         }
    //     }
    //     return false;
    // }

    // /**
    //     Called when the mouse double clicks within the window

    //     Returns whether the input event was handled.
    // */
    // bool onMouseDoubleClicked(float x, float y, SioMouseButton button) { 
    //     foreach(child; children) {
    //         if (child && child.shown) {
    //             if (child.getBounds().intersects(vec2(x, y))) {
    //                 if (child.onMouseDoubleClicked(x, y, button)) break;
    //             }
    //         }
    //     }
    //     return false;
    // }

    // /**
    //     Called when the mouse is released within the window

    //     Returns whether the input event was handled.
    // */
    // bool onMouseReleased(float x, float y, SioMouseButton button) { 
    //     foreach(child; children) {
    //         if (child && child.shown) {
    //             if (child.getBounds().intersects(vec2(x, y))) {
    //                 if (child.onMouseReleased(x, y, button)) break;
    //             }
    //         }
    //     }
    //     return false;
    // }

    // /**
    //     Gets whether this widget is focused
    // */
    // bool isFocused() {
    //     return SioEventLoop.instance.getFocus() && SioEventLoop.instance.getFocus() is this;
    // }

    // /**
    //     Whether the widget can take the focus
    // */
    // bool isFocusable() { return false; }
}