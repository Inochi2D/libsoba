module soba.ssk.appl;

version(SbApple) enum SSKIsApplePlatform = true;
else enum SSKIsApplePlatform = false; /// Whether the compiled-for platform is one made by Apple Inc.