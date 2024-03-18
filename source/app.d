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

        enum offset = 16;
        foreach(i; 0..10) {
            this.addChild(
                nogc_new!SbButton(nstring("uwu"), recti(offset, offset+((offset*i)+(i*64)), 256, 64))
                .setBorderRadius(16)
                .show(),
                SbChildPosition.Back
            );
        }
    }
}