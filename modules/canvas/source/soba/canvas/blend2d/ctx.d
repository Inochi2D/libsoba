/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna Nielsen
*/

module soba.canvas.blend2d.ctx;
import soba.canvas.ctx;
import soba.canvas.image;
import soba.canvas.pattern;
import soba.canvas.mask;
import math = inmath.linalg;
import inmath.linalg : vec2, vec3, vec4, recti, vec2i;
import inmath.math : max, radians, clamp;
import blend2d;
import soba.canvas.blend2d.mask;
import soba.canvas.blend2d;
import numem.all;
import soba.canvas.text;

class SbBLContext : SbContext {
@nogc:
private:
    BLContext ctx;
    BLPath path;
    SbBlendOperator op;
    BLImage targetImage;

    void applyClipRects() {
        blContextRestoreClipping(&ctx);

        if (getClipRectsActive() > 0) {
            auto currClip = getCurrentClip();
            blContextClipToRectI(&ctx, &currClip);
        }
    }

    void applyMask() {
        blContextRestoreClipping(&ctx);

        // if (currentMask.get() && currentMask.getParent() is this) {
        //     hasMask = true;
        //     cairo_append_&path(cr, cast(cairo_&path_t*)currentMask.getHandle());
        //     cairo_clip(cr);
        // } else {
        //     hasMask = false;
            this.applyClipRects();
        // }
    }

    pragma(inline, true)
    bool isInMaskImpl(vec2 point) {
        recti r = getCurrentClip();
        return cast(bool)r.intersects(point);
    }

protected:

    override
    void setSourceImpl(vec4 color) {
        BLRgba rgba = BLRgba(color.x, color.y, color.z, color.w);
        blContextSetFillStyleRgba(&ctx, &rgba);
        blContextSetStrokeStyleRgba(&ctx, &rgba);
    }

    override
    void setSourceImpl(vec3 color) {
        BLRgba rgba = BLRgba(color.x, color.y, color.z, 1);
        blContextSetFillStyleRgba(&ctx, &rgba);
        blContextSetStrokeStyleRgba(&ctx, &rgba);
    }

    override
    void setSourceImpl(SbPattern pattern, vec2 offset) {
        blContextSetFillStyle(&ctx, pattern.getHandle());
        blContextSetStrokeStyle(&ctx, pattern.getHandle());
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
        blImageDestroy(&targetImage);
        blPathDestroy(&path);
        blContextDestroy(&ctx);
    }

    /**
        Creates context for canvas
    */
    this() {
        BLContextCreateInfo cInfo;
        cInfo.reset();

        // Target rendering
        blContextInit(&ctx);
        blImageInit(&targetImage);
        blPathInit(&path);

        // Default in cairo is OVER
        this.op = SbBlendOperator.sourceOver;
    }

    override
    bool begin(SbImage target) {
        bool begun = super.begin(target);
        if (begun) {
            SbImageLock* lock = this.getLock();
            blImageCreateFromData(
                &targetImage,
                lock.width, 
                lock.height, 
                target.getFormat().toBLFormat(),
                lock.data,
                lock.stride,
                BLDataAccessFlags.BL_DATA_ACCESS_RW,
                null,
                null
            );
            blContextBegin(&ctx, &targetImage, null);
        }

        return begun;
    }

    override
    bool end() {
        if (hasLock()) {
            
            // End rendering
            blContextEnd(&ctx);
            blContextFlush(&ctx, BLContextFlushFlags.BL_CONTEXT_FLUSH_SYNC);
            blImageReset(&targetImage);
        }

        return super.end();
    }

    override
    void clearAll() {
        if (!hasLock()) return;
        blContextClearAll(&ctx);
    }

    override
    void* getHandle() {
        return &ctx;
    }

    override
    SbContextCookie save() {
        if (!hasLock()) return null;

        // TODO: cookies in Blend2D are stack allocated, figure out a good way to handle that.
        blContextSave(&ctx, null);
        return null;
    }

    override
    void restore(SbContextCookie) {
        if (!hasLock()) return;

        blContextRestore(&ctx, null);
    }

    override
    void setFillRule(SbFillRule fill) {
        final switch(fill) {
            case SbFillRule.evenOdd: blContextSetFillRule(&ctx, BLFillRule.BL_FILL_RULE_EVEN_ODD); return;
            case SbFillRule.winding: blContextSetFillRule(&ctx, BLFillRule.BL_FILL_RULE_NON_ZERO); return;
        }
    }

