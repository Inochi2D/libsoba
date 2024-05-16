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

    SbAppInfo info;
    info.name = nstring("My Cool App");
    info.version_ = nstring("1.0.0");

    SbApplication app = nogc_new!SbApplication(info);
    app.run(nogc_new!SbMyWindow(app, 640, 480));
}

class SbMyWindow : SbMainWindow {
nothrow @nogc:
private:

public:
    this(ref SbApplication app, int width, int height) {
        super(app, width, height);

        SbBox box = nogc_new!SbBox(SbBoxDirection.Horizontal, true, true);

        foreach (i; 0 .. 5) {
            box.addChild(
                nogc_new!SbButton(nstring("This is a long test string"))
                    .setOnClicked((button) { printf("Hello, world!\n"); })
                    .setBorderRadius(16),
                    SbChildPosition.Back
            );
        }

        this.addChild(box, SbChildPosition.Back);
        this.showAll();
    }
}
