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

Install Zig.
To bootstrap the compiler, run the Makefile:

```bash
make
```

This will create a `martinaise` executable, which you can use to compile programs:

```
./martinaise c advent/day1.mar > output.c && cc output.c -o day1
```

TODO: Make it possible to bootstrap without Zig by caching having the compiled `martinaise_1.c` in the repo.

## Language History

The language evolved dramatically while writing the Martinaise 0 compiler.
All other compilers are written in Martinaise itself.

Each compiler can be compiled using the previous compiler.
The standard library the compiler uses is always in the same folder as the compiler itself.

For example, compiler 1 can be compiled using compiler 0.
It uses the compiler 1 stdlib, but it's designed to compile the compiler 2 stdlib.

- 0: The first compiler, written in Zig.
- 1: A compiler written in Martinaise.
  - makes orelse customizable (not just work on Maybe)
  - introduces Str, Char, OsStr
