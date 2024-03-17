module soba.widgets.window.mainwindow;
import soba.widgets.window;
import soba.widgets.container;
import numem.all;
import soba.core.window;
import soba.core.app;
import soba.drawing.surfaces;
import soba.drawing.contexts;
import inmath;
import bindbc.sdl;

class SbMainWindow : SbWindow {
nothrow @nogc:
private:
    SbApplication app;
    SbSurface surface;
    SbDrawingContext ctx;

public:
    ~this() {
        nogc_delete(surface);
    }

    this(ref SbApplication app, int width, int height) {
        super(SbWindowStyle.MainWindow, SbWindowFlags.Resizable);

        this.app = app;
        this.createBackingWindow(app.appName, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, 0);
        this.surface = createSurfaceForBackingWindow(backing);
        this.ctx = surface.getContext();
    }

    override
    void update() {

    }

    override
    void show() {
        super.show();
        if (backing)
            backing.show();
    }

    override
    void hide() {
        super.hide();
        if (backing) 
            backing.hide();
    }

    final
    void close() {
        nogc_delete(backing);
        backing = null;
    }

    /**
        Gets whether the app has requested to close.
    */
    final
    bool isCloseRequested() {
        return backing is null;
    }

    /**
        Redraws the entire window
    */
    void draw() {
        super.draw(ctx);
        surface.flush();

        backing.getCompositor().beginFrame();
        backing.getCompositor().blitSurface(surface, rect(0, 0, surface.getWidth(), surface.getHeight()));
        backing.getCompositor().endFrame();
    }
}
