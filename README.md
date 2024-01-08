# Martinaise

A small, statically typed, low-level language.

To get a feeling for how Martinaise programs look, take a look at the files in the `advent` folder.
To get an in-depth understanding of Martinaise, take a look at the standard library and the compiler, both of which are in the compiler folder.

> [!IMPORTANT]
> Martinaise is just a small recreational project to get familiar with monomorphization and Zig.
> Martinaise is **not optimized for use**, but for fun during implementation.
> Martinaise is **not meant for serious projects**.
>
> Some consequences:
> Martinaise has no error-resilient parser (it gives up at the first error), does not support multiple files, etc.

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
   Martinaise programs can be compiled and run using `./martinaise c path/to/program.mar > output.c && cc output.c -o output && ./output`

## Quick Tour

This tour assumes you know other programming languages.

### Types

Martinaise supports structs and associated enums.
You can write generic data structures using brackets.

```martinaise
struct Foo { a: U8, b: Str }
enum Maybe[T] { some: T, none }
```

### Control Flow

```martinaise
| This is a comment.

var foo = 3  | variable

if true then println("Hello")

println(
  switch maybe
  case some(a) "a is {a}"
  case none "Nothing to see"
)

println(if maybe is some(a) then "foo with {a}" else "blub")

loop if stdin.read() is #o then break else foo = foo.inc()
```

### Functions

Only used functions are type-checked, always with concrete types.
For generic functions, each combination of type arguments will result in a new compiled function ("monomorphization").
Functions use uniform calling syntax (`a.foo(b)` is the same as `foo(a, b)`).
Functions can be overloaded (multiple functions can have the same name as long as for each function call, the type of the arguments make it clear which function is meant).

```martinaise
fun foo(num: U8): U64 { num.to_U64() }
fun foo(str: Str): U64 { str.len() }
fun foo[T](maybe: Maybe[T]): U64 {
  switch maybe
  case some(a) a.foo()
  case none 3
}

fun main(): Never {
  var three = Maybe[U8].none.foo()
  var four = Maybe.some(4).foo()
  var five = "Hello".foo()

  exit(0:U8)
}
```

## Language History

The language evolved substantially while writing the first Martinaise compiler in Zig.
All other compilers are written in Martinaise itself.

Each compiler can be compiled using the previous compiler.
Each `compiler/<version>` folder contains a compiler and the standard library that this compiler can compile.

For example, compiler 1 uses the compiler 0 stdlib and can be compiled using compiler 0.
It's designed to compile the compiler 1 stdlib.

- 0: The first compiler, written in Zig.
- 1: A compiler written in Martinaise.
  - makes `orelse` customizable (not just work on `Maybe`)
  - ints support radixes such as `8#666`
  - fixes inner variables replacing ones in outer scopes
  - ensure all struct fields are set during creation
  - support global variables
  - allow omitting types
  - introduces `Str`, `Char`, `OsStr`
  - char literals use `#` instead of `'`
  - string literals support interpolation, including metaness
