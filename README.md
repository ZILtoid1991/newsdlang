**Notice: Project moved to the following link:** https://codeberg.org/ZILtoid1991/newsdlang

# newsdlang
SDLang/XDL reader and writer

See SDLang specifications here: https://github.com/dlang-community/SDLang-D/wiki/Language-Guide

See XDL specifications in file XDLspecs.md

# Current status

* Lot of its features are untested at the moment, unittests and other testcases are being written at the moment.
* SDL-style datetime parsing have not been implemented yet.
* Previously advertised KDL compatibility plans dropped.
* DOM and its related API will likely stay the same, but with more features added and things refined.
* XDL specifications are not 100% finalized, and some features might get added/modified.
* It has a mostly working DOM reader and writer in `newsdlang.dom`, and a more manual streaming parser in `newsdlang.parser` if someone wants to directly convert *DL files to data without the DOM overhead.

## Known issues

### Severe

* Floating-point number parsing is unstable, with some very long floats causing issues stemming from limited precision, especially of the 64 bit integers being used during the parsing process. Some mitigations have been done, but more needs to be done in the future.

### Low priority

* Comments put in front of a tag are positioned incorrectly.
