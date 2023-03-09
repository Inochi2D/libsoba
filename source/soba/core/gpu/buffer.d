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

/**
    A base interface for all buffer-compatible objects
*/
interface SbGFXBufferBaseI {
    
    /**
        Handle of the buffer
    */
    WGPUBuffer getHandle();
    
    /**
        Returns the layout of the buffer
    */
    WGPUVertexBufferLayout getLayout();

    /**
        Gets the count of elements in the buffer
    */
    size_t getCount();

    /**
        Gets the size of the buffer in bytes
    */
    size_t getSize();

    /**
        Gets the type of the buffer
    */
    SbGFXBufferType getType();
}

/**
    A typed resizable buffer
*/
class SbGFXBuffer(T) : SbGFXBufferBaseI {
private:
    size_t elements = 0;
    SbGFXContext ctx;

    SbGFXBufferType type;
    WGPUBufferDescriptor desc;
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
                fmt = cast(WGPUVertexFormat)(WGPUVertexFormat.Float32+(X.dimension-1));
            } else static if (is(X.vt : int)) {
                fmt = cast(WGPUVertexFormat)(WGPUVertexFormat.Sint32+(X.dimension-1));
            } else static if (is(X.vt : uint)) {
                fmt = cast(WGPUVertexFormat)(WGPUVertexFormat.Uint32+(X.dimension-1));
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
            fmt = cast(WGPUVertexFormat)fmt+(X.rows-1);

            // Detect column size and take that in to account by adding them to the list
            foreach(x; 0..X.columns) {
                attribs ~= WGPUVertexAttribute(
                    fmt,
                    offset + X.mt.sizeof*x,
                    bindLoc+x
                );
            }
            if (set) bindLoc += X.columns;
            offset += (X.mt.sizeof*X.rows);
        } else {
            attribs ~= WGPUVertexAttribute(
                fmt,
                offset,
                bindLoc
            );
            if (set) bindLoc += 1;
            offset += X.sizeof;
        }
    }

    void generateStructLayout(X)(ref WGPUVertexAttribute[] attribs, ref int i, size_t offset) {
        int bindLoc;
        static foreach(field; FieldNameTuple!X) {

            // One codegen cycle
            {
                mixin(q{alias ft = T.%s;}.format(field));
                alias ftt = typeof(ft);

                static if (is(ftt == struct) && !isVector!ftt && !isMatrix!ftt) {
                    generateStructLayout!ftt(attribs, i, offset);
                } else {

                    // Get bind location UDA or use field position
                    static if (hasUDA!(ftt, SbGFXBindingLocation)) {
                        bindLoc = getUDAs!(ft, SbGFXBindingLocation).location;
                        this.generateBasicLayout!ftt(attribs, offset, bindLoc, false);
                    } else {
                        this.generateBasicLayout!ftt(attribs, offset, i, true);
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

    void setupDesc(size_t elements, bool mapped) {
        this.elements = elements;
        desc.label = T.stringof.toStringz;
        desc.size = T.sizeof*elements;
        desc.mappedAtCreation = mapped;
        switch(type) {
            case SbGFXBufferType.Index:
                desc.usage = WGPUBufferUsage.Index | WGPUBufferUsage.CopyDst | WGPUBufferUsage.CopySrc;
                break;
            case SbGFXBufferType.Vertex:
                desc.usage = WGPUBufferUsage.Vertex | WGPUBufferUsage.CopyDst | WGPUBufferUsage.CopySrc;
                break;
            case SbGFXBufferType.Uniform:
                desc.usage = WGPUBufferUsage.Uniform | WGPUBufferUsage.CopyDst | WGPUBufferUsage.CopySrc;
                break;
            default: break;
        }
    }
    
    void createBuffer(size_t elements) {
        this.setupDesc(elements, false);
        this.buffer = wgpuDeviceCreateBuffer(ctx.getDevice(), &desc);

        this.updateLayout();
    }
    
    void createBufferWithData(T[] data) {
        this.setupDesc(data.length, true);
        this.buffer = wgpuDeviceCreateBuffer(ctx.getDevice(), &desc);

        // Copy data over faster
        T* range = cast(T*)wgpuBufferGetMappedRange(buffer, 0, desc.size);
        range[0..data.length] = data[0..$];
        wgpuBufferUnmap(buffer);

        this.updateLayout();
    }

public:

    /// Constructor
    this(SbGFXContext ctx, T[] data, SbGFXBufferType type) {
        this.ctx = ctx;
        this.type = type;
        this.createBufferWithData(data);
    }

    /// 
    this(SbGFXContext ctx, size_t elements, SbGFXBufferType type) {
        this.ctx = ctx;
        this.type = type;
        this.createBuffer(elements);
    }

    /**
        Buffers data
    */
    void bufferData(T[] data, ulong offset=0) {
        import std.stdio : writeln;
        writeln("Buffering ", T.sizeof*data.length, " bytes of data...");
        wgpuQueueWriteBuffer(ctx.getQueue(), buffer, offset, data.ptr, T.sizeof*data.length);
        
    }

    /**
        Resizes the mapped range of the buffer
    */
    void resize(size_t elementCount) {
        size_t oldSize = this.getSize();
        this.elements = elementCount;

        // Create new descriptor with new size
        WGPUBufferDescriptor nudesc = desc;
        nudesc.size = this.getSize();

        // Create a new buffer with the new size
        WGPUBuffer newBuffer = wgpuDeviceCreateBuffer(ctx.getDevice(), &nudesc);

        // Encode a copy from the old buffer to the new
        WGPUCommandEncoderDescriptor cmddesc;
        cmddesc.label = "Copy Encoder";
        auto encoder = wgpuDeviceCreateCommandEncoder(ctx.getDevice(), &cmddesc);
        wgpuCommandEncoderCopyBufferToBuffer(encoder, buffer, 0, newBuffer, 0, oldSize);
        WGPUCommandBuffer cmdbuffer = wgpuCommandEncoderFinish(encoder, new WGPUCommandBufferDescriptor(
            null,
            "Copy Command"
        ));
        wgpuQueueSubmit(ctx.getQueue(), 1, &cmdbuffer);

        // Drop the old buffer and replace it with the new
        wgpuBufferDrop(buffer);
        buffer = newBuffer;
        desc = nudesc;
        this.updateLayout();
    }

    /**
        Copies data from this buffer to the other buffer
    */
    void copyTo(SbGFXBuffer!T other, size_t offset, size_t length) {

        // Encode a copy from the old buffer to the new
        WGPUCommandEncoderDescriptor cmddesc;
        cmddesc.label = "Copy Command";
        auto encoder = wgpuDeviceCreateCommandEncoder(ctx.getDevice(), &cmddesc);
        wgpuCommandEncoderCopyBufferToBuffer(encoder, buffer, offset, other.buffer, offset, T.sizeof*length);
        WGPUCommandBuffer cmdbuffer = wgpuCommandEncoderFinish(encoder, new WGPUCommandBufferDescriptor(
            null,
            "Copy Command"
        ));
        wgpuQueueSubmit(ctx.getQueue(), 1, &cmdbuffer);
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

    /**
        Gets the count of elements in the buffer
    */
    size_t getCount() {
        return elements;
    }

    /**
        Gets the size of the buffer in bytes
    */
    size_t getSize() {
        return T.sizeof*elements;
    }

    /**
        Gets the type of the buffer
    */
    SbGFXBufferType getType() {
        return type;
    }
}