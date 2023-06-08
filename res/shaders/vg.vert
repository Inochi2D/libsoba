/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Ported and adapted from NanoVG
*/
#version 330
uniform vec2 viewSize;

layout(location = 0) in vec2 posIn;
layout(location = 1) in vec2 uvIn;

out vec4 posOut;
out vec2 uvOut;

void main() {
    posOut = vec4(posIn, 0.0, 1.0);
    uvOut = uvIn;
}