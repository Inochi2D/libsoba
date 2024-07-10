module soba.sio;
import numem.all;
import bindbc.sdl;

@nogc nothrow:

/**
    Initializes SIO.

    Returns true if SIO was initialized.
*/
bool sioInit() {
    SDLSupport support = loadSDL();
    return support != SDLSupport.noLibrary;
}