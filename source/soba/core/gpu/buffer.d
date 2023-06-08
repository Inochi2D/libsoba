module soba.core.gpu.buffer;
 import std.exception;

/**
    The type of the buffer
*/
enum SbGPUBufferType {
    /**
        Buffer is a vertex buffer
    */
    Vertex,

    /**
        Buffer is an index buffer
    */
    Index,

    /**
        Buffer is a uniform buffer
    */
    Uniform
}

/**
    Format of a vertex attribute
*/
enum SbGPUVertexAttribFormat {

    /// Float attribute
    Float,

    /// Int attribute
    Int,

    /// Vec2 attribute
    Vec2,

    /// Vec3 attribute
    Vec3,

    /// Vec4 attribute
    Vec4,

    /// 3x3 Matrix attribute
    Mat3x3,

    /// 4x4 Matrix attribute
    Mat4x4
}

/**
    A vertex attribute
*/
struct SbGPUVertexAttribute {

    /**
        Format of the vertex attribute
    */
    SbGPUVertexAttribFormat format;
    
    /**
        Offset of the vertex attribute in bytes
    */
    size_t offset;

    /**
        Stride of the attribute
    */
    size_t stride;
}

/**
    A buffer
*/
abstract class SbGPUBuffer {
protected:
    SbGPUVertexAttribute[uint] attribs;
    bool attribsFinalized;

public:

    /**
        Gets the count of elements in the buffer
    */
    abstract size_t getCount();

    /**
        Gets the length of the buffer in bytes
    */
    abstract size_t getLength();

    /**
        Gets the type of the buffer
    */
    abstract SbGPUBufferType getType();

    /**
        Copies data from this buffer to the other buffer
    */
    void copyTo(SbGPUBuffer other, size_t srcOffset, size_t srcLength, size_t dstOffset) {

        // Add these little safety checks in there.
        enforce(other.getType == this.getType(), "Invalid buffer copy target!");
        enforce(srcOffset+srcLength <= this.getLength(), "Copy source is out of bounds!");
        enforce(other.getLength() <= dstOffset+srcLength, "Copy out of range for destination!");
    }

    /**
        Resizes the mapped range of the buffer
    */
    abstract void resize(size_t length);
    
    /**
        Buffers data

        offset+length MUST be shorter than buffer data length
    */
    void bufferData(void* data, size_t length, size_t offset=0) {
        enforce(offset+length <= getLength(), "Source data out of range!");
    }

    /**
        Finalize the attributes
    */
    void finalizeAttributes() {
        attribsFinalized = true;
    }

    /**
        Sets an attribute
    */
    void setAttribute(uint location, SbGPUVertexAttribFormat format, size_t offset, size_t stride) {
        enforce(!attribsFinalized, "Cannot edit finalized buffer attributes");
        attribs[location] = SbGPUVertexAttribute(format, offset, stride);
    }
}