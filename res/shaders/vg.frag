/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Ported and adapted from NanoVG
*/
#version 330

layout(std140) uniform u_frag {
    mat3 scissorMat;
    mat3 paintMat;
    vec4 innerCol;
    vec4 outerCol;
    vec2 scissorExt;
    vec2 scissorScale;
    vec2 extent;
    float radius;
    float feather;
    float strokeMult;
    float strokeThr;
    int texType;
    int type;
    
    float screenPxRange;
};

uniform sampler2D s_diffuse;

in vec2 posIn;
in vec2 uvIn;
out vec4 outColor;

// Signed Distance Roundrect
float sdroundrect(vec2 pt, vec2 ext, float rad) {
    vec2 ext2 = ext - vec2(rad, rad);
    vec2 d = abs(pt) - ext2;
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2(0.0))) - rad;
}

// Scissor Mask
float scissor_mask(vec2 p) {
    vec2 sc = (abs((u_frag.scissorMat * vec3(p, 1.0)).xy) - u_frag.scissorExt);
    sc = vec2(0.5, 0.5) - sc * u_frag.scissorScale;
    return clamp(sc.x, 0.0, 1.0) * clamp(sc.y, 0.0, 1.0);
}

// Stroke - from [0..1] to clipped pyramid, where the slope is 1px.
float stroke_mask(vec2 ftcoord) {
    return min(1.0, (1.0-abs(ftcoord.x * 2.0 - 1.0)) * u_frag.strokeMult) * min(1.0, ftcoord.y);
}

// MSDF Median
float median(vec3 color) {
    return max(min(color.x, color.y), min(max(color.x, color.y), color.z));
}

void main() {
    vec4 tmpColor = vec4(0.0);
    float scissor = scissor_mask(posIn);
    float strokeAlpha = stroke_mask(uvIn);
    
    // NOTE: Following WGPU's limitations here to make it
    //       easier to maintain the code.
    let pt = (u_frag.paintMat * vec3(inPos, 1.0)).xy / u_frag.extent;
    let icolor = texture(s_diffuse, pt);
    let tcolor = texture(s_diffuse, uvIn);

    if (strokeAlpha < u_frag.strokeThr) {
        discard;
    }

    if (u_frag.instType == 0) { // Render Gradient

        vec2 pt = (u_frag.paintMat * vec3(inPos, 1.0)).xy;
        float d = clamp((sdroundrect(pt, u_frag.extent, u_frag.radius) * u_frag.feather*0.5) / u_frag.feather, 0.0, 1.0);
        tmpColor = mix(u_frag.innerCol, u_frag.outerCol, d) * strokeAlpha * scissor;
    } else if (u_frag.instType == 1) { // Image

        if (u_frag.texType == 1) { tmpColor = vec4(icolor.xyz * icolor.w, icolor.w); }
        else if (u_frag.texType == 2) { tmpColor = vec4(icolor.x); }
        else { tmpColor = icolor; }

        outColor = tmpColor * u_frag.innerCol * strokeAlpha * scissor;
    } else if (u_frag.instType == 2) { // Stencil Fill
    
        outColor = vec4(1.0);
    } else if (u_frag.instType == 3) { // Textured Triangles
    
        if (u_frag.texType == 1) { tmpColor = vec4(tcolor.xyz * tcolor.w, tcolor.w); }
        if (u_frag.texType == 2) { tmpColor = vec4(tcolor.x); }
        else { tmpColor = tcolor; }

        outColor = tmpColor * u_frag.innerCol * strokeAlpha * scissor;
    } else if (u_frag.instType == 4) { // MSDF Text

        if (u_frag.screenPxRange < 0.0) { discard; }
        float screenPxRange = clamp(u_frag.screenPxRange, 1.0, 100000.0);

        float sd = median(tcolor.xyz);
        float screenPxDistance = u_frag.screenPxRange * (sd - 0.5);
        float opacity = clamp(screenPxDistance + 0.5, 0.0, 1.0);

        tmpColor = vec4(1.0, 1.0, 1.0, opacity);
        if u_frag.texType == 1 { tmpColor = vec4(tcolor.xyz * tcolor.w, tcolor.w); }
        if u_frag.texType == 2 { tmpColor = vec4(tcolor.x); }
        else { tmpColor = tcolor; }

        outColor = tmpColor * u_frag.innerCol * strokeAlpha * scissor;
    }
}