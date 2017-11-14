Cross-language bindings for libpasta
====================================

This library is intended for developers wishing to extend or improve the 
existing language bindings for [libpasta](https://libpasta.github.io/).

For existing language bindings, and ways to install in those languages,
please see the information
[here](https://libpasta.github.io/other-languages/overview/).

SWIG and libpasta
------------------

The language bindings produced here are through using
[SWIG](http://www.swig.org/).

The following logic is used to produce the language bindings:

We define the C header file in [pasta.h](./pasta.h) which corresponds to the
Rust definitions from the
[libpasta-ffi](https://github.com/libpasta/libpasta-ffi) crate (included as a
submodule for convenience).

This header file is now compatible with using SWIG, and the [pasta.i](./pasta.i)
file produces basic bindings with just the `%include <pasta.h>` line.

The rest of the [pasta.i](./pasta.i) file is dedicated to language-specific
requirements, and convenience code, such as automatically deallocating
the Rust `String` objects required to call the library.

We produce code for each support language using the [Makefile](./Makefile).
In general, this runs SWIG over the definition file to produce wrapper code,
and compiles it into a single `pasta.so` file (name depending on the language
and system preferences), and language-specific code to use this library.

Current Status
--------------

The entire libpasta project is still in an early phase. These bindings are 
designed for ease of use, and early testing.

For now, libpasta is compiled dynamically, and included as a dependency in the
produced wrapper, which means linking all the required shared libraries when
building the wrappers. This step is potentially troublesome. In the future, we
would like libpasta to be a shared system library.

Currently these bindings are designed for `x86_64-unknown-linux-gnu` 
(as per
[Rust platform support](https://forge.rust-lang.org/platform-support.html)),
but we are trying to increase support to other platforms.
