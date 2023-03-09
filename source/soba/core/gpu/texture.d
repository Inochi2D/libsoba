/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Textures
*/
module soba.core.gpu.texture;
import soba.core.gpu;
import bindbc.wgpu;

class SbGFXTexture {
    
}

// class SbTexture {
// private:
//     SbGFXContext ctx;
//     WGPUTextureDescriptor desc;
//     WGPUTexture texture;

//     static SbTexture create(SbGFXContext ctx, Image image) {
//         SbTexture tex = new SbTexture;
//         tex.ctx = ctx;
//         tex.desc = WGPUTextureDescriptor(
//             null,
//             "Texture",
//             WGPUTextureUsage.TextureBinding,
//             WGPUTextureDimension.D2,
//             WGPUExtent3D(image.width, image.height, 1),
//             WGPUTextureFormat.RGBA8Uint,
//             1,
//             1,
//             0,
//             null
//         );
//         tex.texture = wgpuDeviceCreateTexture(ctx.device, tex.desc);
//     }
// public:

//     void setData(ubyte[] data, int width, int height) {
//         auto size = WGPUExtent3D(
//             width,
//             height,
//             1
//         );

//         desc.format.

//         wgpuQueueWriteTexture(ctx.queue, 
//             new WGPUImageCopyTexture(
//                 null,
//                 texture,
//                 0,
//                 WGPUOrigin3D(0, 0, 0),
//                 WGPUTextureAspect.All
//             ),
//             data.ptr,
//             data.length,
//             WGPUTextureDataLayout(
//                 null,
//                 0,
//                 (channels) * width,
//                 height
//             ),
//             &size
//         );
//     }

//     void setData(Image image) {
//         ubyte[] data = image.allPixelsAtOnce();
//         size_t channels = 0;
//         size_t bpc = 0;
//         switch(image.type) {
//             case PixelType.rgb8:
//                 channels = 3;
//                 bpc = 1;
//                 break;
//             case PixelType.rgb16:
//                 channels = 3;
//                 bpc = 2;
//                 break;
//             case PixelType.rgbf32:
//                 channels = 3;
//                 bpc = 4;
//                 break;
//             case PixelType.rgba8:
//                 channels = 4;
//                 bpc = 1;
//                 break;
//             case PixelType.rgba16:
//                 channels = 4;
//                 bpc = 2;
//                 break;
//             case PixelType.rgbaf32:
//                 channels = 4;
//                 bpc = 4;
//                 break;
//         }

//         auto size = WGPUExtent3D(
//             image.width,
//             image.height,
//             1
//         );

//         wgpuQueueWriteTexture(ctx.queue, 
//             new WGPUImageCopyTexture(
//                 null,
//                 texture,
//                 0,
//                 WGPUOrigin3D(0, 0, 0),
//                 WGPUTextureAspect.All
//             ),
//             data.ptr,
//             data.length,
//             WGPUTextureDataLayout(
//                 null,
//                 0,
//                 (channels) * image.width,
//                 image.height
//             ),
//             &size
//         );
//     }
    
// }