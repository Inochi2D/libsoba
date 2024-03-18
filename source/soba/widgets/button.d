module soba.widgets.button;
import soba.widgets.widget;
import soba.drawing.contexts;
import soba.core.math;
import soba.core.events;
import numem.all;

class SbButton : SbWidget {
nothrow @nogc:
private:
    bool clicked;
    bool hovered;
    recti bounds;
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
        } else if (hovered) {
            outLineColor = [
                SbGradientStop(0, vec4(0.9, 0.9, 0.9, 1)),
                SbGradientStop(1, vec4(1.0, 1.0, 1.0, 1.0)),
            ];

            mainColor = [
                SbGradientStop(0, vec4(1.0, 1.0, 1.0, 1.0)),
                SbGradientStop(1, vec4(0.9, 0.9, 0.9, 1)),
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
        context.setStrokeWidth(5);
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
    this(nstring text, recti area) {
        super();

        this.bounds = area;
        this.text = text;
    }

    this(nstring text) {
        this(text, recti(0));
    }

    SbButton setBorderRadius(float radius) {
        this.borderRadius = radius;
        return this;
    }

    override
    recti getBounds() {
        return bounds;
    }

    SbButton setBounds(recti bounds) {
        this.bounds = bounds;
        return this;
    }

    override
    bool onMouseMove(float x, float y) {
        this.markDirty();
        
        if (this.getBounds().intersects(vec2(x, y))) {
            hovered = true;
        } else {
            hovered = false;
            clicked = false;
        }

        return true;
    }

    override
    bool onMouseClicked(float x, float y, SbMouseButton btn) {
        if (btn == SbMouseButton.Left) {
            clicked = true;
            this.markDirty();
        }
        return true;
    }

    override
    bool onMouseReleased(float x, float y, SbMouseButton btn) {
        if (btn == SbMouseButton.Left) {
            if (clicked == true) {
                
            }
            clicked = false;
            this.markDirty();
        }
        return true;
    }
}
