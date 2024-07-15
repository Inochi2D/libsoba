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
    if (support != SDLSupport.noLibrary) {
        SDL_Init(SDL_INIT_EVERYTHING);
        return true;
    }
    return false;
}