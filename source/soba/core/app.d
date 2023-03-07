/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Application
*/
module soba.core.app;
import soba.core.gpu;
import std.format;
import inmath.math;

struct SbVersion {
    int major;
    int minor;
    int patch;
    string tag;

    int opCmp(ref SbVersion other) const {
        int s = this.major - other.major;
        if (s == 0) s += this.minor - other.minor;
        if (s == 0) s += this.patch - other.patch;
        return clamp(s, -1, 1);
    }

    /**
        Gets semantic version string
    */
    string toString() const {
        string ver_ = "%s.%s.%s".format(major, minor, patch);
        if (tag.length > 0) ver_ ~= "-%s".format(tag);
        return ver_;
    }
}

@("Version Comparison")
unittest {
    SbVersion ver_ = SbVersion(1, 0, 0);
    SbVersion ver2_ = SbVersion(2, 0, 0);
    assert(ver_ < ver2_);
    assert(ver2_ > ver_);
    assert(ver_ == ver_);
    
    ver_ = SbVersion(0, 1, 0);
    ver2_ = SbVersion(0, 2, 0);
    assert(ver_ < ver2_);
    assert(ver2_ > ver_);
    assert(ver_ == ver_);
    
    ver_ = SbVersion(0, 0, 1);
    ver2_ = SbVersion(0, 0, 2);
    assert(ver_ < ver2_);
    assert(ver2_ > ver_);
    assert(ver_ == ver_);
}

/**
    A Soba Application
*/
class SbApp {
    /**
        Name of the application in reverse domain notation
    */
    string name;
    
    /**
        Human-readable of the application
    */
    string humanName;

    /**
        Version number of the application
    */
    SbVersion version_;

    /**
        The application's GPU Context
    */
    SbGPUContext gpuContext;

    this(string name, string humanName, SbVersion version_) {
        this.name = name;
        this.humanName = humanName;
        this.version_= version_;
        this.gpuContext = new SbGPUContext();
    }
}