/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.cairo.ctx;
import soba.canvas.ctx;
import soba.canvas.pattern;
import soba.canvas.mask;
import soba.canvas.image;
import soba.canvas.text;
import math = inmath.linalg;
import inmath.linalg : vec2, vec3, vec4, recti, vec2i;
import inmath.math : max, radians, clamp;
import cairo;
import soba.canvas.cairo.mask;
import soba.canvas.cairo;
import numem.all;

class SbCairoContext : SbContext {
@nogc:
private:

    // Cairo primitives
    cairo_t* cr;
    cairo_surface_t* surface;
    cairo_matrix_t matrix;
    
    // Other primitives
    SbBlendOperator op;
    shared_ptr!SbMask currentMask;
    bool hasMask = false;

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
            hasMask = true;
            cairo_append_path(cr, cast(cairo_path_t*)currentMask.getHandle());
            cairo_clip(cr);
        } else {
            hasMask = false;
            this.applyClipRects();
        }
    }

    pragma(inline, true)
    bool isInMaskImpl(vec2 point) {
        return cast(bool)cairo_in_clip(cr, point.x, point.y);
    }

protected:

    override
    void setSourceImpl(vec4 color) {
        if (!hasLock()) return;
        
        cairo_set_source_rgba(cr, color.x, color.y, color.z, color.w);
    }

    override
    void setSourceImpl(vec3 color) {
        if (!hasLock()) return;

        cairo_set_source_rgb(cr, color.x, color.y, color.z);
    }

    override
    void setSourceImpl(SbPattern pattern, vec2 offset) {
        if (!hasLock()) return;

        if (pattern) {
            cairo_set_source(cr, cast(cairo_pattern_t*)pattern.getHandle());
        } else {
            cairo_set_source_rgb(cr, 0, 0, 0);
        }
    }

    override
    void beginTextShape(SbFont font) {
    }

    override
    void endTextShape() {
    }

