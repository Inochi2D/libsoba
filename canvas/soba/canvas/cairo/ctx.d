/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module canvas.soba.canvas.cairo.ctx;
import soba.canvas.ctx;
import soba.canvas.canvas;
import soba.canvas.pattern;
import soba.canvas.mask;
import math = inmath.linalg;
import inmath.linalg : vec2, vec3, vec4, recti;
import inmath.math : max, radians, clamp;
import cairo;
import soba.canvas.cairo.mask;
import numem.all;

class SbCairoContext : SbContext {
nothrow @nogc:
private:
    cairo_t* cr;
    SbBlendOperator op;
    shared_ptr!SbMask currentMask;

    void applyClipRects() {
        cairo_reset_clip(cr);

        if (getClipRectsActive() > 0) {
            auto currClip = getCurrentClip();
            cairo_rectangle(cr, currClip.x, currClip.y, currClip.width, currClip.height);
            cairo_clip(cr);
        }
    }

    void applyMask() {
        cairo_reset_clip(cr);

        if (currentMask.get() && currentMask.getParent() is this) {
            cairo_append_path(cr, cast(cairo_path_t*)currentMask.getHandle());
            cairo_clip(cr);
        } else {
            this.applyClipRects();
        }
    }

public:

    /**
        Destructor
    */
    ~this() {
        cairo_destroy(cr);
    }

    /**
        Creates context for canvas
    */
    this(SbCanvas canvas) {
        super(canvas);
        this.cr = cairo_create(cast(cairo_surface_t*)canvas.getHandle());

        // Default in cairo is OVER
        this.op = SbBlendOperator.sourceOver;
    }

    override
    void* getHandle() {
        return cr;
    }

    override
    SbContextCookie save() {
        cairo_save(cr);

        return null;
    }

    override
    void restore(SbContextCookie) {
        cairo_restore(cr);
    }

    override
    void setFillRule(SbFillRule fill) {
        final switch(fill) {
            case SbFillRule.evenOdd: cairo_set_fill_rule(cr, cairo_fill_rule_t.CAIRO_FILL_RULE_EVEN_ODD); return;
            case SbFillRule.winding: cairo_set_fill_rule(cr, cairo_fill_rule_t.CAIRO_FILL_RULE_WINDING); return;
        }
    }

    override
    SbFillRule getFillRule() {
        final switch(cairo_get_fill_rule(cr)) {
            case cairo_fill_rule_t.CAIRO_FILL_RULE_EVEN_ODD: return SbFillRule.evenOdd;
            case cairo_fill_rule_t.CAIRO_FILL_RULE_WINDING: return SbFillRule.winding;
        }
    }

    override
    void setLineCap(SbLineCap cap) {
        final switch(cap) {
            case SbLineCap.butt: cairo_set_line_cap(cr, cairo_line_cap_t.CAIRO_LINE_CAP_BUTT); return;
            case SbLineCap.square: cairo_set_line_cap(cr, cairo_line_cap_t.CAIRO_LINE_CAP_SQUARE); return;
            case SbLineCap.round: cairo_set_line_cap(cr, cairo_line_cap_t.CAIRO_LINE_CAP_ROUND); return;
        }
    }

    override
    SbLineCap getLineCap() {
        final switch(cairo_get_line_cap(cr)) {
            case cairo_line_cap_t.CAIRO_LINE_CAP_BUTT: return SbLineCap.butt;
            case cairo_line_cap_t.CAIRO_LINE_CAP_SQUARE: return SbLineCap.square;
            case cairo_line_cap_t.CAIRO_LINE_CAP_ROUND: return SbLineCap.round;
        }
    }

    override
    void setLineJoin(SbLineJoin join) {
        final switch(join) {
            case SbLineJoin.miter: cairo_set_line_join(cr, cairo_line_join_t.CAIRO_LINE_JOIN_MITER); return;
            case SbLineJoin.bevel: cairo_set_line_join(cr, cairo_line_join_t.CAIRO_LINE_JOIN_BEVEL); return;
            case SbLineJoin.round: cairo_set_line_join(cr, cairo_line_join_t.CAIRO_LINE_JOIN_ROUND); return;
        }
    }

    override
    SbLineJoin getLineJoin() {
        final switch(cairo_get_line_join(cr)) {
            case cairo_line_join_t.CAIRO_LINE_JOIN_MITER: return SbLineJoin.miter;
            case cairo_line_join_t.CAIRO_LINE_JOIN_BEVEL: return SbLineJoin.bevel;
            case cairo_line_join_t.CAIRO_LINE_JOIN_ROUND: return SbLineJoin.round;
        } 
    }

