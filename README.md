# Martinaise

A small, statically typed, low-level language.

To get a feeling for how Martinaise programs look, take a look at the files in the `advent` folder.
To get an in-depth understanding of Martinaise, take a look at the `stdlib.mar`. It's well-documented.

## Don't Use It

Martinaise is just a small recreational project to get familiar with monomorphization and Zig.
Martinaise is **not optimized for use**, but for fun during implementation.
Martinaise is **not meant for serious projects**.

Some consequences:
Martinaise has no robust parser (it gives up at the first error), does not support multiple files, etc.

## Usage

```bash
zig build run && gcc output.c && ./a.out
```

## Why?

- I've never written a low-level language with monomorphization.
  This project scratches that itch.
- I've only written small projects in Zig.
  With this project, I try to get more familiar with Zig.
