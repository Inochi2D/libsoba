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
import std.traits;
import std.format;
import inmath;
import inmath.util;

public import bindbc.wgpu.types : WGPUVertexFormat;
import std.math.exponential;
import std.algorithm.sorting;

enum SbGFXBufferType {
    Vertex,
    Index,
    Uniform
}

struct SbGFXBindingLocation { int location; }

class SbBuffer(T) {
private:
    size_t elements = 0;
    SbGFXContext ctx;

    SbGFXBufferType type;
    WGPUBuffer buffer;

    WGPUVertexBufferLayout layout;
    WGPUVertexAttribute[] attribs;
    bool instanced = false;

    void generateBasicLayout(X)(ref WGPUVertexAttribute[] attribs, ref size_t offset, ref int bindLoc, bool set=false) {
        // Figure out what type to pass
        WGPUVertexFormat fmt;
        static if (is(X : float)) {
            fmt = WGPUVertexFormat.Float32;
        } else static if (is(X == int)) {
            fmt = WGPUVertexFormat.Sint32;
        } else static if (is(X == uint)) {
            fmt = WGPUVertexFormat.Uint32;
        } else static if (isVector!X) {
            static if (is(X.vt : float)) {
                fmt = WGPUVertexFormat.Float32+(X.dimensions-1);
            } else static if (is(X.vt : int)) {
                fmt = WGPUVertexFormat.Sint32+(X.dimensions-1);
            } else static if (is(X.vt : uint)) {
                fmt = WGPUVertexFormat.Uint32+(X.dimensions-1);
            }
        } else static if (isMatrix!X) {

            // Detect matrix base type
            static if (is(X.mt : float)) {
                fmt = WGPUVertexFormat.Float32;
            } else static if (is(X.mt == int)) {
                fmt = WGPUVertexFormat.Sint32;
            } else static if (is(X.mt == uint)) {
                fmt = WGPUVertexFormat.Uint32;
            } 
        }

        static if (isMatrix!X) {

            // Detect matrix row size and pass that in
            fmt = fmt+(X.rows-1);

            // Detect column size and take that in to account by adding them to the list
            foreach(x; 0..X.columns) {
                attribs ~= WGPUVertexAttribute(
                    fmt,
                    offset + X.mt.sizeof*x,
                    bindLoc+x
                );
            }
            if (set) i += X.columns;
            offset += (X.mt.sizeof*X.rows);
        } else {
            attribs ~= WGPUVertexAttribute(
                fmt,
                offset,
                bindLoc
            );
            if (set) i += 1;
            offset += X.sizeof;
        }
    }

    void generateStructLayout(X)(ref WGPUVertexAttribute[] attribs, ref i, size_t offset) {
        int bindLoc;
        static foreach(field; FieldNameTuple!X) {

            // One codegen cycle
            {
                alias ft = mixin(q{typeof(T.%s}.format(field));

                static if (is(ft == struct)) {
                    generateStructLayout!ft(attribs, i, offset);
                } else {

                    // Get bind location UDA or use field position
                    static if (hasUDA!(ft, SbGFXBindingLocation)) {
                        bindLoc = getUDAs!(ft, SbGFXBindingLocation).location;
                        this.generateBasicLayout!ft(attribs, offset, bindLoc, false);
                    } else {
                        this.generateBasicLayout!ft(attribs, offset, i, true);
                    }
                }
            }
        }
    }

    void updateLayout() {

        // Handle array stride
        layout.arrayStride = T.sizeof;

        // Handle attributes
        attribs.length = 0;
        int i = 0;
        size_t offset = 0;
        static if (is(T == struct)) {
            generateStructLayout!T(attribs, i, offset);
        } else {
            generateBasicLayout!T(attribs, i, offset, true);
        }

        // Sort attributes based on shader location
        attribs.sort!((x, y) => x.shaderLocation < y.shaderLocation)();

        // Step mode
        layout.stepMode = instanced ? WGPUVertexStepMode.Instance : WGPUVertexStepMode.Vertex;
        layout.attributeCount = cast(uint)attribs.length;
        layout.attributes = attribs.ptr;
    }
    
    void createBuffer(size_t elements, SbGFXBufferType type) {
        this.elements = elements;
        WGPUBufferDescriptor desc;

        switch(type) {
            case SbGFXBufferType.Index:
                desc.usage = WGPUBufferUsage.Index | WGPUBufferUsage.CopyDst;
                break;
            case SbGFXBufferType.Vertex:
                desc.usage = WGPUBufferUsage.Vertex | WGPUBufferUsage.CopyDst;
                break;
            case SbGFXBufferType.Uniform:
                desc.usage = WGPUBufferUsage.Uniform | WGPUBufferUsage.CopyDst;
                break;
        }
        desc.label = T.nameof.toStringz;
        desc.size = T.sizeof*elements;
        desc.mappedAtCreation = false;
        buffer = wgpuDeviceCreateBuffer(device, &desc);
    }
    
    void createBufferWithData(T[] data, SbGFXBufferType type) {
        this.createBuffer(data.length, type);
        this.bufferData(data, 0);
    }

public:

    /// Constructor
    this(SbGFXContext ctx, T[] data, SbGFXBufferType type) {
        this.ctx = ctx;
        this.createBuffer(data, type);
    }

    /// 
    this(SbGFXContext ctx, size_t startSize, SbGFXBufferType type) {
        this.ctx = ctx;
        this.createBuffer(startSize, type);
    }

    /**
        Buffers data
    */
    void bufferData(T[] data, ulong offset=0) {
        wgpuQueueWriteBuffer(ctx.getQueue(), buffer, offset, data.ptr, T.sizeof*data.length);
    }

    /**
        Resizes the mapped range of the buffer
    */
    void resize(size_t elementCount) {
        size_t oldSize = this.getSize();
        this.elements = data.length;

        // Create new descriptor with new size
        WGPUBufferDescriptor nudesc = buffdesc;
        nudesc.size = this.getSize();

        // Create a new buffer with the new size
        WGPUBuffer newBuffer = wgpuDeviceCreateBuffer(ctx.getDevice(), &nudesc);

        // Copy old data in to new buffer
        auto range = wgpuBufferGetConstMappedRange(buffer, 0, oldSize);
        wgpuQueueWriteBuffer(ctx.getQueue(), newBuffer, 0, range, oldSize);
        wgpuBufferUnmap(buffer);

        // Drop the old buffer and replace it with the new
        wgpuBufferDrop(buffer);
        buffer = newBuffer;
        buffdesc = nudesc;
    }

    /**
        Returns the layout of the buffer
    */
    final
    WGPUVertexBufferLayout getLayout() {
        return layout;
    }

    /**
        Handle of the buffer
    */
    final
    WGPUBuffer getHandle() {
        return buffer;
    }

    /**
        Gets the count of elements in the buffer
    */
    final
    size_t getCount() {
        return elements;
    }

    /**
        Gets the size of the buffer in bytes
    */
    size_t getSize() {
        return T.sizeof*elements;
    }
}