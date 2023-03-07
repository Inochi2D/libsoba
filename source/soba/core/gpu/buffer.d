/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Buffers
*/
module soba.core.gpu.buffer;
import soba.core.gpu;
import bindbc.wgpu;
import std.string;

public import bindbc.wgpu.types : WGPUVertexFormat;

class SbBuffer {
private:
    SbGPUContext ctx;

    WGPUBufferDescriptor buffdesc;
    WGPUBuffer buffer;

    WGPUVertexBufferLayout layout;
    WGPUVertexAttribute[size_t] attribs;
    WGPUVertexAttribute[] cattribs;

    void updateLayout() {
        cattribs.length = 0;
        foreach(attrib; attribs) {
            cattribs ~= attrib;
        }

        layout.stepMode = WGPUVertexStepMode.Vertex;
        layout.attributeCount = cast(uint)cattribs.length;
        layout.attributes = cattribs.ptr;
    }

package(soba.core.gpu):

    static SbBuffer createVertex(SbGPUContext ctx, size_t size, string name=null) {
        SbBuffer buffer = new SbBuffer;
        buffer.buffdesc.mappedAtCreation = false;
        buffer.buffdesc.label = name.toStringz;
        buffer.buffdesc.usage = WGPUBufferUsage.Vertex;
        buffer.buffdesc.size = size;
        buffer.buffdesc.mappedAtCreation = true;
        buffer.buffer = wgpuDeviceCreateBuffer(ctx.getDevice(), &buffer.buffdesc);
        return buffer;
    }

    static SbBuffer createIndex(SbGPUContext ctx, size_t size, string name=null) {
        SbBuffer buffer = new SbBuffer;
        buffer.buffdesc.mappedAtCreation = false;
        buffer.buffdesc.label = name.toStringz;
        buffer.buffdesc.usage = WGPUBufferUsage.Index;
        buffer.buffdesc.size = size;
        buffer.buffdesc.mappedAtCreation = true;
        buffer.buffer = wgpuDeviceCreateBuffer(ctx.getDevice(), &buffer.buffdesc);
        return buffer;
    }

public:

    /**
        Buffers data
    */
    void bufferData(const(void)* data, size_t size, ulong offset=0) {
        wgpuQueueWriteBuffer(ctx.getQueue(), buffer, offset, data, size);
    }

    /**
        Sets a buffer attribute
    */
    void setAttribute(size_t index, WGPUVertexFormat format, ulong offset) {
        attribs[index] = WGPUVertexAttribute(
            format,
            offset,
            cast(uint)index
        );
        this.updateLayout();
    }

    /**
        Removes a buffer attribute
    */
    void removeAttribute(size_t index) {
        if (index in attribs) attribs.remove(index);
        this.updateLayout();
    }

    /**
        Sets the buffer's stride
    */
    void setStride(size_t stride) {
        layout.arrayStride = stride;
        this.updateLayout();
    }

    /**
        Returns the layout of the buffer
    */
    WGPUVertexBufferLayout getLayout() {
        return layout;
    }

    /**
        Handle of the buffer
    */
    WGPUBuffer getHandle() {
        return buffer;
    }
}