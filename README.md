# Futhark Tutorial for Absolute Nim Beginners

This is a basic tutorial for binding C code to Nim using **Futhark**, covering both:
- basic `importc` usage
- creating a Nim wrapper for a C library


## Installing Futhark

The only requirement for **Futhark** is the `clang` compiler.

- **Windows**: install the executable in [github releases](https://github.com/llvm/llvm-project/releases/tag/llvmorg-18.1.8)
- **Linux** (Debian-based): run `sudo apt install clang libclang-dev`
- **Linux** (Void Linux): run `sudo xbps-install clang clang17-devel`
- **macOS**: run `xcode-select --install`

If `clang` is installed in the system path, run:

```bash
nimble install futhark
```

If not, search for `libclang.lib` or `libclang.so` depending on your system and run:

```bash
nimble install --passL:"-L<path to clang library>" futhark
```


## A basic C library

Let's create basic C code to import:

`csalute/hello.c`:
```c
#include <stdio.h>

void hello(char * name)
{
    csalute_printf("Hello %s from C!\n", name);
}
```

`csalute/hello.h`:
```h
#ifndef HELLO_H
#define HELLO_H

void csalute_hello(char * name);

#endif
```

## Importing the C code

Importing the C code into a Nim file is straightforward.

First add a **Futhark** dependency to your `.nimble` file:

`salute.nimble`
```nim
requires "futhark >= 0.15.0"
```

Then `import futhark` on your code, and use the `importc` macro declaring both the path where to find our C code, and the header file to import:

`src/salute.nim`
```nim
import futhark

importc:
  path "../csalute"
  "hello.h"
```

Instruct the Nim compiler to compile the C code together with the Nim code by adding the following pragma:

`src/salute.nim`
```nim
{.compile: "csalute/hello.c".}
```

We're ready to use our C code in Nim:

`src/salute.nim`
```nim
when isMainModule:
  csalute_hello("Row".cstring)
```

Notice that Nim values must be converted to C types, usually using `cstring`, `cint`, `cfloat`, etc.

Running `nimble build && ./bin/salute` should output:
```
Hello Row from C!
```


## Building against a library

While this is not strictly specific to **Futhark**, it's common to want to build against a library instead of compiling against C files.

Let's create a basic `libsalute.a` library:

`csalute/build.sh`
```bash
#/bin/bash

clang -c hello.c -o hello.o
ar rcs libhello.a hello.o
rm hello.o
```

Make it executable, and run it before building our Nim code:

`salute.nimble`
```nim
before build:
  exec "cd csalute && ./build.sh"
```

Now to tell Nim to link against our library, change the compile pragma:

`src/salute.nim`
```nim
#{.compile: "csalute/hello.c".}
#{.passL: "csalute/hello.o".}
{.passL: "csalute/libhello.a".}
```

> **Note:** The compiler/linker pragmas can be moved to a `compile.nim` file and then import it. This has the advantage of keeping the main code clean while not complicating the `.nimble` file with build instructions specific to each module of your project.

> **Note:** These steps work well for simple C projects, but building a library is usually not straightforward, it's always a good idea to know how to do so _before_ trying to integrate it into your Nim project using **Futhark**.


## Creating a wrapper

If you just want to import a C library into your project, using **Futhark**'s `importc` is more than enough. However, this requires declaring a dependency with **Futhark** in our `.nimble` file and, more importantly, installing **Futhark** for anyone using our codebase.

It is possible to generate a wrapper so that these two requirements are no longer needed, this is great since **Futhark**'s installation process is not trivial.


### Create the generator

First, let's create a `gen` directory with the following Nim files:

`gen/paths.nim`
```nim
from std/os import parentDir, `/`

const rootDir* = currentSourcePath.parentDir()/".."
const srcDir* = rootDir/"src"
const csaluteDir* = rootDir/"csalute"
```

`gen/generator.nim`
```nim
import futhark
import paths
from std/os import parentDir, `/`

importc:
  outputPath srcDir/"csalute.nim"
  path csaluteDir
  "hello.h"
```

The `importc` block now has an `outputPath` declaration, which tells **Futhark** to generate a Nim file with the binding code at the specified path.

> **Note:** the Nim files in the `gen` directory are not compiled, they are only used to generate the binding code.


### Update `salute.nim`

Remove the `importc` block from `salute.nim`.
Import the generated `csalute.nim` file.

`src/salute.nim`
```nim
import csalute
```

The `csalute.nim` file will be generated in the `src` directory.


### Update the `.nimble` file

Modify the `.nimble` file to generate the binding code before building:

`salute.nimble`
```nim
before build:
  exec "cd csalute && ./build.sh"
  exec "nim c -r -d:futharkRebuild -d:opirRebuild gen/generator.nim"
  exec "rm gen/generator"
```

- The `futharkRebuild` flag rebuilds the binding code when changes are made to the `importc` block.
- The `opirRebuild` flag rebuilds the binding code when the C code changes.
- Also remove the built generator, it's not needed after the binding code is generated. If it's not removed, the bindings are usually not rebuilt.

Run `nimble build && ./bin/salute` to test the wrapper.
