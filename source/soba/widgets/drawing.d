module soba.widgets.drawing;
import soba.widgets.widget;
import soba.canvas;
import soba.ssk;
import soba.sio;
import numem.all;


class SbDrawingWidget : SbWidget {
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
        this.setSurface(nogc_new!SskCanvasSurface(0, 0));
        this.requestRedraw();
    }
}