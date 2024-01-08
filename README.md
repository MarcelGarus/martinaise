# Martinaise

A small, statically typed, low-level language.

To get a feeling for how Martinaise programs look, take a look at the files in the `advent` folder.
To get an in-depth understanding of Martinaise, take a look at the most recent folder in the compiler folder.

> [!IMPORTANT]
> Martinaise is just a small recreational project to get familiar with monomorphization and Zig.
> Martinaise is **not optimized for use**, but for fun during implementation.
> Martinaise is **not meant for serious projects**.
>
> Some consequences:
> Martinaise has no error-resilient parser (it gives up at the first error), does not support multiple files, etc.

## Why?

- I've never written a low-level language with monomorphization.
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
   Martinaise programs can be compiled and run using `./martinaise c path/to/program.mar > output.c && cc output.c -o output && ./output`


```
```


## Language History

The language evolved dramatically while writing the Martinaise 0 compiler.
All other compilers are written in Martinaise itself.

Each compiler can be compiled using the previous compiler.
The standard library the compiler uses is always in the same folder as the compiler itself.

For example, compiler 1 can be compiled using compiler 0.
It uses the compiler 1 stdlib, but it's designed to compile the compiler 2 stdlib.

- 0: The first compiler, written in Zig.
- 1: A compiler written in Martinaise.
  - makes `orelse` customizable (not just work on `Maybe`)
  - introduces `Str`, `Char`, `OsStr`
  - ints support radixes such as `8#666`
  - fixes inner variables replacing ones in outer scopes
