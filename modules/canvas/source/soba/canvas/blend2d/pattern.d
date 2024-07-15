/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.blend2d.pattern;
import soba.canvas.pattern;
import soba.canvas.image;
import soba.canvas.canvas;
import blend2d;
import inmath.linalg;
import numem.all;

alias mat3d = Matrix!(double, 3, 3);

class SbBLGradient : SbGradient {
@nogc:
private:
    BLGradient gradient;

public:
    ~this() {
        blGradientDestroy(&gradient);
    }

    this(SbGradientType type) {
        super(type);
    }
    
    /**
        Gets the sampling mode
    */
    override
    SbPatternSampleMode getSampleMode() {
        switch(blGradientGetExtendMode(&gradient)) {
            case BLExtendMode.BL_EXTEND_MODE_REPEAT: return SbPatternSampleMode.repeat;
            case BLExtendMode.BL_EXTEND_MODE_REFLECT: return SbPatternSampleMode.mirror;
            case BLExtendMode.BL_EXTEND_MODE_PAD: return SbPatternSampleMode.borderClamp;
            default: return SbPatternSampleMode.repeat;
        }
    }

    /**
        Sets the sampling mode
    */
    override
    void setSampleMode(SbPatternSampleMode mode) {
        final switch(mode) {
            case SbPatternSampleMode.none:          blGradientSetExtendMode(&gradient, BLExtendMode.BL_EXTEND_MODE_PAD); return;
            case SbPatternSampleMode.repeat:        blGradientSetExtendMode(&gradient, BLExtendMode.BL_EXTEND_MODE_REPEAT); return;
            case SbPatternSampleMode.mirror:        blGradientSetExtendMode(&gradient, BLExtendMode.BL_EXTEND_MODE_REFLECT); return;
            case SbPatternSampleMode.borderClamp:   blGradientSetExtendMode(&gradient, BLExtendMode.BL_EXTEND_MODE_PAD); return;
        }
    }

    /**
        Gets the filtering mode
    */
    override
    SbPatternFilter getFiltering() {

        // Blend2D only does bilinear filtering atm.
        return SbPatternFilter.bilinear;
    }

    /**
        Sets the filtering mode
    */
    override
    void setFiltering(SbPatternFilter filter) {

        // Blend2D only does bilinear filtering atm.
    }

    /**
        Gets the dithering mode
    */
    override
    SbPatternDither getDither() {
        return SbPatternDither.none;
    }

    /**
        Sets the dithering mode
    */
    override
    void setDither(SbPatternDither filter) { }

    /**
        Gets the matrix
    */
    override
    mat3 getMatrix() {
        double[6] mat;
        blGradientGetTransform(&gradient, cast(BLMatrix2D*)&mat);

        return mat3(
            mat[0], mat[2], mat[4],
            mat[1], mat[3], mat[5],
            0,         0,         1.0,
        );
    }

    /**
        Sets the matrix
    */
    override
    void setMatrix(mat3 matrix) {

        double[6] mat = [
            matrix[0][0],
            matrix[0][1],
            matrix[1][0],
            matrix[1][1],
            matrix[0][2],
            matrix[1][2]
        ];

        blGradientApplyTransformOp(&gradient, BLTransformOp.BL_TRANSFORM_OP_ASSIGN, &mat);
    }

    /**
        Clears the pattern's matrix
    */
    override
    void clearMatrix() {
        blGradientApplyTransformOp(&gradient, BLTransformOp.BL_TRANSFORM_OP_RESET, null);
    }

    /**
        Returns the backing handle
    */
    override
    void* getHandle() {
        return &gradient;
    }

    static
    SbBLGradient linearGradient(vec2 start, vec2 end) {
        SbBLGradient grad = nogc_new!SbBLGradient(SbGradientType.linear);
        BLLinearGradientValues values;
        values.x0 = start.x;
        values.y0 = start.y;
        values.x1 = end.x;
        values.y1 = end.y;

        blGradientInitAs(cast(BLGradient*)grad.getHandle(), BLGradientType.BL_GRADIENT_TYPE_LINEAR, &values, BLExtendMode.BL_EXTEND_MODE_PAD, null, 0, null);
        return grad;
    }

    static
    SbBLGradient radialGradient(vec2 inner, float innerRadius, vec2 outer, float outerRadius) {
        SbBLGradient grad = nogc_new!SbBLGradient(SbGradientType.linear);

        BLRadialGradientValues values;
        values.x0 = inner.x;
        values.y0 = inner.y;
        values.x1 = outer.x;
        values.y1 = outer.y;
        values.r0 = innerRadius;
        values.r1 = outerRadius;

        blGradientInitAs(cast(BLGradient*)grad.getHandle(), BLGradientType.BL_GRADIENT_TYPE_RADIAL, &values, BLExtendMode.BL_EXTEND_MODE_PAD, null, 0, null);
        return grad;
    }


