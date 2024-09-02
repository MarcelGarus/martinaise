# Martinaise

A small, statically typed, low-level language.

For a quick tour of the language, have a look at the [tour.mar](tour.mar) file.
To get a feeling for how Martinaise programs look, take a look at the files in the [advent](advent/) folder.
To get an in-depth understanding of Martinaise, take a look at the standard library and the compiler, both of which are in the compiler folder.

> [!IMPORTANT]
> Martinaise is just a small recreational project to get familiar with monomorphization and Zig.
> Martinaise is **not optimized for use**, but for fun during implementation.
> Martinaise is **not meant for serious projects**.
>
> Some consequences:
> Martinaise has no error-resilient parser (it gives up at the first error), does not support multiple files, only works on x86_64, etc.

## Why?

- I've never written a low-level, statically-typed language.
  Doing so enables features such as monomorphization and overloading, which I find interesting to implement.
  This project scratches that itch.
- I've only written small projects in Zig.
  With this project, I try to get more familiar with Zig.

## Usage

Martinaise is self-hosting – the compiler is written in Martinaise itself.
So, you first need to bootstrap Martinaise.

1. In the command line, navigate to the project root (the folder where this README is).
2. **Option A:** Install [Zig](https://ziglang.org).  
   **Option B (TODO: support this):** Run `make skip-zig`. The first compiler written in Martinaise was compiled into C and is included in this repo. This command compiles this (generated, unreadable) C code instead of compiling all the way from the original compiler written in Zig.
3. Run `make`. This builds all compiler generations. The newest compiler will be placed into the project root as the `martinaise` executable.
4. Run `./martinaise help` for help and go from there.  
   Martinaise programs can be compiled and run using `./martinaise compile tour.mar && ./tour`

## Editor

> [!IMPORTANT]
> The editor is still a work in progress.

There's an editor for Martinaise written in Martinaise.
Run `./martinaise compile editor.mar` to get the `editor`.
Then run `./editor some-file.mar` to edit a file.
Special thanks to @antoniusnaumann for the color theme.

## Language History

The language evolved substantially while writing the first Martinaise compiler in Zig.
All other compilers are written in Martinaise itself.

Each compiler can be compiled using the previous compiler.
Each `compiler/<version>` folder contains a compiler.

- Compiler 0
  - Written in Zig
- Compiler 1
  - Written in Martinaise (every compiler after this as well)
  - Makes `orelse` customizable (not just work on `Maybe`)
  - Ints support radixes such as `8#666:U32`
  - Fixes inner variables replacing ones in outer scopes
  - Ensures all struct fields are set during creation
  - Supports global variables
  - Allows omitting types
  - Introduces `Str`, `Char`, `OsStr`
  - Char literals use `#` instead of `'`
  - String literals support interpolation, including metaness
- Compiler 2
  - Uses all the new features, making it more concise
  - Produces the exact same C output as compiler 1
  - Adds buffered stdout stream for writing the C output faster
  - Can compile itself
- Compiler 3
  - Replaces the C backend with an x86_64 assembly backend
  - Adds opaque types and asm functions
  - The integer types and their operations are no longer built-into the language, but implemented as opaque types
  - Adds support for operators
- Compiler 4
  - Supports FASM as well as NASM
- Compiler 5
  - Compiles to [Soil byte code](https://github.com/MarcelGarus/soil) instead of FASM or NASM
  - Parses ASM functions that contain byte code instructions
  - Replaces `orelse` with `and` and `or`
  - Supports imports.
- Compiler 6
  - Replaces specific int types (`U8`, `U64`, `I8`, `I64`) with simpler `Int` and `Byte` (which correspond to `I64` and `U8`, respectively)
- Compiler 7
  - Adds builtin functions for fuzzing (`write_debug`, `generate`, `mutate`)
- Compiler 8
  - Adds fuzz command
