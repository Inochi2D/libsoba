module soba.ssk.appl;

// Apple platforms
version(OSX) version = ApplePlatform;
else version(iOS) version = ApplePlatform;

version(ApplePlatfom) enum SSKIsApplePlatform = true;
else enum SSKIsApplePlatform = false; /// Whether the compiled-for platform is one made by Apple Inc.