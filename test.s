; This is NASM assembly syntax, which similar to Intl syntax.
; nasm -f elf64 -o playground.o playground.s && ld -o playground playground.o

global _start

section .text

main:
  ret

_start:
    call _init_heap
    call _init_globals
  .prep_args:
    ; We need to put the args in a Slice[Str].
    pop r8       ; num args
    mov r9, rsp  ; cursor through the original c-style args
    mov r10, r8  ; how much memory to reserve for the slice data
    shl r10, 4   ; for each arg, there's a Str in the data (16 bytes)
    sub rsp, r10 ; reserve the amount of data
    mov r10, rsp ; cursor through the Martinaise-style args
    mov r11, r9  ; end of the Martinaise-style args
    mov r15, rsp ; start of the Martinaise-style args
  .find_next_arg:
    cmp r10, r11
    je .call_main
    mov r12, [r9] ; the start of the C-style string
    mov r13, r12  ; cursor for finding the str length
  .find_len:
    mov r14b, [r13]
    cmp r14, 0
    je .add_arg
    inc r13
    jmp .find_len
  .add_arg:
    sub r13, r12       ; the str length
    mov [r10], r12     ; the data: &Char of the str slice
    mov [r10 + 8], r13 ; the len: U64 of the str slice
    add r10, 16        ; advance cursor through Martinaise args
    add r9, 8          ; advance cursor through C args
    jmp .find_next_arg
  .call_main:
    sub rsp, 16       ; reserve memory for the surrounding slice
    mov [rsp], r15    ; data: &Str of the args slice
    mov [rsp + 8], r8 ; len: U64 of the args slice
    push rsp          ; where to store the returned Never
  call main

    mov r8, [_globals.num_hello]
  .loop:
    cmp r8, 0
    jz .end
    dec r8
    mov rax, 1 ; write
    mov rdi, 1 ; stdout
    mov rsi, _str_0.data
    mov rdx, _str_0.len
    syscall
    jmp .loop
  .end:
    mov r14, [_heap.head]
    push r14
    mov r8, 1
    mov r9, 1
    call _malloc
    mov r8, 5
    mov r9, 4
    call _malloc
    mov r8, 4000
    mov r9, 8
    call _malloc
    mov r8, 100
    mov r9, 4
    call _malloc
    mov r14, [_heap.head]
    pop r15
    sub r14, r15
    ; mov rax, 1
    ; mov rdi, 1
    ; mov rsi, r14
    ; mov rdx, 1
    ; syscall
    mov rax, 60 ; exit
    mov rdi, r14  ; success
    syscall

_init_globals:
  mov r8, 0
  mov [_globals.num_hello], r8
  ret

_init_heap:
  mov rax, 12 ; brk
  mov rdi, 0  ; brk(0) returns the break (where the data segment ends)
  syscall
  mov [_heap.head], rax
  mov [_heap.end], rax
  ret

_malloc:
    ; Does not follow the Martinaise calling convention. Expects the amount to
    ; allocate in r8 and the alignment in r9. Returns the address in rax.
    mov r10, [_heap.head] ; the address of the newly allocated memory
    cmp r9, 8
    jg .error ; alignment must be <= 8
    popcnt r11, r9
    cmp r11, 1
    jne .error  ; alignment must be 1, 2, 4, or 8
    ; rounding up to alignment means r10 = (r10 + (r9 - 1)) & bitmask for lower
    ; for example, for alignment 4: r10 = (r10 + 3) & ...1111100
    add r10, r9
    dec r10
    neg r9 ; make r9 a bitmask; ...1111 or ...1110 or ...1100 or ...1000
    and r10, r9
    ; r10 is now rounded up so that it matches the required alignment
    ; find the end of the allocated data -> r11
    mov r11, r10
    add r11, r8
    cmp r11, [_heap.end]
    jge .realloc
    mov [_heap.head], r11
    mov rax, r10
    ret
  .realloc:
    ; find the amount to allocate
    mov r12, [_heap.end]
  .find_new_brk:
    add r12, 4096
    cmp r12, r11
    jl .find_new_brk
  .found_new_brk:
    push r10
    push r11
    mov rax, 12  ; brk
    mov rdi, r12 ; brk(r12) moves the break to r12
    syscall
    pop r11
    pop r10
    cmp rax, r12
    jl .error ; setting the brk failed
    mov [_heap.head], r11
    mov [_heap.end], rax
    mov rax, r10
    ret
  .error:
    mov rax, 0
    ret


section .bss

_heap:
  align 8
  .head: resb 8
  .end: resb 8

_globals:
  .num_hello resb 8
  .true resb 1
  .false resb 1


section .rodata

_str_0:
  .data db "Hello, world!", 10
  .len: equ $ - .data
