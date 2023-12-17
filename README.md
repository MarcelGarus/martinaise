# Martinaise

A small, statically typed, low-level language.

Take a look at the files in the `advent` folder.

## This language is not optimized for use, but for fun during implementation

This language is not meant to become a programming language for serious projects.
It's just a small recreational project to get familiar with monomorphization and Zig.

It has no robust parser (it gives up at the first error), does not support multiple files, etc.

## Usage

```bash
zig build run && gcc output.c && ./a.out
```

## Why?

- I've never written a low-level language with monomorphization.
  This project scratches that itch.
- I've only written small projects in Zig.
  With this project, I try to get more familiar with Zig.
