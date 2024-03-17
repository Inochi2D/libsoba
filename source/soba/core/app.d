module soba.core.app;
import soba.core.events;
import soba.widgets.window.mainwindow;
import numem.all;
import numem.mem.map;
import cairo;
import bindbc.sdl;
import soba.core.window;

@nogc:

/**
    Initialize Soba
*/
void sbInit() {
    auto sdlSupport = loadSDL("libSDL2.dylib");
    if (sdlSupport == SDLSupport.noLibrary)
        throw nogc_new!Exception("Could not find a valid SDL2 library!");

    SDL_Init(SDL_INIT_EVERYTHING);

    auto cairoSupport = loadCairo();
    if (cairoSupport == cairoSupport.noLibrary)
        throw nogc_new!Exception("Could not find a valid Cairo library!");
}

struct SbApplication {
nothrow @nogc:
public:
    nstring appName;
}

void sbRunApplication(SbMainWindow window) {
    window.show();
    try {
        while(!window.isCloseRequested()) {
            if (sbPumpEventQueue()) break;

            window.update();
            window.draw();
        }

        nogc_delete(window);
    } catch(Exception ex) {
        import core.stdc.stdio : printf;
        nstring str = ex.msg;
        printf("FATAL ERROR: %s", str.toCString());
        nogc_delete(ex);
    }
}