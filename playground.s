; This is NASM assembly syntax, which similar to Intl syntax.
; nasm -f elf64 -o playground.o playground.s && ld -o playground playground.o

global _start

section .rodata
  msg: db "Hello, world!", 10
  msglen: equ $ - msg

section .text

; add(U64, U64): U64
mar_add:
  ; stack: callee@0 a@8 b@16 return_address@24
  mov rax, [rsp + 8]
  add rax, [rsp + 16]
  mov rbx, [rsp + 24]
  mov [rbx], rax
  ret

_start:
  ; syscalls:
  ; - rax is the syscall number
  ; - arguments go in rdi, rsi, rdx, rcx, r8, r9
  ; - run syscall instruction
  ; - return value is in eax
        push 0
        mov r8, 8
  .l_0: mov r9, 8
        ; write = 1, stdout = 1
        mov rax, 1
        mov rdi, 1
        mov rsi, msg
        mov rdx, msglen
        syscall
        ; subtract loop variable
        sub r8, 1
        cmp r8, 0
        jnz .l_0
        ; call add(7, 35)
        push rsp
        push 35
        push 7
        call mar_add
        pop r9
        pop r9
        pop r9
        mov rdi, [rsp]
        ; exit = 60, success = 0
        mov rax, 60
        ;mov rdi, 0
        syscall
        pop r9