    override
    void addStop(float offset, vec4 color) {
        union rgbc {
            ubyte[4] b;
            uint argb32;
        }
        rgbc conv;
        conv.b[2] = cast(ubyte)(255.0/color.x);
        conv.b[1] = cast(ubyte)(255.0/color.y);
        conv.b[0] = cast(ubyte)(255.0/color.z);
        conv.b[3] = cast(ubyte)(255.0/color.w);

        blGradientAddStopRgba32(&gradient, offset, conv.argb32);
    }


    override
    void addStop(float offset, vec3 color) {
        this.addStop(offset, vec4(color, 1));
    }

    override
    uint getStopCount() {
        return cast(uint)blGradientGetSize(&gradient);
    }
}


class SbBLImagePattern : SbImagePattern {
@nogc:
private:
    BLImage img;
    BLImageData data;
    BLPattern pattern;
    
    BLFormat getBLFormat() {
        final switch(this.getImage().getFormat()) {
            case SbImageFormat.None:    return BLFormat.BL_FORMAT_NONE;
            case SbImageFormat.A8:      return BLFormat.BL_FORMAT_A8;
            case SbImageFormat.RGB:     return BLFormat.BL_FORMAT_XRGB32;
            case SbImageFormat.RGBA:    return BLFormat.BL_FORMAT_PRGB32;
        }
    }


public:

    ~this() {
        if (img.pixelData) {
            blImageDestroy(&img);
            blPatternDestroy(&pattern);
        }
    }

    this(SbImage image) {
        super(image);
        blImageInitAs(
            &img, 
            image.getWidth(), 
            image.getHeight(), 
            this.getBLFormat()
        );
        blImageMakeMutable(&img, &data);
        blPatternInitAs(&pattern, &img, null, BLExtendMode.BL_EXTEND_MODE_PAD, null);

        this.refresh();
    }

    override
    void refresh() {
        ubyte[] dataSlice = this.getImage().getData();

        // Copy to surface
        auto pdata = cast(ubyte*)data.pixelData;
        pdata[0..dataSlice.length] = dataSlice[0..$];
    }
    
    /**
        Gets the sampling mode
    */
    override
    SbPatternSampleMode getSampleMode() {
        switch(blPatternGetExtendMode(&pattern)) {
            case BLExtendMode.BL_EXTEND_MODE_REPEAT: return SbPatternSampleMode.repeat;
            case BLExtendMode.BL_EXTEND_MODE_REFLECT: return SbPatternSampleMode.mirror;
            case BLExtendMode.BL_EXTEND_MODE_PAD: return SbPatternSampleMode.borderClamp;
            default: return SbPatternSampleMode.repeat;
        }
    }

    /**
        Sets the sampling mode
    */
    override
    void setSampleMode(SbPatternSampleMode mode) {
        final switch(mode) {
            case SbPatternSampleMode.none:          blPatternSetExtendMode(&pattern, BLExtendMode.BL_EXTEND_MODE_PAD); return;
            case SbPatternSampleMode.repeat:        blPatternSetExtendMode(&pattern, BLExtendMode.BL_EXTEND_MODE_REPEAT); return;
            case SbPatternSampleMode.mirror:        blPatternSetExtendMode(&pattern, BLExtendMode.BL_EXTEND_MODE_REFLECT); return;
            case SbPatternSampleMode.borderClamp:   blPatternSetExtendMode(&pattern, BLExtendMode.BL_EXTEND_MODE_PAD); return;
        }
    }

    /**
        Gets the filtering mode
    */
    override
    SbPatternFilter getFiltering() {

        // Blend2D only does bilinear filtering atm.
        return SbPatternFilter.bilinear;
    }

    /**
        Sets the filtering mode
    */
    override
    void setFiltering(SbPatternFilter filter) {

        // Blend2D only does bilinear filtering atm.
    }

    /**
        Gets the dithering mode
    */
    override
    SbPatternDither getDither() {
        return SbPatternDither.none;
    }

    /**
        Sets the dithering mode
    */
    override
    void setDither(SbPatternDither filter) { }

    /**
        Gets the matrix
    */
    override
    mat3 getMatrix() {
        double[6] mat;
        blPatternGetTransform(&pattern, cast(BLMatrix2D*)&mat);

        return mat3(
            mat[0], mat[2], mat[4],
            mat[1], mat[3], mat[5],
            0,         0,         1.0,
        );
    }

    /**
        Sets the matrix
    */
    override
    void setMatrix(mat3 matrix) {

        double[6] mat = [
            matrix[0][0],
            matrix[0][1],
            matrix[1][0],
            matrix[1][1],
            matrix[0][2],
            matrix[1][2]
        ];

        blPatternApplyTransformOp(&pattern, BLTransformOp.BL_TRANSFORM_OP_ASSIGN, &mat);
    }

    /**
        Clears the pattern's matrix
    */
    override
    void clearMatrix() {
        blPatternApplyTransformOp(&pattern, BLTransformOp.BL_TRANSFORM_OP_RESET, null);
    }

    /**
        Returns the backing handle
    */
    override
    void* getHandle() {
        return &pattern;
    }
}

