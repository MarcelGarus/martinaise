# Martinaise

A small, statically typed, low-level language.

For a quick tour of the language, have a look at the [tour.mar](tour.mar) file.
To get a feeling for how Martinaise programs look, take a look at the files in the [advent](advent/) folder.
To get an in-depth understanding of Martinaise, take a look at the standard library and the compiler, both of which are in the compiler folder.

> [!IMPORTANT]
> Martinaise is mostly a small recreational project.
> Martinaise is **not meant for serious projects**.

## Why?

- I wanted to write a low-level, statically-typed language.
  Martinaise has `Address`es, references, and a `malloc` implementation.
  Implementing monomorphizing and overloading was fun.
- I wanted to write an entire compiler, not just an LLVM frontend.
  This compiler goes from source code all the way to x86_64 machine code.
  The compiler computes efficient memory layouts, the functions have their own calling convention, etc.
- I wanted to write a project in [Zig](https://ziglang.org).
  Of course, by now, the compiler is written in Martinaise itself.

## Usage

Martinaise is self-hosting – the compiler is written in Martinaise itself.
So, you first need to bootstrap Martinaise.

1. In the command line, navigate to the project root (the folder where this README is).
2. Install [Soil](https://github.com/MarcelGarus/soil).
   The soil executable should be somewhere in your path.
3. **Option A:** Install [Zig](https://ziglang.org).  
   **Option B (TODO: fix this):** Run `make skip-zig`.
   This repo contains the Soil byte code of a stable self-hosted compiler.
   This command starts with that instead of compiling all the way from the original compiler written in Zig.
4. Run `make`. This builds all compiler generations. The newest compiler will be placed into the project root as the `martinaise` executable.
5. Run `soil martinaise.soil help` for help and go from there.  
   Martinaise programs can be compiled and run using `soil martinaise.soil run tour.mar`.

## Editor

> [!IMPORTANT]
> The editor is still a work in progress.

There's an editor for Martinaise written in Martinaise.
It's not up-to-date (and uses compiler 4, if I'm correct).
Run `./martinaise compile editor.mar` to get the `editor`.
Then run `./editor some-file.mar` to edit a file.
Special thanks to @antoniusnaumann for the color theme.

## Language History

The language evolved substantially over time.
Each `compiler/<version>` folder contains a compiler.
Each compiler can be compiled using the previous compiler.

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
