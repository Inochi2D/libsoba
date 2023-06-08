/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Ported and adapted from NanoVG
*/

//
// Vertex Part
//

struct vtxin {
    @location(0) position: vec2<f32>,
    @location(1) uvs: vec2<f32>,
};

struct vtxout {
    @builtin(position) pos: vec4<f32>,
    @location(1) uvs: vec2<f32>,
}

@vertex
fn vs_main(in: vtxin) -> vtxout {
    var out: vtxout;
    out.pos = vec4<f32>(in.position, 0.0, 1.0);
    out.uvs = in.uvs;
    return out;
}

//
// Fragment Part
//

struct frag {
    scissorMat:     mat3x3<f32>,
    paintMat:       mat3x3<f32>,
    innerCol:         vec4<f32>,
    outerCol:         vec4<f32>,
    scissorExt:       vec2<f32>,
    scissorScale:     vec2<f32>,
    extent:           vec2<f32>,
    radius:                 f32,
    feather:                f32,
    strokeMult:             f32,
    strokeThr:              f32,
    texType:                i32,
    instType:               i32,
    
    screenPxRange:          f32,
}

@group(1) @binding(0)
var t_diffuse: texture_2d<f32>;

@group(1) @binding(1)
var s_diffuse: sampler;

@group(1) @binding(2)
var<uniform> u_frag: frag;

// Signed Distance Roundrect
fn sdroundrect(pt: vec2<f32>, ext: vec2<f32>, rad: f32) -> f32 {
    let ext2 = ext - vec2<f32>(rad, rad);
    let d = abs(pt) - ext2;
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2<f32>(0.0))) - rad;
}

// Scissor Mask
fn scissor_mask(p: vec2<f32>) -> f32 {
    var sc = (abs((u_frag.scissorMat * vec3<f32>(p, 1.0)).xy) - u_frag.scissorExt);
    sc = vec2<f32>(0.5, 0.5) - sc * u_frag.scissorScale;
    return clamp(sc.x, 0.0, 1.0) * clamp(sc.y, 0.0, 1.0);
}

// Stroke - from [0..1] to clipped pyramid, where the slope is 1px.
fn stroke_mask(ftcoord: vec2<f32>) -> f32 {
    return min(1.0, (1.0-abs(ftcoord.x * 2.0 - 1.0)) * u_frag.strokeMult) * min(1.0, ftcoord.y);
}

// MSDF Median
fn median(color: vec3<f32>) -> f32 {
    return max(min(color.x, color.y), min(max(color.x, color.y), color.z));
}

@fragment
fn fs_main(in: vtxout) -> @location(0) vec4<f32> {
    var outColor = vec4<f32>(0.0);
    let scissor = scissor_mask(in.pos.xy);
    let strokeAlpha = stroke_mask(in.uvs);

    // Because WGPU is the worst creation in the universe
    // I have to sample the textures here or naga will strangle me
    // and burn my house down
    let pt = (u_frag.paintMat * vec3<f32>(in.pos.xy, 1.0)).xy / u_frag.extent;
    let icolor = textureSample(t_diffuse, s_diffuse, pt);
    let tcolor = textureSample(t_diffuse, s_diffuse, in.uvs);

    // Discard stroke if under threshold
    if strokeAlpha < u_frag.strokeThr {
        discard;
    }

    if u_frag.instType == 0 { // Render Gradient

        let pt = (u_frag.paintMat * vec3<f32>(in.pos.xy, 1.0)).xy;
        let d = clamp((sdroundrect(pt, u_frag.extent, u_frag.radius) * u_frag.feather*0.5) / u_frag.feather, 0.0, 1.0);
        outColor = mix(u_frag.innerCol, u_frag.outerCol, d);
        outColor *= strokeAlpha * scissor;
    } else if u_frag.instType == 1 { // Image
        
        if u_frag.texType == 1 { outColor = vec4<f32>(icolor.xyz * icolor.w, icolor.w); }
        else if u_frag.texType == 2 { outColor = vec4<f32>(icolor.x); }
        else { outColor = icolor; }

        outColor *= u_frag.innerCol;
        outColor *= strokeAlpha * scissor;
    } else if u_frag.instType == 2 { // Stencil Fill
        
        outColor = vec4<f32>(1.0, 1.0, 1.0, 1.0);
    } else if u_frag.instType == 3 { // Textured Triangles

        if u_frag.texType == 1 { outColor = vec4<f32>(tcolor.xyz * tcolor.w, tcolor.w); }
        if u_frag.texType == 2 { outColor = vec4<f32>(tcolor.x); }
        else { outColor = tcolor; }

        outColor *= u_frag.innerCol;
        outColor *= strokeAlpha * scissor;
    } else if u_frag.instType == 4 { // MSDF Text

        if (u_frag.screenPxRange < 0.0) { discard; }
        let screenPxRange = clamp(u_frag.screenPxRange, 1.0, 100000.0);

        let sd = median(tcolor.xyz);
        let screenPxDistance = u_frag.screenPxRange * (sd - 0.5);
        let opacity = clamp(screenPxDistance + 0.5, 0.0, 1.0);

        outColor = vec4<f32>(1.0, 1.0, 1.0, opacity);
        if u_frag.texType == 1 { outColor = vec4<f32>(tcolor.xyz * tcolor.w, tcolor.w); }
        if u_frag.texType == 2 { outColor = vec4<f32>(tcolor.x); }
        else { outColor = tcolor; }

        outColor *= u_frag.innerCol;
        outColor *= strokeAlpha * scissor;
    }

    // Return resulting color
    return outColor;
}