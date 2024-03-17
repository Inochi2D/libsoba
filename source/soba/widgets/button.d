module soba.widgets.button;
import soba.widgets.widget;
import soba.drawing.contexts;
import numem.all;
import inmath;

class SbButton : SbWidget {
nothrow @nogc:
private:
    bool clicked;
    bool hovered;
    rect bounds;
    nstring text;


    float borderRadius = 8;

protected:

    override
    void onDraw(ref SbDrawingContext context) {
        context.setBorderRadius(borderRadius, borderRadius, borderRadius, borderRadius);
        context.rectangleRounded(bounds.x, bounds.y, bounds.width, bounds.height);

        SbGradientStop[2] outLineColor;
        SbGradientStop[2] mainColor;

        if (clicked) {
            outLineColor = [
                SbGradientStop(0, vec4(1.0, 1.0, 1.0, 1.0)),
                SbGradientStop(1, vec4(0.8, 0.8, 0.8, 1)),
            ];

            mainColor = [
                SbGradientStop(0, vec4(0.6, 0.6, 0.6, 1)),
                SbGradientStop(1, vec4(0.8, 0.8, 0.8, 1)),
            ];
        } else {
            outLineColor = [
                SbGradientStop(0, vec4(0.8, 0.8, 0.8, 1)),
                SbGradientStop(1, vec4(1.0, 1.0, 1.0, 1.0)),
            ];

            mainColor = [
                SbGradientStop(0, vec4(1.0, 1.0, 1.0, 1.0)),
                SbGradientStop(1, vec4(0.8, 0.8, 0.8, 1)),
            ];
        }

        // Draw outline
        context.setGradientLinear(outLineColor, 0, bounds.top, 0, bounds.bottom);
        context.strokePreserve();

        // Draw fill color
        context.setGradientLinear(mainColor, 0, bounds.top, 0, bounds.bottom);
        context.fill();

        context.setColor(0, 0, 0, 1);
        context.setFontSize(24);

        float tw, th;
        context.measureText(text, tw, th);
        context.drawText(text, bounds.center.x-(tw/2), bounds.center.y+(th/2));
    }

public:
    this(nstring text, int width, int height) {
        super();

        this.bounds = rect(32, 32, width, height);
        this.text = text;
    }

    this(nstring text) {
        this(text, 1, 1);
    }

    void setBorderRadius(float radius) {
        this.borderRadius = radius;
    }

    override void update() {

    }

    override rect getBounds() {
        return bounds;
    }

    override void setBounds(rect bounds) {
        this.bounds = bounds;
    }
}
