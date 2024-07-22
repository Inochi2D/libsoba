<p align="center">
  <img width="256" height="256" src="./logo.png">
</p>


# Soba
Soba is a **work in progress** permissively licensed cross platform UI toolkit for D. The toolkit targets productivity apps which benefit from real-time rendering capabilities.

Soba is mainly designed after the needs of the Inochi2D project, as such any feature requests that don't neatly fit in to our needs may take a while to be implemented.

## What to expect
Soba aims to support writing individual applications for Windows, macOS, Linux (and the BSDs that support Vulkan).  
With a design combining the sensibilities of retained UI and immediate UI Soba aims to work well with multimedia applications.

Soba is however only made for application development, it is not suitable for things such as creating desktop environments.

## Soba submodules
Soba consists of a main library and multiple smaller reusable sub-libraries.  
These libraries provides core functionality in a more cross platform way.

The current modules are:  

 * `soba:sio` - Soba I/O  
   Provides cross-platform access to system functions, such as window creation, event handling. 
   file dialogs, and more. 

 * `soba:ssk` - Soba Scene Kit  
   Provides a portable scene graph for compositing UI surfaces using GPUs.  

 * `soba:canvas` - Soba Canvas  
   Provides vector rendering functionality.  


## How do I open a Window?

The API has undergone a major restructuring so currently the widget system is not usable.