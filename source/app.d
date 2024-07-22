module app;
import soba;
import numem.all;
import numem.conv;

import soba.ssk;
import soba.sio;
import soba.canvas;

import soba.widgets;

void main() {
    sbInit();
    
    SbAppInfo info;
    info.name = "My Cool App";
    info.version_ = "1.0.0";

    MyDrawingWidget widget = nogc_new!MyDrawingWidget();

    SbWindow window = nogc_new!SbWindow(info.name, 640, 480);
    window.setChild(widget);
    SbApplication app = nogc_new!SbApplication(info);
    app.setRootWindow(window);

    app.run();
}


class MyDrawingWidget : SbDrawingWidget {
@nogc:
private:
    SbFontFace face;
    SbFont font;

protected:
    override
    void onDraw(SbContext ctx) {
        ctx.setSource(vec4(0, 0, 0, 1));
        ctx.clearAll();

        recti bounds = this.getBounds().expanded(vec2i(-32, -32));

        ctx.setSource(vec4(0.5, 0.5, 0.5, 1));
        ctx.rect(rect(bounds.x, bounds.y, bounds.width, bounds.height));
        ctx.fill();

        ctx.setSource(vec4(1, 1, 1, 1));
        vec2 cont = ctx.fillText(font, this.getBounds().width.toString(), vec2(32, 32));
        cont = ctx.fillText(font, nstring("x"), cont);
        cont = ctx.fillText(font, this.getBounds().width.toString(), cont);
    }

public:
    this() {
        face = nogc_new!SbFontFace(nstring("noto.ttf"), 0);
        font = nogc_new!SbFont(face, 24);
    }
}