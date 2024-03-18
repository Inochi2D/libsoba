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
    nstring text;

    float borderRadius = 8;
    void function(SbButton button) onClickedCallback;

protected:

    override
    void onReflow() {

        float w, h;
        this.getDrawingContext().setFontSize(24);
        this.getDrawingContext().measureText(text, w, h);
        this.setRequestedSize(vec2i(cast(int)w+24, cast(int)h+32));

        super.onReflow();
    }

    override
    void onDraw(ref SbDrawingContext context) {
        context.save();
            recti bounds = this.getBounds();
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
            context.fillPreserve();

            // Clip text to rectangle
            context.clip();

            context.setColor(0, 0, 0, 1);
            context.setFontSize(24);

            float tw, th;
            context.measureText(text, tw, th);
            context.drawText(text, bounds.center.x-(tw/2), bounds.center.y+(th/2));
        context.restore();
    }

public:

    this(nstring text, recti area) {
        this(text);
        this.setBounds(area);
    }

    this(nstring text) {
        super();
        this.text = text;
        this.setMinimumSize(vec2i(48, 48));
    }

    SbButton setBorderRadius(float radius) {
        this.borderRadius = radius;
        return this;
    }

    final
    SbButton setOnClicked(void function(SbButton) nothrow @nogc callback) {
        this.onClickedCallback = callback;
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
                if (onClickedCallback) {
                    onClickedCallback(this);
                }
            }
            clicked = false;
            this.markDirty();
        }
        return true;
    }
}
