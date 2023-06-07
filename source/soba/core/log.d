module soba.core.log;
import colorize;
import std.stdio;

private {
    LogLevel loglevel = LogLevel.Info;
}

enum LogLevel {
    NONE,
    Info,
    Warning,
    Error,
    Debug,
}

/**
    Sets the current logging level
*/
void sbSetLogLevel(LogLevel level) {
    loglevel = level;
}

/**
    Gets whether the specified log level is active
*/
bool sbGetLogLevelActive(LogLevel level) {
    return loglevel >= level;
}

/**
    Write informational message
*/
void sbLogInfo(T...)(string msg, T data) {
    if (!sbGetLogLevelActive(LogLevel.Info)) return;
    cwrite("[INFO] ".color(fg.black));
    writefln!T(msg, data);
}

/**
    Write warning message
*/
void sbLogWarning(T...)(string msg, T data) {
    if (!sbGetLogLevelActive(LogLevel.Info)) return;
    cwrite("[WARN] ".color(fg.light_yellow));
    writefln!T(msg, data);
}

/**
    Write warning message
*/
void sbLogError(T...)(string msg, T data) {
    if (!sbGetLogLevelActive(LogLevel.Info)) return;
    cwrite("[ERR ] ".color(fg.red));
    writefln!T(msg, data);
}

/**
    Write warning message
*/
void sbLogDebug(T...)(string msg, T data) {
    if (!sbGetLogLevelActive(LogLevel.Info)) return;
    cwrite("[DBG ] ".color(fg.blue));
    writefln!T(msg, data);
}