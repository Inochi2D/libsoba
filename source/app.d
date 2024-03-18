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

        SbBox box = nogc_new!SbBox(SbBoxDirection.Horizontal, true, true);

        box.addChild(
            nogc_new!SbButton(nstring("This is a long test string"))
            .setOnClicked((button) {
                printf("Hello, world!\n");
            })
            .setBorderRadius(16),
            SbChildPosition.Back
        );
        
        this.addChild(box, SbChildPosition.Back);
        this.showAll();
    }
}