    override
    SbFillRule getFillRule() {
        final switch(blContextGetFillRule(&ctx)) {
            case BLFillRule.BL_FILL_RULE_EVEN_ODD: return SbFillRule.evenOdd;
            case BLFillRule.BL_FILL_RULE_NON_ZERO: return SbFillRule.winding;
        }
    }

    override
    void setLineCap(SbLineCap cap) {
        final switch(cap) {
            case SbLineCap.butt: blContextSetStrokeCaps(&ctx, BLStrokeCap.BL_STROKE_CAP_BUTT); return;
            case SbLineCap.square: blContextSetStrokeCaps(&ctx, BLStrokeCap.BL_STROKE_CAP_SQUARE); return;
            case SbLineCap.round: blContextSetStrokeCaps(&ctx, BLStrokeCap.BL_STROKE_CAP_ROUND); return;
        }
    }

    override
    SbLineCap getLineCap() {

        final switch(blContextGetStrokeCap(&ctx, BLStrokeCapPosition.BL_STROKE_CAP_POSITION_START)) {
            case BLStrokeCap.BL_STROKE_CAP_BUTT: return SbLineCap.butt;
            case BLStrokeCap.BL_STROKE_CAP_SQUARE: return SbLineCap.square;
            case BLStrokeCap.BL_STROKE_CAP_ROUND_REV:
            case BLStrokeCap.BL_STROKE_CAP_TRIANGLE:
            case BLStrokeCap.BL_STROKE_CAP_TRIANGLE_REV:
            case BLStrokeCap.BL_STROKE_CAP_ROUND: return SbLineCap.round;
        }
    }

    override
    void setLineJoin(SbLineJoin join) {
        final switch(join) {
            case SbLineJoin.miter: blContextSetStrokeJoin(&ctx, BLStrokeJoin.BL_STROKE_JOIN_MITER_CLIP); return;
            case SbLineJoin.bevel: blContextSetStrokeJoin(&ctx, BLStrokeJoin.BL_STROKE_JOIN_BEVEL); return;
            case SbLineJoin.round: blContextSetStrokeJoin(&ctx, BLStrokeJoin.BL_STROKE_JOIN_ROUND); return;
        }
    }

    override
    SbLineJoin getLineJoin() {
        final switch(blContextGetStrokeJoin(&ctx)) {
            case BLStrokeJoin.BL_STROKE_JOIN_MITER_ROUND:
            case BLStrokeJoin.BL_STROKE_JOIN_MITER_BEVEL:
            case BLStrokeJoin.BL_STROKE_JOIN_MITER_CLIP: return SbLineJoin.miter;
            case BLStrokeJoin.BL_STROKE_JOIN_BEVEL: return SbLineJoin.bevel;
            case BLStrokeJoin.BL_STROKE_JOIN_ROUND: return SbLineJoin.round;
        }
    }

