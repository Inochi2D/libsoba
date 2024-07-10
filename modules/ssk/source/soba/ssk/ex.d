/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Soba Scene Kit Exceptions
*/
module soba.ssk.ex;
import numem.all;

/**
    Base exception of all SSK exceptions
*/
class SSKException : NuException {
@nogc public:
    this(nstring msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

/**
    Exception thrown when attempting to use Apple-specific APIs on non-apple platforms
*/
class SSKNotAppleException : SSKException {
@nogc public:
    this(string file = __FILE__, size_t line = __LINE__) {
        super(nstring("Attempted to use Apple APIs on non-apple platform!"), file, line);
    }
}

/**
    Exception thrown when attempting to use a feature not yet implemented
*/
class SSKNotImplementedException : SSKException {
@nogc public:
    this(string file = __FILE__, size_t line = __LINE__) {
        super(nstring("This feature is currently not implemented!"), file, line);
    }
}