public:

    /**
        Destructor
    */
    ~this() {
        if(cr) cairo_destroy(cr);
        if(surface) cairo_surface_destroy(surface);

        this.surface = null;
        this.cr = null;
    }

    /**
        Creates context for canvas
    */
    this() {

        // Default in cairo is OVER
        this.op = SbBlendOperator.sourceOver;
    }

    override
    bool begin(SbImage target) {
        bool begun = super.begin(target);

        if (begun) {
            SbImageLock* lock = this.getLock();
            this.surface = cairo_image_surface_create_for_data(
                lock.data,
                target.getFormat().toCairoFormat(),
                lock.width,
                lock.height,
                cast(int)lock.stride
            );
            this.cr = cairo_create(this.surface);
        }
        return begun;
    }

    override
    bool end() {
        if (hasLock()) {
            cairo_surface_finish(surface);
            cairo_surface_destroy(surface);

            cairo_destroy(cr);

            this.surface = null;
            this.cr = null;
        }

        return super.end();
    }

    override
    void clearAll() {
        if (!hasLock()) return;

        this.setSource(vec4(0, 0, 0, 0));
        cairo_paint(cr);
    }

    override
    void* getHandle() {
        return cr;
    }

    override
    SbContextCookie save() {
        if (!hasLock()) return null;

        cairo_save(cr);

        return null;
    }

    override
    void restore(SbContextCookie) {
        if (!hasLock()) return;

        cairo_restore(cr);
    }

    override
    void setFillRule(SbFillRule fill) {
        if (!hasLock()) return;

        final switch(fill) {
            case SbFillRule.evenOdd: cairo_set_fill_rule(cr, cairo_fill_rule_t.CAIRO_FILL_RULE_EVEN_ODD); return;
            case SbFillRule.winding: cairo_set_fill_rule(cr, cairo_fill_rule_t.CAIRO_FILL_RULE_WINDING); return;
        }
    }

    override
    SbFillRule getFillRule() {
        if (!hasLock()) return SbFillRule.evenOdd;

        final switch(cairo_get_fill_rule(cr)) {
            case cairo_fill_rule_t.CAIRO_FILL_RULE_EVEN_ODD: return SbFillRule.evenOdd;
            case cairo_fill_rule_t.CAIRO_FILL_RULE_WINDING: return SbFillRule.winding;
        }
    }

    override
    void setLineCap(SbLineCap cap) {
        if (!hasLock()) return;

        final switch(cap) {
            case SbLineCap.butt: cairo_set_line_cap(cr, cairo_line_cap_t.CAIRO_LINE_CAP_BUTT); return;
            case SbLineCap.square: cairo_set_line_cap(cr, cairo_line_cap_t.CAIRO_LINE_CAP_SQUARE); return;
            case SbLineCap.round: cairo_set_line_cap(cr, cairo_line_cap_t.CAIRO_LINE_CAP_ROUND); return;
        }
    }

    override
    SbLineCap getLineCap() {
        if (!hasLock()) return SbLineCap.butt;

        final switch(cairo_get_line_cap(cr)) {
            case cairo_line_cap_t.CAIRO_LINE_CAP_BUTT: return SbLineCap.butt;
            case cairo_line_cap_t.CAIRO_LINE_CAP_SQUARE: return SbLineCap.square;
            case cairo_line_cap_t.CAIRO_LINE_CAP_ROUND: return SbLineCap.round;
        }
    }

    override
    void setLineJoin(SbLineJoin join) {
        if (!hasLock()) return;

        final switch(join) {
            case SbLineJoin.miter: cairo_set_line_join(cr, cairo_line_join_t.CAIRO_LINE_JOIN_MITER); return;
            case SbLineJoin.bevel: cairo_set_line_join(cr, cairo_line_join_t.CAIRO_LINE_JOIN_BEVEL); return;
            case SbLineJoin.round: cairo_set_line_join(cr, cairo_line_join_t.CAIRO_LINE_JOIN_ROUND); return;
        }
    }

    override
    SbLineJoin getLineJoin() {
        if (!hasLock()) return SbLineJoin.miter;

        final switch(cairo_get_line_join(cr)) {
            case cairo_line_join_t.CAIRO_LINE_JOIN_MITER: return SbLineJoin.miter;
            case cairo_line_join_t.CAIRO_LINE_JOIN_BEVEL: return SbLineJoin.bevel;
            case cairo_line_join_t.CAIRO_LINE_JOIN_ROUND: return SbLineJoin.round;
        } 
    }

    override
    void setBlendOperator(SbBlendOperator op) {
        if (!hasLock()) return;

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
        if (!hasLock()) return;

        cairo_set_line_width(cr, width);
    }

    override
    float getLineWidth(float width) {
        if (!hasLock()) return 1;
        
        return cast(float)cairo_get_line_width(cr);
    }

    override
    void fill() {
        if (!hasLock()) return;
        
        cairo_fill(cr);
    }

    override
    void fillPreserve() {
        if (!hasLock()) return;
        
        cairo_fill_preserve(cr);
    }

    override
    void stroke() {
        if (!hasLock()) return;
        
        cairo_stroke(cr);
    }

    override
    void strokePreserve() {
        if (!hasLock()) return;
        
        cairo_stroke_preserve(cr);
    }

    /**
        Creates a mask for the current path.

        Use setMask to use it.
        Returns null if there's no current path.
    */
    override
    shared_ptr!SbMask fillMask() {
        if (!hasLock()) return (shared_ptr!SbMask).init;
        
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
        if (!hasLock()) return;

        // Clear smart pointer
        if (currentMask.get() !is null) {
            nogc_delete(currentMask);
        }

        this.currentMask = mask;
        this.applyMask();
    }
    
    override
    void clearMask() {
        if (!hasLock()) return;
        
        nogc_delete(currentMask);
        this.applyMask();
    }

    override
    bool isInMask(vec2 point) {
        if (!hasLock()) return false;

        // Convert to screen coordinates
        double dx = point.x, dy = point.y;
        cairo_device_to_user(cr, &dx, &dy);
        point.x = cast(float)dx;
        point.y = cast(float)dy;

        return isInMaskImpl(point);
    }

    override
    bool isInMask(vec2i point) {
        if (!hasLock()) return false;
        
        enum SB_MASK_SEARCH_EPSILON = 0.5;

        // Convert to screen coordinates
        double dx = point.x, dy = point.y;
        cairo_device_to_user(cr, &dx, &dy);
        point.x = cast(int)dx;
        point.y = cast(int)dy;

        return 
            isInMaskImpl(vec2(point.x-SB_MASK_SEARCH_EPSILON, point.y)) ||
            isInMaskImpl(vec2(point.x+SB_MASK_SEARCH_EPSILON, point.y)) ||
            isInMaskImpl(vec2(point.x, point.y-SB_MASK_SEARCH_EPSILON)) ||
            isInMaskImpl(vec2(point.x, point.y+SB_MASK_SEARCH_EPSILON)) ||
            isInMaskImpl(vec2(point.x, point.y));

    }

    override
    bool isMasked() {
        if (!hasLock()) return false;

        return hasMask;
    }

    override
    void clearPath() {
        if (!hasLock()) return;
        
        cairo_new_path(cr);
    }

    override
    void moveTo(vec2 pos) {
        if (!hasLock()) return;
        
        cairo_move_to(cr, pos.x, pos.y);
    }

    override
    void lineTo(vec2 pos) {
        if (!hasLock()) return;
        
        cairo_line_to(cr, pos.x, pos.y);
    }

    override
    void quadTo(vec2 ctrl, vec2 pos) {
        if (!hasLock()) return;
        
        vec2 start = getPathCursorPos();
        cairo_curve_to(
            cr,
            2.0 / 3.0 * ctrl.x + 1.0 / 3.0 * start.x,
            2.0 / 3.0 * ctrl.y + 1.0 / 3.0 * start.y,
            2.0 / 3.0 * ctrl.x + 1.0 / 3.0 * pos.x,
            2.0 / 3.0 * ctrl.y + 1.0 / 3.0 * pos.y,
            pos.x,
            pos.y
        );
    }

    override
    void cubicTo(vec2 ctrl1, vec2 ctrl2, vec2 pos) {
        if (!hasLock()) return;
        
        cairo_curve_to(cr, ctrl1.x, ctrl1.y, ctrl2.x, ctrl2.y, pos.x, pos.y);
    }

    override
    void arcTo(vec2 point) {
        if (!hasLock()) return;
        
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
        if (!hasLock()) return;
        
        cairo_rectangle(cr, r.x, r.y, r.width, r.height);
    }

    override
    void roundRect(math.rect r, float borderRadius) {
        this.roundRect(r, borderRadius, borderRadius, borderRadius, borderRadius);
    }

    override
    void roundRect(math.rect r, float borderRadiusTL, float borderRadiusTR, float borderRadiusBL, float borderRadiusBR) {
        if (!hasLock()) return;
        
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
        if (!hasLock()) return;
        
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
        if (!hasLock()) return;
        
        cairo_close_path(cr);
    }

    override
    void translate(vec2 pos) {
        if (!hasLock()) return;
        
        cairo_translate(cr, pos.x, pos.y);
    }

    override
    void rotate(float radians) {
        if (!hasLock()) return;
        
        cairo_rotate(cr, radians);
    }

    override
    void scale(vec2 scale) {
        if (!hasLock()) return;
        
        cairo_scale(cr, scale.x, scale.y);
    }

    override
    void resetTransform() {
        if (!hasLock()) return;
        
        cairo_identity_matrix(cr);
    }

    override
    vec2 getPathCursorPos() {
        if (!hasLock()) return vec2.init;
        
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

    override
    void pushClipRect(recti area) {
        if (!hasLock()) return;
        
        super.pushClipRect(area);

        auto currClip = getCurrentClip();
        cairo_rectangle(cr, currClip.x, currClip.y, currClip.width, currClip.height);
        cairo_clip(cr);
    }

    override
    void popClipRect() {
        if (!hasLock()) return;
        
        super.popClipRect();
        this.applyClipRects();
    }

    override
    void clearClipRects() {
        if (!hasLock()) return;
        
        super.clearClipRects();
        cairo_reset_clip(cr);

        this.applyMask();
    }
}

