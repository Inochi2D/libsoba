module soba.widgets.window.mainwindow;
import soba.widgets.window;
import soba.widgets.container;
import soba.widgets.widget;
import numem.all;
import soba.core.math;
import soba.core.window;
import soba.core.app;
import soba.drawing.surfaces;
import soba.drawing.contexts;
import bindbc.sdl;

class SbMainWindow : SbWindow {
nothrow @nogc:
private:
    SbApplication app;
    SbSurface surface;

    shared_ptr!SbDrawingContext ctx;
    SbDrawingContext ctxref;

protected:

    override
    ref SbSurface getSurface() {
        return surface;
    }

    override
    ref SbDrawingContext getDrawingContext() {
        return ctxref;
    }

public:
    ~this() {
        nogc_delete(surface);
    }

    this(ref SbApplication app, int width, int height) {
        super(SbWindowStyle.MainWindow, SbWindowFlags.Resizable);

        this.app = app;
        this.createBackingWindow(app.appName, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, 0);
        
        // Surface and context
        this.surface = sbCreateSurface(this.getBackingWindow());
        this.ctx = createContext(surface.getFormat(), width, height);
        this.ctxref = ctx.get();
        this.ctxref.setTarget(this.surface);

        this.setResizable(true);
    }

    override
    SbWidget show() {
        super.show();
        if (this.getBackingWindow())
            this.getBackingWindow().show();

        return this;
    }

    override
    SbWidget hide() {
        super.hide();
        if (this.getBackingWindow()) 
            this.getBackingWindow().hide();

        return this;
    }

    final
    void close() {
        this.destroyBackingWindow();
    }

    /**
        Gets whether the app has requested to close.
    */
    final
    bool isCloseRequested() {
        return this.getBackingWindow() is null;
    }

    /**
        Called when the window is resized
    */
    override
    void onResize(float width, float height) {
        surface.resize(cast(size_t)width, cast(size_t)height);
        super.onResize(width, height);
        this.markDirty();
    }

    /**
        Redraws the entire window
    */
    override
    int draw() {
        bool isSelfDirty = this.isDirty();
        int acc = 0;

        if (isSelfDirty) {
            acc = super.draw();
            ctxref.flush();
        }
            
        this.getBackingWindow().getCompositor().beginFrame();
        this.getBackingWindow().getCompositor().blitSurface(surface, rect(0, 0, surface.getWidth(), surface.getHeight()));
        this.getBackingWindow().getCompositor().endFrame();

        return acc;
    }
}
