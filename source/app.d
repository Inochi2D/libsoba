module app;
import soba;
import soba.drawing;
import numem.all;
import inmath;
import soba.core;
import soba.widgets;
import bindbc.sdl;
import std.stdio;

void main() {
    sbInit();
    // shared_ptr!SbDrawingContext sctx = createContext(SbSurfaceFormat.ARGB, 640, 480);
    // SbDrawingContext ctx = sctx.get();

    // ctx.drawButton(rect(8, 8, 256, 64), nstring("Button"), true);
    // ctx.drawButton(rect(8, 64+16, 256, 64), nstring("Button"));
    // ctx.saveToPNG(nstring("test.png"));
    SbMainWindow window = nogc_new!SbMyWindow(SbApplication(
        nstring("My Cool App")
    ), 640, 480);
    sbRunApplication(window);
}

class SbMyWindow : SbMainWindow {
nothrow @nogc:
private:

public:
    this(ref SbApplication app, int width, int height) {
        super(app, width, height);

        SbButton button = nogc_new!SbButton(nstring("uwu"), 256, 64);
        button.setBorderRadius(16);

        this.addChild(button);
    }

}