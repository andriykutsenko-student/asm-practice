; practice4.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .data
    newline db 10               ; memory: newline character

SECTION .bss
    buf resb 256                ; memory: buffer for input string
    outbuf resb 8               ; memory: buffer for output digits

SECTION .text
_start:
    ; I/O: read line from stdin
    mov eax, 3                  ; sys_read
    mov ebx, 0                  ; stdin
    mov ecx, buf
    mov edx, 255
    int 0x80

    ; parse: convert string in buf to integer, result in eax
    mov esi, buf                ; memory: pointer to input buffer
    xor eax, eax                ; math: accumulator = 0
    xor ecx, ecx                ; loops: index = 0

parse_loop:
    movzx edx, byte [esi]       ; memory: load next character
    cmp dl, 10                  ; logic: check for newline
    je parse_done
    cmp dl, 13                  ; logic: check for carriage return
    je parse_done
    cmp dl, 0                   ; logic: check for null
    je parse_done
    sub dl, '0'                 ; parse: convert ASCII to digit
    imul eax, eax, 10           ; math: shift accumulator left
    add eax, edx                ; math: add new digit
    inc esi                     ; loops: advance pointer
    jmp parse_loop

parse_done:
    ; logic: number is now in eax, convert back to string (from practice3)
    mov ecx, outbuf             ; memory: point to output buffer
    add ecx, 7                  ; memory: point to end of buffer
    mov ebx, 10                 ; math: base-10 divisor
    mov edi, 0                  ; loops: digit counter

convert_loop:
    xor edx, edx                ; math: clear edx before division
    div ebx                     ; math: eax = eax/10, edx = remainder
    add dl, '0'                 ; parse: convert digit to ASCII
    dec ecx                     ; memory: move pointer left
    mov [ecx], dl               ; memory: store digit
    inc edi                     ; loops: increment counter
    test eax, eax               ; logic: check if done
    jnz convert_loop            ; loops: continue if not zero

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