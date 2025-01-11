# newsdlang
SDLang/XDL reader and writer

See SDLang specifications here: https://github.com/dlang-community/SDLang-D/wiki/Language-Guide

See XDL specifications in file XDLspecs.md

# Current status

* Lot of its features are untested at the moment, unittests and other testcases are being written at the moment.
* SDL-style datetime parsing have not been implemented yet.
* KDL parsing/compatibility might be dropped, not implemented yet due to some of its special.
* DOM and its related API will likely stay the same, but with more features added and things refined.
* XDL specifications are not 100% finalized, and some features might get added/modified.
* It has a mostly working DOM reader and writer in `newsdlang.dom`, and a more manual streaming parser in `newsdlang.parser` if someone wants to directly convert *DL files to data without the DOM overhead.