    override
    void setBlendOperator(SbBlendOperator op) {

        this.op = op;

        //TODO: make this a LUT
        final switch(op) {
            case SbBlendOperator.clear:         cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_CLEAR); return;
            case SbBlendOperator.source:        cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_SOURCE); return;
            case SbBlendOperator.sourceOver:    cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_OVER); return;
            case SbBlendOperator.sourceIn:      cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_IN); return;
            case SbBlendOperator.sourceOut:     cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_OUT); return;
            case SbBlendOperator.sourceAtop:    cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_ATOP); return;
            case SbBlendOperator.dest:          cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_DEST); return;
            case SbBlendOperator.destOver:      cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_DEST_OVER); return;
            case SbBlendOperator.destIn:        cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_DEST_IN); return;
            case SbBlendOperator.destOut:       cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_DEST_OUT); return;
            case SbBlendOperator.destAtop:      cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_DEST_ATOP); return;
            case SbBlendOperator.xor:           cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_XOR); return;
            case SbBlendOperator.add:           cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_ADD); return;
            case SbBlendOperator.saturate:      cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_SATURATE); return;
            case SbBlendOperator.multiply:      cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_MULTIPLY); return;
            case SbBlendOperator.screen:        cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_SCREEN); return;
            case SbBlendOperator.overlay:       cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_OVERLAY); return;
            case SbBlendOperator.darken:        cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_DARKEN); return;
            case SbBlendOperator.lighten:       cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_LIGHTEN); return;
            case SbBlendOperator.colorDodge:    cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_COLOR_DODGE); return;
            case SbBlendOperator.colorBurn:     cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_COLOR_BURN); return;
            case SbBlendOperator.hardLight:     cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_HARD_LIGHT); return;
            case SbBlendOperator.softLight:     cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_SOFT_LIGHT); return;
            case SbBlendOperator.difference:    cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_DIFFERENCE); return;
            case SbBlendOperator.exclusion:     cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_EXCLUSION); return;
            case SbBlendOperator.hslHue:        cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_HSL_HUE); return;
            case SbBlendOperator.hslSaturation: cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_HSL_SATURATION); return;
            case SbBlendOperator.hslColor:      cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_HSL_COLOR); return;
            case SbBlendOperator.hslLuminosity: cairo_set_operator(cr, cairo_operator_t.CAIRO_OPERATOR_HSL_LUMINOSITY); return;
        }
    }

    override
    SbBlendOperator getBlendOperator() {
        return this.op;
    }

    override
    void setLineWidth(float width) {
        cairo_set_line_width(cr, width);
    }

    override
    float getLineWidth(float width) {
        return cast(float)cairo_get_line_width(cr);
    }

    override
    void fill() {
        cairo_fill(cr);
    }

    override
    void fillPreserve() {
        cairo_fill_preserve(cr);
    }

    override
    void stroke() {
        cairo_stroke(cr);
    }

    override
    void strokePreserve() {
        cairo_stroke_preserve(cr);
    }

    /**
        Creates a mask for the current path.

        Use setMask to use it.
        Returns null if there's no current path.
    */
    override
    shared_ptr!SbMask fillMask() {
        cairo_path_t* path = cairo_copy_path(cr);
        if (path.num_data == 0) {
            cairo_path_destroy(path);

            shared_ptr!SbMask mask;
            return mask;
        }

        return shared_ptr!SbMask.fromPtr(nogc_new!SbCairoMask(getTarget().getFormat(), this, path));
    }
    
    override
    void setMask(shared_ptr!SbMask mask) {
        this.currentMask = mask;

        // Clear smart pointer
        if (currentMask.get() !is null) {
            nogc_delete(currentMask);
        }

        this.applyMask();
    }
    
    override
    void clearMask() {
        nogc_delete(currentMask);
        this.applyMask();
    }

    override
    void clearPath() {
        cairo_new_path(cr);
    }

    override
    void moveTo(vec2 pos) {
        cairo_move_to(cr, pos.x, pos.y);
    }

    override
    void lineTo(vec2 pos) {
        cairo_line_to(cr, pos.x, pos.y);
    }

    override
    void curveTo(vec2 pos, vec2 ctrl1, vec2 ctrl2) {
        cairo_curve_to(cr, ctrl1.x, ctrl1.y, ctrl2.x, ctrl2.y, pos.x, pos.y);
    }

    override
    void arcTo(vec2 point) {
        vec2 start = getPathCursorPos();
        
        // flat arc to nowhere
        if (point.x == start.x || point.y == start.y) {
            this.lineTo(point);
            return;
        }

        bool negative = point.x < start.x;
        vec2 diff = point-start;
        vec2 arcCenterPos = vec2(0, 0);
        float maxDiff = max(diff.x, diff.y);

        if (start.y > point.y) {
            arcCenterPos.y = start.y + maxDiff;
        }

        if (negative) {
            cairo_arc_negative(cr, arcCenterPos.x, arcCenterPos.y, maxDiff, radians(0), radians(270));
        } else {
            cairo_arc(cr, arcCenterPos.x, arcCenterPos.y, maxDiff, radians(0), radians(90));
        }
    }

    override
    void rect(math.rect r) {
        cairo_rectangle(cr, r.x, r.y, r.width, r.height);
    }

    override
    void roundRect(math.rect r, float borderRadius) {
        this.roundRect(r, borderRadius, borderRadius, borderRadius, borderRadius);
    }

    override
    void roundRect(math.rect r, float borderRadiusTL, float borderRadiusTR, float borderRadiusBL, float borderRadiusBR) {
        
        cairo_move_to(cr, r.x+borderRadiusTL, r.y);

        // Top-Right
        cairo_arc(cr, r.right-borderRadiusTR, r.top+borderRadiusTR, borderRadiusTR, radians(270), radians(360));

        // Bottom-Right
        cairo_arc(cr, r.right-borderRadiusBR, r.bottom-borderRadiusBR, borderRadiusBR, radians(0), radians(90));

        // Bottom-Left
        cairo_arc(cr, r.left+borderRadiusBL, r.bottom-borderRadiusBL, borderRadiusBL, radians(90), radians(180));

        // Top-Left
        cairo_arc(cr, r.left+borderRadiusTL, r.top+borderRadiusTL, borderRadiusTL, radians(180), radians(270));
    }

    override
    void squircle(math.rect r, float elasticity) {
        cairo_new_path(cr);

        elasticity = clamp(elasticity, 0, 1);

        float halfW = (r.width/2);
        float halfH = (r.height/2);

        float elasticW = halfW*elasticity;
        float elasticH = halfH*elasticity;

        // Begin
        cairo_move_to(cr, r.x+halfW, r.top);

        // Right center
        cairo_rel_curve_to(cr, elasticW, 0, halfW, 0, halfW, halfH);

        // Bottom center
        cairo_rel_curve_to(cr, 0, elasticH, 0, halfH, -halfW, halfH);

        // Left center
        cairo_rel_curve_to(cr, -elasticW, 0, -halfW, 0, -halfW, -halfH);

        // Top center
        cairo_rel_curve_to(cr, 0, -elasticH, 0, -halfH, halfW, -halfH);
        
        // Finalize
        cairo_close_path(cr);
    }

    override
    void closePath() {
        cairo_close_path(cr);
    }

    override
    void translate(vec2 pos) {
        cairo_translate(cr, pos.x, pos.y);
    }

    override
    void rotate(float radians) {
        cairo_rotate(cr, radians);
    }

    override
    void scale(vec2 scale) {
        cairo_scale(cr, scale.x, scale.y);
    }

    override
    void resetTransform() {
        cairo_identity_matrix(cr);
    }

    override
    vec2 getPathCursorPos() {
        vec2 pos = vec2(0, 0);
        if (cairo_has_current_point(cr)) {
            double px, py;
            cairo_get_current_point(cr, &px, &py);
            pos = vec2(px, py);
        }

        return pos;
    }

    override
    math.rect getPathExtents() {
        return math.rect.init; // TODO: implement
    }

    /**
        Sets the color of the sourde
    */
    override
    void setSource(vec4 color) {
        cairo_set_source_rgba(cr, color.x, color.y, color.z, color.w);
    }

    override
    void setSource(vec3 color) {
        cairo_set_source_rgb(cr, color.x, color.y, color.z);
    }

    override
    void setSource(SbPattern pattern) {
        cairo_set_source(cr, cast(cairo_pattern_t*)pattern.getHandle());
    }

    override
    void setSource(SbCanvas canvas, vec2 offset) {
        cairo_set_source_surface(cr, cast(cairo_surface_t*)canvas.getHandle(), offset.x, offset.y);
    }

    override
    void pushClipRect(recti area) {
        super.pushClipRect(area);

        auto currClip = getCurrentClip();
        cairo_rectangle(cr, currClip.x, currClip.y, currClip.width, currClip.height);
        cairo_clip(cr);
    }

    override
    void popClipRect() {
        super.popClipRect();
        this.applyClipRects();
    }

    override
    void clearClipRects() {
        super.clearClipRects();
        cairo_reset_clip(cr);

        this.applyMask();
    }
}