    override
    void setBlendOperator(SbBlendOperator op) {

        this.op = op;

        //TODO: make this a LUT
        final switch(op) {
            case SbBlendOperator.clear:         blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_CLEAR); return;
            case SbBlendOperator.source:        blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_SRC_COPY); return;
            case SbBlendOperator.sourceOver:    blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_SRC_OVER); return;
            case SbBlendOperator.sourceIn:      blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_SRC_IN); return;
            case SbBlendOperator.sourceOut:     blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_SRC_OUT); return;
            case SbBlendOperator.sourceAtop:    blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_SRC_ATOP); return;
            case SbBlendOperator.dest:          blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_DST_COPY); return;
            case SbBlendOperator.destOver:      blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_DST_OVER); return;
            case SbBlendOperator.destIn:        blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_DST_IN); return;
            case SbBlendOperator.destOut:       blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_DST_OUT); return;
            case SbBlendOperator.destAtop:      blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_DST_ATOP); return;
            case SbBlendOperator.xor:           blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_XOR); return;
            case SbBlendOperator.add:           blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_PLUS); return;
            case SbBlendOperator.saturate:      blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_MINUS); return;
            case SbBlendOperator.multiply:      blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_MULTIPLY); return;
            case SbBlendOperator.screen:        blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_SCREEN); return;
            case SbBlendOperator.overlay:       blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_OVERLAY); return;
            case SbBlendOperator.darken:        blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_DARKEN); return;
            case SbBlendOperator.lighten:       blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_LIGHTEN); return;
            case SbBlendOperator.colorDodge:    blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_COLOR_DODGE); return;
            case SbBlendOperator.colorBurn:     blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_COLOR_BURN); return;
            case SbBlendOperator.hardLight:     blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_HARD_LIGHT); return;
            case SbBlendOperator.softLight:     blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_SOFT_LIGHT); return;
            case SbBlendOperator.difference:    blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_DIFFERENCE); return;
            case SbBlendOperator.exclusion:     blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_EXCLUSION); return;
            case SbBlendOperator.hslHue:        blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_SRC_COPY); return;
            case SbBlendOperator.hslSaturation: blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_SRC_COPY); return;
            case SbBlendOperator.hslColor:      blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_SRC_COPY); return;
            case SbBlendOperator.hslLuminosity: blContextSetCompOp(&ctx, BLCompOp.BL_COMP_OP_SRC_COPY); return;
        }
    }

    override
    SbBlendOperator getBlendOperator() {
        return this.op;
    }

    override
    void setLineWidth(float width) {
        blContextSetStrokeWidth(&ctx, width);
    }

    override
    float getLineWidth(float width) {
        return cast(float)blContextGetStrokeWidth(&ctx);
    }

    override
    void fill() {
        blContextFillGeometry(&ctx, BLGeometryType.BL_GEOMETRY_TYPE_PATH, &path);
        blPathClear(&path);
    }

    override
    void fillPreserve() {
        blContextFillGeometry(&ctx, BLGeometryType.BL_GEOMETRY_TYPE_PATH, &path);
    }

    override
    void stroke() {
        blContextStrokeGeometry(&ctx, BLGeometryType.BL_GEOMETRY_TYPE_PATH, &path);
        blPathClear(&path);
    }

    override
    void strokePreserve() {
        blContextStrokeGeometry(&ctx, BLGeometryType.BL_GEOMETRY_TYPE_PATH, &path);
    }

    /**
        Creates a mask for the current &path.

        Use setMask to use it.
        Returns null if there's no current &path.
    */
    override
    shared_ptr!SbMask fillMask() {
        // cairo_&path_t* &path = cairo_copy_&path(cr);

        // if (&path.num_data == 0) {
        //     cairo_&path_destroy(&path);

        //     shared_ptr!SbMask mask;
        //     return mask;
        // }

        //return shared_ptr!SbMask.fromPtr(nogc_new!SbCairoMask(getTarget().getFormat(), this, &path));

        return (shared_ptr!SbMask).init;
    }

    override
    void setMask(shared_ptr!SbMask mask) {

        // // Clear smart pointer
        // if (currentMask.get() !is null) {
        //     nogc_delete(currentMask);
        // }

        // this.currentMask = mask;
        // this.applyMask();
    }

    override
    void clearMask() {
        // nogc_delete(currentMask);
        // this.applyMask();
    }

    override
    bool isInMask(vec2 point) {

        // // Convert to screen coordinates
        // double dx = point.x, dy = point.y;
        // cairo_device_to_user(cr, &dx, &dy);
        // point.x = cast(float)dx;
        // point.y = cast(float)dy;

        // return isInMaskImpl(point);
        return false;
    }

    override
    bool isInMask(vec2i point) {
        // enum SB_MASK_SEARCH_EPSILON = 0.5;

        // // Convert to screen coordinates
        // double dx = point.x, dy = point.y;
        // cairo_device_to_user(cr, &dx, &dy);
        // point.x = cast(int)dx;
        // point.y = cast(int)dy;

        // return
        //     isInMaskImpl(vec2(point.x-SB_MASK_SEARCH_EPSILON, point.y)) ||
        //     isInMaskImpl(vec2(point.x+SB_MASK_SEARCH_EPSILON, point.y)) ||
        //     isInMaskImpl(vec2(point.x, point.y-SB_MASK_SEARCH_EPSILON)) ||
        //     isInMaskImpl(vec2(point.x, point.y+SB_MASK_SEARCH_EPSILON)) ||
        //     isInMaskImpl(vec2(point.x, point.y));

        return false;
    }

    override
    bool isMasked() {
        return hasMask;
    }

    override
    void clearPath() {
        blPathClear(&path);
    }

    override
    void moveTo(vec2 pos) {
        blPathMoveTo(&path, pos.x, pos.y);
    }

    override
    void lineTo(vec2 pos) {
        blPathLineTo(&path, pos.x, pos.y);
    }

    override
    void quadTo(vec2 ctrl, vec2 pos) {
        blPathQuadTo(&path, ctrl.x, ctrl.y, pos.x, pos.y);
    }

    override
    void cubicTo(vec2 ctrl1, vec2 ctrl2, vec2 pos) {
        blPathCubicTo(&path, ctrl1.x, ctrl1.y, ctrl2.x, ctrl2.y, pos.x, pos.y);
    }

    override
    void arcTo(vec2 point) {
        BLPoint p;
        blPathGetLastVertex(&path, &p);
        blPathArcQuadrantTo(&path, p.x, p.y, point.x, point.y);
    }

    override
    void rect(math.rect r) {
        BLRect rx = BLRect(r.x, r.y, r.width, r.height);
        blPathAddRectD(&path, &rx, BLGeometryDirection.BL_GEOMETRY_DIRECTION_CW);
    }

    override
    void roundRect(math.rect r, float borderRadius) {
        this.roundRect(r, borderRadius, borderRadius, borderRadius, borderRadius);
    }

    override
    void roundRect(math.rect r, float borderRadiusTL, float borderRadiusTR, float borderRadiusBL, float borderRadiusBR) {
        blPathMoveTo(&path, r.left+borderRadiusTL, r.top);

        // Top-Right
        blPathLineTo(&path, r.right-borderRadiusTR, r.top);
        blPathArcQuadrantTo(&path, r.right, r.top, r.right, r.top+borderRadiusTR);

        // Bottom-Right
        blPathLineTo(&path, r.right, r.bottom-borderRadiusBR);
        blPathArcQuadrantTo(&path, r.right, r.bottom, r.right-borderRadiusBR, r.bottom);

        // Bottom-Left
        blPathLineTo(&path, r.left+borderRadiusBL, r.bottom);
        blPathArcQuadrantTo(&path, r.left, r.bottom, r.left, r.bottom-borderRadiusBL);

        // Top-Left
        blPathLineTo(&path, r.left, r.top+borderRadiusTL);
        blPathArcQuadrantTo(&path, r.left, r.top, r.left+borderRadiusTL, r.top);

        blPathClose(&path);
    }

    override
    void squircle(math.rect r, float elasticity) {
        elasticity = clamp(elasticity, 0, 1);

        float halfW = (r.width/2);
        float halfH = (r.height/2);

        float elasticW = halfW*elasticity;
        float elasticH = halfH*elasticity;

        vec2 rel = vec2(r.left+halfW, r.top);

        // Begin
        blPathMoveTo(&path, rel.x, rel.y);

        // Right center
        blPathCubicTo(&path, rel.x+elasticW, rel.y+0, rel.x+halfW, rel.y+0, rel.x+halfW, rel.y+halfH);
        rel = getPathCursorPos();

        // Bottom center
        blPathCubicTo(&path, rel.x+0, rel.y+elasticH, rel.x+0, rel.y+halfH, rel.x-halfW, rel.y+halfH);
        rel = getPathCursorPos();

        // Left center
        blPathCubicTo(&path, rel.x-elasticW, rel.y+0, rel.x-halfW, rel.y+0, rel.x-halfW, rel.y-halfH);
        rel = getPathCursorPos();

        // Top center
        blPathCubicTo(&path, rel.x+0, rel.y-elasticH, rel.x+0, rel.y-halfH, rel.x+halfW, rel.y-halfH);

        // Finalize
        blPathClose(&path);
    }

    override
    void closePath() {
        blPathClose(&path);
    }

    override
    void translate(vec2 pos) {
        vec2d dpos = pos;
        blContextApplyTransformOp(&ctx, BLTransformOp.BL_TRANSFORM_OP_TRANSLATE, &dpos);
    }

    override
    void rotate(float radians) {
        double rads = radians;
        blContextApplyTransformOp(&ctx, BLTransformOp.BL_TRANSFORM_OP_ROTATE, &rads);
    }

    override
    void scale(vec2 scale) {
        vec2d dscale = scale;
        blContextApplyTransformOp(&ctx, BLTransformOp.BL_TRANSFORM_OP_SCALE, &dscale);
    }

    override
    void resetTransform() {
        blContextApplyTransformOp(&ctx, BLTransformOp.BL_TRANSFORM_OP_RESET, null);
    }

    override
    vec2 getPathCursorPos() {
        vec2 pos = vec2(0, 0);
        if (blPathGetSize(&path) > 0) {
            BLPoint p;
            blPathGetLastVertex(&path, &p);
            pos = vec2(p.x, p.y);
        }

        return pos;
    }

    override
    math.rect getPathExtents() {
        BLBox box;
        blPathGetBoundingBox(&path, &box);
        return math.rect(box.x0, box.y0, box.x1-box.x0, box.y1-box.y0);
    }

    override
    void pushClipRect(recti area) {
        super.pushClipRect(area);

        auto currClip = getCurrentClip();
        blContextClipToRectI(&ctx, &currClip);
    }

    override
    void popClipRect() {
        super.popClipRect();
        this.applyClipRects();
    }

    override
    void clearClipRects() {
        super.clearClipRects();
        blContextRestoreClipping(&ctx);

        this.applyMask();
    }
}

