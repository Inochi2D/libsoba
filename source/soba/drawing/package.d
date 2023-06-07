/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
    
    Drawing routines for UI rendering
*/
module soba.drawing;
// import soba.core.gpu;

// import bindbc.wgpu;
// import inmath;

// private {
//     struct SbDrawVert {
//         vec2 position;
//         vec2 uv;
//         vec4 color;
//     }

//     enum SbPathMode {
//         Line,
//         Filled
//     }

//     struct SbDrawPath {
//         SbPathMode mode;
//         rect clipRect;
//         uint pathStart;
//         uint pathLength;
//         SbGFXTextureView texture;
//     }

//     struct SbDrawCtx {
//         // Base Primitives
//         SbDrawVert[ushort.max]   verts;
//         ushort    [ushort.max]   idxs;
//         SbDrawPath[ushort.max]   paths;
//         size_t pathOffset;
//         size_t vertOffset;
//         size_t idxOffset;
        
//         // Buffers
//         // SbGFXBuffer!SbDrawVert vtxBuffer;
//         // SbGFXBuffer!uint idxBuffer;
//         SbGFXPipeline filledTexture;
//         SbGFXPipeline line;
//         SbGFXPipeline filedShape;

//         void addPathSegment(vec2 position, vec4 color, vec2 uv = vec2.init) {
//             verts[vertOffset++] = SbDrawVert(
//                 position,
//                 uv,
//                 color
//             );
//         }


//         void render(ref SbGFXEncoder encoder, ref SbGFXSurface surface) {
//             encoder.beginFrame();
//             encoder.begin([surface], false, true);

//                 // Bind our buffers
//                 // encoder.setVertexBuffer(vtxBuffer);
//                 // encoder.setIndexBuffer(idxBuffer);

//                 // Iterate every path
//                 foreach(pid; 0..pathOffset) {
                    
//                     // Switch rendering pipeline based on rendering parameters
//                     // if (path.texture) encoder.setPipeline(filledTexture);
//                     // else {
//                     //     if (path.mode == SbPathMode.Line) encoder.setPipeline(line);
//                     //     else encoder.setPipeline(filedShape);
//                     // }

//                     auto path = paths[pid];
//                     encoder.setScissor(path.clipRect);
//                     encoder.drawIndexed(path.pathLength, 1, path.pathStart);
//                 }
//             encoder.end();
//             encoder.endFrame();
//         }
        
//     }
// }

/**
    Vector drawing context
*/
class SbDrawingContext {

}