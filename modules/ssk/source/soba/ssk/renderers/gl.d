module soba.ssk.renderers.gl;
import soba.ssk.renderers;
import soba.ssk.texture;
import soba.sio;
import numem.all;
import inmath;

import bindbc.opengl;

enum sskBaseVtxShaderGL = "
#version 150 core
#extension GL_ARB_explicit_attrib_location : enable

layout(location = 0) in vec2 vtxIn;
layout(location = 1) in vec2 uvIn;

uniform mat4 mvp;

out vec2 uvOut;

void main() {
    gl_Position = mvp * vec4(vtxIn.x, vtxIn.y, -10, 1);
    uvOut = uvIn;
}\0";

enum sskBaseFragShaderGL = "
#version 150 core
#extension GL_ARB_explicit_attrib_location : enable
in vec2 uvOut;

uniform sampler2D texIn;

layout(location = 0) out vec4 colorOut;

void main() {
    colorOut = texture(texIn, uvOut);
}\0";

class SskGLRenderer : SskRenderer {
@nogc:
private:
    GLuint vao;
    GLuint vbo;

    GLuint program;
    GLuint mvp;

    vec2i fbSize;

    GLuint createShader(GLenum type, const(char)* code) {
        GLuint shader = glCreateShader(type);
        glShaderSource(shader, 1, &code, null);
        glCompileShader(shader);

        int success;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
        if (!success) {
            int logLen;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLen);

            nstring errText;
            errText.resize(logLen);

            glGetShaderInfoLog(shader, logLen, null, cast(char*)errText.ptr);
            throw nogc_new!NuException(errText);
        }

        return shader;
    }

    GLuint createShaderProgram(const(char)* vtx, const(char)* frag) {
        GLuint vtxShader = createShader(GL_VERTEX_SHADER, vtx);
        GLuint fragShader = createShader(GL_FRAGMENT_SHADER, frag);

        GLuint prog = glCreateProgram();
        glAttachShader(prog, vtxShader);
        glAttachShader(prog, fragShader);
        glLinkProgram(prog);

        // Should be linked by now.
        // Which means we can free these.
        glDeleteShader(vtxShader);
        glDeleteShader(fragShader);

        int success;
        glGetProgramiv(prog, GL_LINK_STATUS, &success);
        if (!success) {

            int logLen;
            glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLen);

            nstring errText;
            errText.resize(logLen);

            glGetProgramInfoLog(prog, logLen, null, cast(char*)errText.ptr);
            throw nogc_new!NuException(errText);
        }

        return prog;
    }

    void initState() {
        glGenBuffers(1, &vbo);
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);

        program = createShaderProgram(sskBaseVtxShaderGL, sskBaseFragShaderGL);
        mvp = glGetUniformLocation(program, "mvp");

        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glVertexAttribPointer(
            0,
            2,
            GL_FLOAT,
            GL_FALSE,
            vec2.sizeof*2,
            cast(void*)0
        );
        glVertexAttribPointer(
            1,
            2,
            GL_FLOAT,
            GL_FALSE,
            vec2.sizeof*2,
            cast(void*)vec2.sizeof
        );
    }

