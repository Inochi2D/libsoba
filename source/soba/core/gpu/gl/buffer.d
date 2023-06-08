module soba.core.gpu.gl.buffer;
import soba.core.gpu.gl;
import soba.core.gpu.buffer;

import bindbc.opengl;


class SbGLBuffer : SbGPUBuffer {
private:
    // Sb Variables
    SbGPUBufferType type;
    SbGLContext context;

    // GL variables
    GLuint bufferId;
    size_t size;

    void createBuffer(size_t size) {
        glGenBuffers(1, &bufferId);
        glBindBuffer(GL_ARRAY_BUFFER, bufferId);
        glBufferData(GL_ARRAY_BUFFER, size, null, GL_DYNAMIC_DRAW);
    }
    
public:

    /**
        Creates a buffer with no data but a preallocated size
    */
    this(SbGLContext context, SbGPUBufferType type, size_t initialSize = 1) {
        this.context = context;
        this.type = type;
        
        if (initialSize == 0) initialSize = 1;
        this.size = initialSize;
        
        createBuffer(initialSize);
    }

    /**
        Creates a buffer with preallocated data
    */
    this(SbGLContext context, SbGPUBufferType type, void* initialData, size_t length) {
        this.context = context;
        this.type = type;
        
        if (length == 0) length = 1;
        this.size = length;

        this.createBuffer(length);
        this.bufferData(initialData, length);
    }

    /**
        Gets the count of attributes in the buffer
    */
    override 
    size_t getCount() {
        return attribs.length;
    }

    /**
        Gets the length of the buffer in bytes
    */
    override
    size_t getLength() {
        return size;
    }

    /**
        Gets the type of the buffer
    */
    override
    SbGPUBufferType getType() {
        return type;
    }

    /**
        Copies data from this buffer to the other buffer
    */
    override
    void copyTo(SbGPUBuffer other, size_t srcOffset, size_t srcLength, size_t dstOffset) {
        super.copyTo(other, srcOffset, srcLength, dstOffset);
        
        glBindBuffer(GL_COPY_READ_BUFFER, bufferId);
        glBindBuffer(GL_COPY_WRITE_BUFFER, bufferId);
        glCopyBufferSubData(GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, cast(GLintptr)srcOffset, cast(GLintptr)dstOffset, cast(GLsizeiptr)srcLength);

        // Clear these to not mangle state
        glBindBuffer(GL_COPY_READ_BUFFER, 0);
        glBindBuffer(GL_COPY_WRITE_BUFFER, 0);
    }

    /**
        Resizes the mapped range of the buffer
    */
    override
    void resize(size_t length) {
        // TODO: do a slower technique that retains the OpenGL buffer ID?

        size_t oldLength = this.getLength();
        size = length;
        
        // Create a new buffer with our new size
        GLuint newBuffer;
        glGenBuffers(1, &newBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, newBuffer);
        glBufferData(GL_ARRAY_BUFFER, length, null, GL_DYNAMIC_DRAW);

        // Copy old buffer data in
        glBindBuffer(GL_COPY_READ_BUFFER, bufferId);
        glCopyBufferSubData(GL_COPY_READ_BUFFER, GL_ARRAY_BUFFER, 0, 0, oldLength);

        // Delete old buffer and replace it with the new buffer.
        glDeleteBuffers(1, &bufferId);
        bufferId = newBuffer;
    }
    
    /**
        Buffers data

        offset+length MUST be shorter than buffer data length
    */
    override
    void bufferData(void* data, size_t length, size_t offset=0) {
        super.bufferData(data, length, offset);
        
        glBindBuffer(GL_ARRAY_BUFFER, bufferId);
        if (offset != 0) {

            // Buffer subdata
            glBufferSubData(GL_ARRAY_BUFFER, cast(GLintptr)offset, cast(GLsizeiptr)length, data);
        } else {

            // Buffer normally
            glBufferData(GL_ARRAY_BUFFER, length, data, GL_DYNAMIC_DRAW);
        }
    }

    /**
        Finalize the attributes
    */
    override
    void finalizeAttributes() {
        attribsFinalized = true;
    }
}