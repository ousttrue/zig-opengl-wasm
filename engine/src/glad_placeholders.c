#include <glad/gl.h>

GLboolean isEnabled(GLenum cap) { return glad_glIsEnabled(cap); }

const GLubyte *getString(GLenum name) { return glad_glGetString(name); }

void viewport(GLint x, GLint y, GLsizei width, GLsizei height) {
  glViewport(x, y, width, height);
}

void scissor(GLint x, GLint y, GLsizei width, GLsizei height) {
  glad_glScissor(x, y, width, height);
}

void clearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) {
  glClearColor(red, green, blue, alpha);
}

void clear(GLbitfield mask) { glClear(mask); }

void genBuffers(GLsizei n, GLuint *buffers) { glad_glGenBuffers(n, buffers); }

void bindBuffer(GLenum target, GLuint buffer) {
  glad_glBindBuffer(target, buffer);
}

void bufferData(GLenum target, GLsizeiptr size, const GLvoid *data,
                GLenum usage) {
  glad_glBufferData(target, size, data, usage);
}

void bufferSubData(GLenum target, GLintptr offset, GLsizeiptr size,
                   const GLvoid *data) {
  glad_glBufferSubData(target, offset, size, data);
}

GLuint createShader(GLenum shaderType) {
  return glad_glCreateShader(shaderType);
}

void deleteShader(GLuint shader) { glad_glDeleteShader(shader); }

void shaderSource(GLuint shader, GLuint count, const GLchar *const *string) {
  glad_glShaderSource(shader, count, string, 0);
}

void compileShader(GLuint shader) { glad_glCompileShader(shader); }

void getShaderiv(GLuint shader, GLenum pname, GLint *params) {
  glad_glGetShaderiv(shader, pname, params);
}

void getShaderInfoLog(GLuint shader, GLsizei maxLength, GLsizei *length,
                      GLchar *infoLog) {
  glad_glGetShaderInfoLog(shader, maxLength, length, infoLog);
}

GLuint createProgram(void) { return glad_glCreateProgram(); }

void attachShader(GLuint program, GLuint shader) {
  glad_glAttachShader(program, shader);
}

void detachShader(GLuint program, GLuint shader) {
  glad_glAttachShader(program, shader);
}

void linkProgram(GLuint program) { glad_glLinkProgram(program); }

void getProgramiv(GLuint program, GLenum pname, GLint *params) {
  glad_glGetProgramiv(program, pname, params);
}

void getProgramInfoLog(GLuint program, GLsizei maxLength, GLsizei *length,
                       GLchar *infoLog) {
  glad_glGetProgramInfoLog(program, maxLength, length, infoLog);
}

GLint getUniformLocation(GLuint program, const GLchar *name) {
  return glad_glGetUniformLocation(program, name);
}

GLint getAttribLocation(GLuint program, const GLchar *name) {
  return glad_glGetAttribLocation(program, name);
}

void enableVertexAttribArray(GLuint index) {
  glad_glEnableVertexAttribArray(index);
}

void vertexAttribPointer(GLuint index, GLint size, GLenum type,
                         GLboolean normalized, GLsizei stride,
                         GLsizeiptr offset) {
  glad_glVertexAttribPointer(index, size, type, normalized, stride, offset);
}

void useProgram(GLuint program) { glad_glUseProgram(program); }

void uniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose,
                      const GLfloat *value) {
  glad_glUniformMatrix4fv(location, count, transpose, value);
}
void uniform1i(GLint location, GLint v0) { glad_glUniform1i(location, v0); }

void drawArrays(GLenum mode, GLint first, GLsizei count) {
  glad_glDrawArrays(mode, first, count);
}
void drawElements(GLenum mode, GLsizei count, GLenum type,
                  const GLvoid *indices) {
  glad_glDrawElements(mode, count, type, indices);
}

void getIntegerv(GLenum pname, GLint *data) { glad_glGetIntegerv(pname, data); }

void bindTexture(GLenum target, GLuint texture) {
  glad_glBindTexture(target, texture);
}

void texImage2D(GLenum target, GLint level, GLint internalFormat,
                  GLsizei width, GLsizei height, GLint border, GLenum format,
                  GLenum type, const GLvoid *data) {
  glad_glTexImage2D(target, level, internalFormat, width, height, border,
                    format, type, data);
}

void activeTexture(GLenum texture) { glad_glActiveTexture(texture); }

void genTextures(GLsizei n, GLuint *textures) {
  glad_glGenTextures(n, textures);
}

void texParameteri(GLenum target, GLenum pname, GLint param) {
  glad_glTexParameteri(target, pname, param);
}

void pixelStorei(GLenum pname, GLint param) {
  glad_glPixelStorei(pname, param);
}

void genVertexArrays(GLsizei n, GLuint *arrays) {
  glad_glGenVertexArrays(n, arrays);
}
void deleteVertexArrays(GLsizei n, const GLuint *arrays) {
  glad_glDeleteVertexArrays(n, arrays);
}

void bindVertexArray(GLuint array) { glad_glBindVertexArray(array); }

void enable(GLenum cap) { glEnable(cap); }
void disable(GLenum cap) { glDisable(cap); }

void blendEquation(GLenum mode) { glad_glBlendEquation(mode); }
void blendFuncSeparate(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha,
                       GLenum dstAlpha) {
  glad_glBlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
}

void blendEquationSeparate(GLenum modeRGB, GLenum modeAlpha) {
  glad_glBlendEquationSeparate(modeRGB, modeAlpha);
}