public:

    ~this() {
        glDeleteBuffers(1, &vbo);
        glDeleteVertexArrays(1, &vao);
        glDeleteProgram(program);
    }
    
    this(SioWindow window) {
        super(window);

        window.makeCurrent();
        GLSupport support = loadOpenGL();
        enforce(support != GLSupport.noLibrary, nstring("Failed to establish OpenGL context."));

        this.initState();
    }

    override
    SskTexture createTexture(SskTextureFormat format, SskTextureKind kind, uint width, uint height) {
        this.getWindow().makeCurrent();
        return nogc_new!SskGLTexture(format, kind, width, height);
    }

    override
    void begin() {
        this.getWindow().makeCurrent();
        
        fbSize = this.getWindow().getFramebufferSize();
        glViewport(0, 0, fbSize.x, fbSize.y);

        mat4 mvpMatrix = mat4.orthographic(0, fbSize.x, fbSize.y, 0, 0, ushort.max);
        glUniformMatrix4fv(mvp, 1, GL_TRUE, mvpMatrix.ptr);

        glBindVertexArray(vao);
        glDisable(GL_DEPTH_TEST);
        glEnable(GL_SCISSOR_TEST);
        glEnable(GL_BLEND);
        glBlendEquation(GL_FUNC_ADD);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    }

    override
    void end() {
        this.getWindow().makeCurrent();
        glDisable(GL_SCISSOR_TEST);
        glDisable(GL_BLEND);
        glEnable(GL_DEPTH_TEST);
    }

    override
    void setScissor(recti scissor) {
        this.getWindow().makeCurrent();

        glScissor(scissor.left, fbSize.y-scissor.height, scissor.width, fbSize.y);
    }

    /**
        Renders texture to the specified area
    */
    override
    void renderTextureTo(SskTexture texture, recti at) {
        this.getWindow().makeCurrent();

        // Vertex Data
        vec2[12] vtxData = [
            vec2(at.left, at.top),
            vec2(0, 0),
            vec2(at.left, at.bottom),
            vec2(0, 1),
            vec2(at.right, at.top),
            vec2(1, 0),
            vec2(at.right, at.top),
            vec2(1, 0),
            vec2(at.left, at.bottom),
            vec2(0, 1),
            vec2(at.right, at.bottom),
            vec2(1, 1),
        ];
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vtxData.sizeof*vtxData.length, vtxData.ptr, GL_DYNAMIC_DRAW);

        glBindVertexArray(vao);
        glUseProgram(program);
        glBindTexture(GL_TEXTURE_2D, cast(GLuint)texture.getHandle());
        
        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
            glDrawArrays(GL_TRIANGLES, 0, 6);

        glDisableVertexAttribArray(1);
        glDisableVertexAttribArray(0);
    }

    /**
        Sets texture to render target.
        Type of texture MUST be framebuffer.

        Set to null to render to the window once again.
    */
    override
    void renderToTexture(SskTexture texture) {

    }
}

class SskGLTexture : SskTexture {
@nogc:
private:
    GLuint handle;
    GLuint fbTexHandle;

    uint width, height;

    void create() {
        if (this.getKind() == SskTextureKind.image) {
            glGenTextures(1, &handle);
            glBindTexture(GL_TEXTURE_2D, handle);
            glTexImage2D(
                GL_TEXTURE_2D,
                0,
                GL_RGBA,
                width,
                height,
                0,
                this.getFormat() == SskTextureFormat.RGB ? GL_RGB : GL_BGRA,
                GL_UNSIGNED_BYTE,
                null
            );
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);  

        } else {
            glGenTextures(1, &fbTexHandle);
            glGenFramebuffers(1, &handle);

            glBindTexture(GL_TEXTURE_2D, handle);
            glTexImage2D(
                GL_TEXTURE_2D,
                0,
                GL_RGBA,
                width,
                height,
                0,
                GL_RGBA,
                GL_UNSIGNED_BYTE,
                null
            );
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 

            glBindFramebuffer(GL_FRAMEBUFFER, handle);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fbTexHandle, 0);
        
            // Back to default.
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }
    }

public:
    ~this() {
        final switch(this.getKind()) {
            case SskTextureKind.image:
                glDeleteTextures(1, &handle);
                break;

            case SskTextureKind.framebuffer:
                glDeleteFramebuffers(1, &handle);
                glDeleteTextures(1, &fbTexHandle);
                break;
        }
    }

    this(SskTextureFormat format, SskTextureKind kind, uint width, uint height) {
        super(format, kind, width, height);

        this.width = width;
        this.height = height;

        this.create();
    }

    /**
        Gets the render-api specific handle
    */
    override
    SskTextureRef getHandle() {
        return cast(SskTextureRef)handle;
    }

    /**
        Resizes the texture
    */
    override
    void resize(uint width, uint height) {
        this.width = width;
        this.height = height;

        glBindTexture(GL_TEXTURE_2D, this.getKind() == SskTextureKind.framebuffer ? fbTexHandle : handle);
        glTexImage2D(
            GL_TEXTURE_2D,
            0,
            GL_RGBA,
            width,
            height,
            0,
            GL_RGBA,
            GL_UNSIGNED_BYTE,
            null
        );
    }

    /**
        Gets the width of the texture
    */
    override
    uint getWidth() {
        return width;
    }

    /**
        Gets the height of the texture
    */
    override
    uint getHeight() {
        return height;
    }

    override
    void upload(SskTextureFormat format, ubyte[] data, uint width, uint height) {
        if (this.getKind() == SskTextureKind.image) {
            glBindTexture(GL_TEXTURE_2D, handle);
            glTexImage2D(
                GL_TEXTURE_2D,
                0,
                GL_RGBA,
                width,
                height,
                0,
                GL_RGBA,
                GL_UNSIGNED_BYTE,
                data.ptr
            );
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }
}