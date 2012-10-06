# xchatd
*xchatd* is a plugin interface for XChat built on the C interface,
allowing for plugins written in the D programming language.

Bindings for the original C interface are also included.

## Directory Structure

 * `xchat` - source package containing both the high and low level interfaces.
 * `visuald` - [VisualD](http://www.dsource.org/projects/visuald) project files.
 * `lib` - library files for the high level interface (when built).
 * `example` - *xchatd* examples.

## Documentation
Documentation coming soon.

For documentation on the C interface, see the
[HexChat plugin documentation](https://github.com/hexchat/hexchat/wiki/Plugins).

## Example
See the `example` subdirectory for two ports of the AutoOp example plugin found
in the official documentation; one port using the high level interface and one faithful port using the original C API.
The `visuald` subdirectory contains [VisualD](http://www.dsource.org/projects/visuald)
project files for the examples. The plugin DLLs are output to the `example/bin` subdirectory.
Move a plugin DLL to the `addons` directory of your XChat configuration directory to test it.

## License
*xchatd* is licensed under the terms of the MIT license (see the [LICENSE.txt](https://github.com/JakobOvrum/xchatd/blob/master/LICENSE.txt) file for details).
