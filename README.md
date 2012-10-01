# XChat Plugin Interface for D
This is a binding for the XChat plugin interface, with an included example.
The reference C header is included alongside the D interface.

## [Documentation](http://xchat.org/docs/plugin20.html)
See the official [XChat plugin documentation](http://xchat.org/docs/plugin20.html).
The D interface is nearly identical; some strings have been constified for better
compatibility with D string literals.

## Example
See the `example` subdirectory for a port of the AutoOp example plugin found
in the official documentation. The `visuald` subdirectory contains [VisualD](http://www.dsource.org/projects/visuald)
project files for the example. The plugin DLL is output to the `bin` subdirectory.
Move the DLL to the `plugins` directory of your XChat client to test it.

## License
This project is public domain.