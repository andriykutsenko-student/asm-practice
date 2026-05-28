; practice3.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .data
    newline db 10               ; memory: newline character

SECTION .bss
    buf resb 8                  ; memory: buffer for digits (max 6 digits)

SECTION .text
_start:
    ; logic: number to print (range 0..999999)
    mov eax, 123456

    ; parse: convert integer in eax to decimal string
    mov ecx, buf                ; memory: point to start of buffer
    add ecx, 7                  ; point to end of buffer
    mov ebx, 10                 ; math: base-10 divisor
    mov edi, 0                  ; loops: digit counter

convert_loop:
    xor edx, edx                ; math: clear edx before division
    div ebx                     ; math: eax = eax/10, edx = remainder
    add dl, '0'                 ; parse: convert digit to ASCII
    dec ecx                     ; memory: move pointer left
    mov [ecx], dl               ; memory: store digit in buffer
    inc edi                     ; loops: increment counter
    test eax, eax               ; logic: check if done
    jnz convert_loop            ; loops: continue if quotient != 0

    ; I/O: write number to stdout
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    mov edx, edi                ; parse: number of digits
    int 0x80

    ; I/O: write newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; I/O: exit
    mov eax, 1                  ; sys_exit
    xor ebx, ebx
    int 0x80