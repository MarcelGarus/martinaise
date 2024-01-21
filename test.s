; This is NASM assembly syntax, which similar to Intl syntax.
; nasm -f elf64 -o playground.o playground.s && ld -o playground playground.o

global _start

section .text

_start:
    call _init_heap
    call _init_globals
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
    je .round_up_to_multiple_of_8
    cmp r9, 4
    je .round_up_to_multiple_of_4
    cmp r9, 2
    je .round_up_to_multiple_of_2
    cmp r9, 1
    je .alloc
    jmp .error ; alignment must be 1, 2, 4, or 8
  .round_up_to_multiple_of_2:
    add r10, 1
    and r10, 0fffffffffffffffeH
    jmp .alloc
  .round_up_to_multiple_of_4:
    add r10, 3
    and r10, 0fffffffffffffffcH
    jmp .alloc
  .round_up_to_multiple_of_8:
    add r10, 7
    and r10, 0fffffffffffffff8H
  .alloc:
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
