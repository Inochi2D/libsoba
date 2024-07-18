/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen, SDL2 Project

    Definitions in this file are taken from the SDL headers for compatibility
    reasons.

    --------------------------------------------------------------------------

    Simple DirectMedia Layer
    Copyright (C) 1997-2024 Sam Lantinga <slouken@libsdl.org>

    This software is provided 'as-is', without any express or implied
    warranty.  In no event will the authors be held liable for any damages
    arising from the use of this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
        claim that you wrote the original software. If you use this software
        in a product, an acknowledgment in the product documentation would be
        appreciated but is not required.
    2. Altered source versions must be plainly marked as such, and must not be
        misrepresented as being the original software.
    3. This notice may not be removed or altered from any source distribution.
*/

module soba.sio.events.keyboard;
import bindbc.sdl;

/**
    Keyboard event IDs
*/
enum SioKeyboardEventID : ubyte {
    pressed,
    released
}

/**
    Keyboard modifiers
*/
enum SioKeyModifier : ushort {
    none    = 0x0000,
    lshift  = 0x0001,
    rshift  = 0x0002,
    lctrl   = 0x0040,
    rctrl   = 0x0080,
    lalt    = 0x0100,
    ralt    = 0x0200,
    lgui    = 0x0400,
    rgui    = 0x0800,
    num     = 0x1000,
    caps    = 0x2000,
    mode    = 0x4000,
    scroll  = 0x8000,

    ctrl    = lctrl  | rctrl,
    shift   = lshift | rshift,
    alt     = lalt   | ralt,
    gui     = lgui   | rgui,
}

/**
    Converts a Sio keymod to a SDL2 keymod.
*/
pragma(inline, true)
SDL_Keymod toSDLKeyMod(SioKeyModifier mod) {
    return cast(SDL_Keymod)mod;
}

