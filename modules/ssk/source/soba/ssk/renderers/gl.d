module soba.ssk.renderers.gl;
import soba.ssk.renderers;
import soba.ssk.texture;
import soba.sio;
import numem.all;
import inmath;

import bindbc.opengl;

enum sskBaseVtxShaderGL = "
#version 330
uniform mat4 mvp;

layout(location = 0) in vec2 vtxIn;
layout(location = 1) in vec2 uvIn;

out vec2 uvOut;

void main() {
    gl_Position = mvp * vec4(vtxIn.x, vtxIn.y, 0, 1);
    uvOut = uvIn;
}\0";

enum sskBaseFragShaderGL = "
#version 330
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
        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
        glVertexAttribPointer(
            0,
            2,
            GL_FLOAT,
            GL_FALSE,
            float.sizeof*4,
            cast(void*)0
        );
        glVertexAttribPointer(
            1,
            2,
            GL_FLOAT,
            GL_FALSE,
            float.sizeof*4,
            cast(void*)8
        );

        program = createShaderProgram(sskBaseVtxShaderGL, sskBaseFragShaderGL);
        glBufferData(GL_ARRAY_BUFFER, vec2.sizeof*12, null, GL_DYNAMIC_DRAW);
    }

public:

    ~this() {
        glDeleteBuffers(1, &vbo);
        glDeleteProgram(program);
    }
    
    this(SioWindow window) {
        super(window);

        window.makeCurrent();
        enforce(loadOpenGL() != GLSupport.noLibrary, nstring("Failed to establish OpenGL context."));
    
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
        glEnable(GL_SCISSOR_TEST);
        glBindVertexArray(vao);
    }

    override
    void end() {
        this.getWindow().makeCurrent();
        glDisable(GL_SCISSOR_TEST);
    }

    override
    void setScissor(recti scissor) {
        this.getWindow().makeCurrent();
        vec2i wsize = this.getWindow().getFramebufferSize();
        glScissor(scissor.left, wsize.y-scissor.y, scissor.width, scissor.height);
    }

    /**
        Renders texture to the specified area
    */
    override
    void renderTextureTo(SskTexture texture, recti at) {
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
        
        glBindVertexArray(vao);
        glBindBuffer(vbo, GL_ARRAY_BUFFER);
        glBindTexture(GL_TEXTURE_2D, cast(GLuint)texture.getHandle());
        glBufferSubData(GL_ARRAY_BUFFER, 0, vec2.sizeof*vtxData.length, vtxData.ptr);
        glDrawArrays(GL_TRIANGLES, 0, 6);
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
                null
            );

            glGenerateMipmap(GL_TEXTURE_2D);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }
}