/**
    Scancodes
*/
enum SioScanCode : ushort {
    unknown = 0,
    a = 4,
    b = 5,
    c = 6,
    d = 7,
    e = 8,
    f = 9,
    g = 10,
    h = 11,
    i = 12,
    j = 13,
    k = 14,
    l = 15,
    m = 16,
    n = 17,
    o = 18,
    p = 19,
    q = 20,
    r = 21,
    s = 22,
    t = 23,
    u = 24,
    v = 25,
    w = 26,
    x = 27,
    y = 28,
    z = 29,
    num1 = 30,
    num2 = 31,
    num3 = 32,
    num4 = 33,
    num5 = 34,
    num6 = 35,
    num7 = 36,
    num8 = 37,
    num9 = 38,
    num0 = 39,
    enter = 40,
    escape = 41,
    backspace = 42,
    tab = 43,
    space = 44,
    minus = 45,
    equals = 46,
    leftbracket = 47,
    rightbracket = 48,
    backslash = 49, 
    nonushash = 50, 
    semicolon = 51,
    apostrophe = 52,
    grave = 53, 
    comma = 54,
    period = 55,
    slash = 56,
    capslock = 57,
    f1 = 58,
    f2 = 59,
    f3 = 60,
    f4 = 61,
    f5 = 62,
    f6 = 63,
    f7 = 64,
    f8 = 65,
    f9 = 66,
    f10 = 67,
    f11 = 68,
    f12 = 69,
    printscreen = 70,
    scrolllock = 71,
    pause = 72,
    insert = 73,
    home = 74,
    pageup = 75,
    del = 76,
    end = 77,
    pagedown = 78,
    right = 79,
    left = 80,
    down = 81,
    up = 82,
    numlockclear = 83,
    kpDivide = 84,
    kpMultiply = 85,
    kpMinus = 86,
    kpPlus = 87,
    kpEnter = 88,
    kp1 = 89,
    kp2 = 90,
    kp3 = 91,
    kp4 = 92,
    kp5 = 93,
    kp6 = 94,
    kp7 = 95,
    kp8 = 96,
    kp9 = 97,
    kp0 = 98,
    kpPeriod = 99,
    nonusbackslash = 100,
    application = 101,
    power = 102,
    kpEquals = 103,
    f13 = 104,
    f14 = 105,
    f15 = 106,
    f16 = 107,
    f17 = 108,
    f18 = 109,
    f19 = 110,
    f20 = 111,
    f21 = 112,
    f22 = 113,
    f23 = 114,
    f24 = 115,
    execute = 116,
    help = 117,
    menu = 118,
    select = 119,
    stop = 120,    
    again = 121,  
    undo = 122,   
    cut = 123,   
    copy = 124,   
    paste = 125,  
    find = 126,  
    mute = 127,
    volumeup = 128,
    volumedown = 129,
    kpComma = 133,
    kpEqualsas400 = 134,
    international1 = 135,
    international2 = 136,
    international3 = 137,
    international4 = 138,
    international5 = 139,
    international6 = 140,
    international7 = 141,
    international8 = 142,
    international9 = 143,
    lang1 = 144,
    lang2 = 145,
    lang3 = 146, 
    lang4 = 147,
    lang5 = 148,
    lang6 = 149,
    lang7 = 150,
    lang8 = 151,
    lang9 = 152,
    alterase = 153,
    sysreq = 154,
    cancel = 155,
    clear = 156,
    prior = 157,
    return2 = 158,
    separator = 159,
    out_ = 160,
    oper = 161,
    clearagain = 162,
    crsel = 163,
    exsel = 164,
    kp00 = 176,
    kp000 = 177,
    thousandsseparator = 178,
    decimalseparator = 179,
    currencyunit = 180,
    currencysubunit = 181,
    kpLeftparen = 182,
    kpRightparen = 183,
    kpLeftbrace = 184,
    kpRightbrace = 185,
    kpTab = 186,
    kpBackspace = 187,
    kpA = 188,
    kpB = 189,
    kpC = 190,
    kpD = 191,
    kpE = 192,
    kpF = 193,
    kpXor = 194,
    kpPower = 195,
    kpPercent = 196,
    kpLess = 197,
    kpGreater = 198,
    kpAmpersand = 199,
    kpDblampersand = 200,
    kpVerticalbar = 201,
    kpDblverticalbar = 202,
    kpColon = 203,
    kpHash = 204,
    kpSpace = 205,
    kpAt = 206,
    kpExclam = 207,
    kpMemstore = 208,
    kpMemrecall = 209,
    kpMemclear = 210,
    kpMemadd = 211,
    kpMemsubtract = 212,
    kpMemmultiply = 213,
    kpMemdivide = 214,
    kpPlusminus = 215,
    kpClear = 216,
    kpClearentry = 217,
    kpBinary = 218,
    kpOctal = 219,
    kpDecimal = 220,
    kpHexadecimal = 221,
    lctrl = 224,
    lshift = 225,
    lalt = 226,
    lgui = 227,
    rctrl = 228,
    rshift = 229,
    ralt = 230,
    rgui = 231,
    mode = 257,
    audionext = 258,
    audioprev = 259,
    audiostop = 260,
    audioplay = 261,
    audiomute = 262,
    mediaselect = 263,
    www = 264,          
    mail = 265,
    calculator = 266,  
    computer = 267,
    acSearch = 268,    
    acHome = 269,     
    acBack = 270,        
    acForward = 271,     
    acStop = 272,    
    acRefresh = 273,   
    acBookmarks = 274, 
    brightnessdown = 275,
    brightnessup = 276,
    displayswitch = 277,
    kbdillumtoggle = 278,
    kbdillumdown = 279,
    kbdillumup = 280,
    eject = 281,
    sleep = 282,  
    app1 = 283,
    app2 = 284,
    audiorewind = 285,
    audiofastforward = 286,
    softleft = 287,
    softright = 288,
    call = 289,
    endcall = 290,
}

/**
    Converts a Sio scancode to a SDL2 scancode.
*/
pragma(inline, true)
SDL_Scancode toSDLScanCode(SioScanCode code) {
    return cast(SDL_Scancode)code;
}


/**
    Converts a scancode to a keycode
*/
enum SioScanCodeToKeyCode(SioScanCode code) = cast(char)(code | (1 << 30));

/**
    Keycodes
*/
enum SioKeyCode : char {
    unknown = '\0',

    enter = '\r',
    escape = '\x1b',
    backspace = '\b',
    tab = '\t',
    space = ' ',
    exclaim = '!',
    quotedbl = '"',
    hash = '#',
    percent = '%',
    dollar = '$',
    ampersand = '&',
    quote = '\'',
    leftparen = '(',
    rightparen = ')',
    asterisk = '*',
    plus = '+',
    comma = ',',
    minus = '-',
    period = '.',
    slash = '/',
    num0 = '0',
    num1 = '1',
    num2 = '2',
    num3 = '3',
    num4 = '4',
    num5 = '5',
    num6 = '6',
    num7 = '7',
    num8 = '8',
    num9 = '9',
    colon = ':',
    semicolon = ';',
    less = '<',
    equals = '=',
    greater = '>',
    question = '?',
    at = '@',
    
    leftbracket = '[',
    backslash = '\\',
    rightbracket = ']',
    caret = '^',
    underscore = '_',
    backquote = '`',
    a = 'a',
    b = 'b',
    c = 'c',
    d = 'd',
    e = 'e',
    f = 'f',
    g = 'g',
    h = 'h',
    i = 'i',
    j = 'j',
    k = 'k',
    l = 'l',
    m = 'm',
    n = 'n',
    o = 'o',
    p = 'p',
    q = 'q',
    r = 'r',
    s = 's',
    t = 't',
    u = 'u',
    v = 'v',
    w = 'w',
    x = 'x',
    y = 'y',
    z = 'z',

    
    capslock                = SioScanCodeToKeyCode!(SioScanCode.capslock),
    f1                      = SioScanCodeToKeyCode!(SioScanCode.f1),
    f2                      = SioScanCodeToKeyCode!(SioScanCode.f2),
    f3                      = SioScanCodeToKeyCode!(SioScanCode.f3),
    f4                      = SioScanCodeToKeyCode!(SioScanCode.f4),
    f5                      = SioScanCodeToKeyCode!(SioScanCode.f5),
    f6                      = SioScanCodeToKeyCode!(SioScanCode.f6),
    f7                      = SioScanCodeToKeyCode!(SioScanCode.f7),
    f8                      = SioScanCodeToKeyCode!(SioScanCode.f8),
    f9                      = SioScanCodeToKeyCode!(SioScanCode.f9),
    f10                     = SioScanCodeToKeyCode!(SioScanCode.f10),
    f11                     = SioScanCodeToKeyCode!(SioScanCode.f11),
    f12                     = SioScanCodeToKeyCode!(SioScanCode.f12),
    printscreen             = SioScanCodeToKeyCode!(SioScanCode.printscreen),
    scrolllock              = SioScanCodeToKeyCode!(SioScanCode.scrolllock),
    pause                   = SioScanCodeToKeyCode!(SioScanCode.pause),
    insert                  = SioScanCodeToKeyCode!(SioScanCode.insert),
    home                    = SioScanCodeToKeyCode!(SioScanCode.home),
    pageup                  = SioScanCodeToKeyCode!(SioScanCode.pageup),
    del                     = '\x7F',
    end                     = SioScanCodeToKeyCode!(SioScanCode.end),
    pagedown                = SioScanCodeToKeyCode!(SioScanCode.pagedown),
    right                   = SioScanCodeToKeyCode!(SioScanCode.right),
    left                    = SioScanCodeToKeyCode!(SioScanCode.left),
    down                    = SioScanCodeToKeyCode!(SioScanCode.down),
    up                      = SioScanCodeToKeyCode!(SioScanCode.up),
    numlockclear            = SioScanCodeToKeyCode!(SioScanCode.numlockclear),
    kpDivide                = SioScanCodeToKeyCode!(SioScanCode.kpDivide),
    kpMultiply              = SioScanCodeToKeyCode!(SioScanCode.kpMultiply),
    kpMinus                 = SioScanCodeToKeyCode!(SioScanCode.kpMinus),
    kpPlus                  = SioScanCodeToKeyCode!(SioScanCode.kpPlus),
    kpEnter                 = SioScanCodeToKeyCode!(SioScanCode.kpEnter),
    kp1                     = SioScanCodeToKeyCode!(SioScanCode.kp1),
    kp2                     = SioScanCodeToKeyCode!(SioScanCode.kp2),
    kp3                     = SioScanCodeToKeyCode!(SioScanCode.kp3),
    kp4                     = SioScanCodeToKeyCode!(SioScanCode.kp4),
    kp5                     = SioScanCodeToKeyCode!(SioScanCode.kp5),
    kp6                     = SioScanCodeToKeyCode!(SioScanCode.kp6),
    kp7                     = SioScanCodeToKeyCode!(SioScanCode.kp7),
    kp8                     = SioScanCodeToKeyCode!(SioScanCode.kp8),
    kp9                     = SioScanCodeToKeyCode!(SioScanCode.kp9),
    kp0                     = SioScanCodeToKeyCode!(SioScanCode.kp0),
    kpPeriod                = SioScanCodeToKeyCode!(SioScanCode.kpPeriod),
    application             = SioScanCodeToKeyCode!(SioScanCode.application),
    power                   = SioScanCodeToKeyCode!(SioScanCode.power),
    kpEquals                = SioScanCodeToKeyCode!(SioScanCode.kpEquals),
    f13                     = SioScanCodeToKeyCode!(SioScanCode.f13),
    f14                     = SioScanCodeToKeyCode!(SioScanCode.f14),
    f15                     = SioScanCodeToKeyCode!(SioScanCode.f15),
    f16                     = SioScanCodeToKeyCode!(SioScanCode.f16),
    f17                     = SioScanCodeToKeyCode!(SioScanCode.f17),
    f18                     = SioScanCodeToKeyCode!(SioScanCode.f18),
    f19                     = SioScanCodeToKeyCode!(SioScanCode.f19),
    f20                     = SioScanCodeToKeyCode!(SioScanCode.f20),
    f21                     = SioScanCodeToKeyCode!(SioScanCode.f21),
    f22                     = SioScanCodeToKeyCode!(SioScanCode.f22),
    f23                     = SioScanCodeToKeyCode!(SioScanCode.f23),
    f24                     = SioScanCodeToKeyCode!(SioScanCode.f24),
    execute                 = SioScanCodeToKeyCode!(SioScanCode.execute),
    help                    = SioScanCodeToKeyCode!(SioScanCode.help),
    menu                    = SioScanCodeToKeyCode!(SioScanCode.menu),
    select                  = SioScanCodeToKeyCode!(SioScanCode.select),
    stop                    = SioScanCodeToKeyCode!(SioScanCode.stop),
    again                   = SioScanCodeToKeyCode!(SioScanCode.again),
    undo                    = SioScanCodeToKeyCode!(SioScanCode.undo),
    cut                     = SioScanCodeToKeyCode!(SioScanCode.cut),
    copy                    = SioScanCodeToKeyCode!(SioScanCode.copy),
    paste                   = SioScanCodeToKeyCode!(SioScanCode.paste),
    find                    = SioScanCodeToKeyCode!(SioScanCode.find),
    mute                    = SioScanCodeToKeyCode!(SioScanCode.mute),
    volumeup                = SioScanCodeToKeyCode!(SioScanCode.volumeup),
    volumedown              = SioScanCodeToKeyCode!(SioScanCode.volumedown),
    kpComma                 = SioScanCodeToKeyCode!(SioScanCode.kpComma),
    kpEqualsas400           = SioScanCodeToKeyCode!(SioScanCode.kpEqualsas400),
    alterase                = SioScanCodeToKeyCode!(SioScanCode.alterase),
    sysreq                  = SioScanCodeToKeyCode!(SioScanCode.sysreq),
    cancel                  = SioScanCodeToKeyCode!(SioScanCode.cancel),
    clear                   = SioScanCodeToKeyCode!(SioScanCode.clear),
    prior                   = SioScanCodeToKeyCode!(SioScanCode.prior),
    return2                 = SioScanCodeToKeyCode!(SioScanCode.return2),
    separator               = SioScanCodeToKeyCode!(SioScanCode.separator),
    out_                    = SioScanCodeToKeyCode!(SioScanCode.out_),
    oper                    = SioScanCodeToKeyCode!(SioScanCode.oper),
    clearagain              = SioScanCodeToKeyCode!(SioScanCode.clearagain),
    crsel                   = SioScanCodeToKeyCode!(SioScanCode.crsel),
    exsel                   = SioScanCodeToKeyCode!(SioScanCode.exsel),
    kp00                    = SioScanCodeToKeyCode!(SioScanCode.kp00),
    kp000                   = SioScanCodeToKeyCode!(SioScanCode.kp000),
    thousandsseparator      = SioScanCodeToKeyCode!(SioScanCode.thousandsseparator),
    decimalseparator        = SioScanCodeToKeyCode!(SioScanCode.decimalseparator),
    currencyunit            = SioScanCodeToKeyCode!(SioScanCode.currencyunit),
    currencysubunit         = SioScanCodeToKeyCode!(SioScanCode.currencysubunit),
    kpLeftparen             = SioScanCodeToKeyCode!(SioScanCode.kpLeftparen),
    kpRightparen            = SioScanCodeToKeyCode!(SioScanCode.kpRightparen),
    kpLeftbrace             = SioScanCodeToKeyCode!(SioScanCode.kpLeftbrace),
    kpRightbrace            = SioScanCodeToKeyCode!(SioScanCode.kpRightbrace),
    kpTab                   = SioScanCodeToKeyCode!(SioScanCode.kpTab),
    kpBackspace             = SioScanCodeToKeyCode!(SioScanCode.kpBackspace),
    kpA                     = SioScanCodeToKeyCode!(SioScanCode.kpA),
    kpB                     = SioScanCodeToKeyCode!(SioScanCode.kpB),
    kpC                     = SioScanCodeToKeyCode!(SioScanCode.kpC),
    kpD                     = SioScanCodeToKeyCode!(SioScanCode.kpD),
    kpE                     = SioScanCodeToKeyCode!(SioScanCode.kpE),
    kpF                     = SioScanCodeToKeyCode!(SioScanCode.kpF),
    kpXor                   = SioScanCodeToKeyCode!(SioScanCode.kpXor),
    kpPower                 = SioScanCodeToKeyCode!(SioScanCode.kpPower),
    kpPercent               = SioScanCodeToKeyCode!(SioScanCode.kpPercent),
    kpLess                  = SioScanCodeToKeyCode!(SioScanCode.kpLess),
    kpGreater               = SioScanCodeToKeyCode!(SioScanCode.kpGreater),
    kpAmpersand             = SioScanCodeToKeyCode!(SioScanCode.kpAmpersand),
    kpDblampersand          = SioScanCodeToKeyCode!(SioScanCode.kpDblampersand),
    kpVerticalbar           = SioScanCodeToKeyCode!(SioScanCode.kpVerticalbar),
    kpDblverticalbar        = SioScanCodeToKeyCode!(SioScanCode.kpDblverticalbar),
    kpColon                 = SioScanCodeToKeyCode!(SioScanCode.kpColon),
    kpHash                  = SioScanCodeToKeyCode!(SioScanCode.kpHash),
    kpSpace                 = SioScanCodeToKeyCode!(SioScanCode.kpSpace),
    kpAt                    = SioScanCodeToKeyCode!(SioScanCode.kpAt),
    kpExclam                = SioScanCodeToKeyCode!(SioScanCode.kpExclam),
    kpMemstore              = SioScanCodeToKeyCode!(SioScanCode.kpMemstore),
    kpMemrecall             = SioScanCodeToKeyCode!(SioScanCode.kpMemrecall),
    kpMemclear              = SioScanCodeToKeyCode!(SioScanCode.kpMemclear),
    kpMemadd                = SioScanCodeToKeyCode!(SioScanCode.kpMemadd),
    kpMemsubtract           = SioScanCodeToKeyCode!(SioScanCode.kpMemsubtract),
    kpMemmultiply           = SioScanCodeToKeyCode!(SioScanCode.kpMemmultiply),
    kpMemdivide             = SioScanCodeToKeyCode!(SioScanCode.kpMemdivide),
    kpPlusminus             = SioScanCodeToKeyCode!(SioScanCode.kpPlusminus),
    kpClear                 = SioScanCodeToKeyCode!(SioScanCode.kpClear),
    kpClearentry            = SioScanCodeToKeyCode!(SioScanCode.kpClearentry),
    kpBinary                = SioScanCodeToKeyCode!(SioScanCode.kpBinary),
    kpOctal                 = SioScanCodeToKeyCode!(SioScanCode.kpOctal),
    kpDecimal               = SioScanCodeToKeyCode!(SioScanCode.kpDecimal),
    kpHexadecimal           = SioScanCodeToKeyCode!(SioScanCode.kpHexadecimal),
    lctrl                   = SioScanCodeToKeyCode!(SioScanCode.lctrl),
    lshift                  = SioScanCodeToKeyCode!(SioScanCode.lshift),
    lalt                    = SioScanCodeToKeyCode!(SioScanCode.lalt),
    lgui                    = SioScanCodeToKeyCode!(SioScanCode.lgui),
    rctrl                   = SioScanCodeToKeyCode!(SioScanCode.rctrl),
    rshift                  = SioScanCodeToKeyCode!(SioScanCode.rshift),
    ralt                    = SioScanCodeToKeyCode!(SioScanCode.ralt),
    rgui                    = SioScanCodeToKeyCode!(SioScanCode.rgui),
    mode                    = SioScanCodeToKeyCode!(SioScanCode.mode),
    audionext               = SioScanCodeToKeyCode!(SioScanCode.audionext),
    audioprev               = SioScanCodeToKeyCode!(SioScanCode.audioprev),
    audiostop               = SioScanCodeToKeyCode!(SioScanCode.audiostop),
    audioplay               = SioScanCodeToKeyCode!(SioScanCode.audioplay),
    audiomute               = SioScanCodeToKeyCode!(SioScanCode.audiomute),
    mediaselect             = SioScanCodeToKeyCode!(SioScanCode.mediaselect),
    www                     = SioScanCodeToKeyCode!(SioScanCode.www),
    mail                    = SioScanCodeToKeyCode!(SioScanCode.mail),
    calculator              = SioScanCodeToKeyCode!(SioScanCode.calculator),
    computer                = SioScanCodeToKeyCode!(SioScanCode.computer),
    acSearch                = SioScanCodeToKeyCode!(SioScanCode.acSearch),
    acHome                  = SioScanCodeToKeyCode!(SioScanCode.acHome),
    acBack                  = SioScanCodeToKeyCode!(SioScanCode.acBack),
    acForward               = SioScanCodeToKeyCode!(SioScanCode.acForward),
    acStop                  = SioScanCodeToKeyCode!(SioScanCode.acStop),
    acRefresh               = SioScanCodeToKeyCode!(SioScanCode.acRefresh),
    acBookmarks             = SioScanCodeToKeyCode!(SioScanCode.acBookmarks),
    brightnessdown          = SioScanCodeToKeyCode!(SioScanCode.brightnessdown),
    brightnessup            = SioScanCodeToKeyCode!(SioScanCode.brightnessup),
    displayswitch           = SioScanCodeToKeyCode!(SioScanCode.displayswitch),
    kbdillumtoggle          = SioScanCodeToKeyCode!(SioScanCode.kbdillumtoggle),
    kbdillumdown            = SioScanCodeToKeyCode!(SioScanCode.kbdillumdown),
    kbdillumup              = SioScanCodeToKeyCode!(SioScanCode.kbdillumup),
    eject                   = SioScanCodeToKeyCode!(SioScanCode.eject),
    sleep                   = SioScanCodeToKeyCode!(SioScanCode.sleep),
    app1                    = SioScanCodeToKeyCode!(SioScanCode.app1),
    app2                    = SioScanCodeToKeyCode!(SioScanCode.app2),
    audiorewind             = SioScanCodeToKeyCode!(SioScanCode.audiorewind),
    audiofastforward        = SioScanCodeToKeyCode!(SioScanCode.audiofastforward),
    softleft                = SioScanCodeToKeyCode!(SioScanCode.softleft),
    softright               = SioScanCodeToKeyCode!(SioScanCode.softright),
    call                    = SioScanCodeToKeyCode!(SioScanCode.call),
    endcall                 = SioScanCodeToKeyCode!(SioScanCode.endcall)
}

/**
    Converts a Sio keycode to a SDL2 keycode.
*/
pragma(inline, true)
SDL_KeyCode toSDLKeyCode(SioKeyCode code) {
    return cast(SDL_KeyCode)code;
}

/**
    A keyboard event
*/
struct SioKeyboardEvent {

    /**
        Event ID
    */
    SioKeyboardEventID event;

    /**
        Whether the key was pressed
    */
    bool pressed;

    /**
        Whether the key is repeating (being held down)
    */
    bool repeating;

    /**
        Key code
    */
    SioKeyCode keyCode;

    /**
        Keyboard modifier
    */
    SioKeyModifier mod;
    
    /**
        Scan code
    */
    SioScanCode scanCode;
}