; practice5.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .data
    newline db 10               ; memory: newline character

SECTION .bss
    buf    resb 256             ; memory: input buffer
    outbuf resb 16              ; memory: output buffer for itoa

SECTION .text
_start:
    ; I/O: read line from stdin
    mov eax, 3                  ; sys_read
    mov ebx, 0                  ; stdin
    mov ecx, buf
    mov edx, 255
    int 0x80

    ; parse: convert string to integer (atoi), result in eax
    mov esi, buf
    xor eax, eax

atoi_loop:
    movzx edx, byte [esi]       ; memory: load next char
    cmp dl, 10                  ; logic: newline?
    je atoi_done
    cmp dl, 13                  ; logic: carriage return?
    je atoi_done
    cmp dl, 0                   ; logic: null?
    je atoi_done
    sub dl, '0'                 ; parse: ASCII to digit
    imul eax, eax, 10           ; math: shift accumulator
    add eax, edx                ; math: add digit
    inc esi                     ; loops: next char
    jmp atoi_loop

atoi_done:
    ; logic: save original number
    mov ebx, eax                ; memory: ebx = x

    ; math: compute sumDigits(x)
    xor edi, edi                ; math: digit sum = 0
    mov eax, ebx                ; math: eax = x

sum_loop:
    xor edx, edx                ; math: clear edx before div
    mov ecx, 10                 ; math: divisor
    div ecx                     ; math: eax = eax/10, edx = remainder
    add edi, edx                ; math: add digit to sum
    test eax, eax               ; logic: check if done
    jnz sum_loop                ; loops: continue

    ; parse: print sumDigits(x)
    mov eax, edi
    call itoa_print

    ; math: compute len(x) = number of digits
    xor edi, edi                ; math: digit count = 0
    mov eax, ebx                ; math: eax = x

len_loop:
    xor edx, edx                ; math: clear edx before div
    mov ecx, 10                 ; math: divisor
    div ecx                     ; math: divide by 10
    inc edi                     ; loops: count digit
    test eax, eax               ; logic: check if done
    jnz len_loop                ; loops: continue

    ; parse: print len(x)
    mov eax, edi
    call itoa_print

    ; I/O: exit
    mov eax, 1                  ; sys_exit
    xor ebx, ebx
    int 0x80

; parse: convert eax to string and print
itoa_print:
    push ebx                    ; memory: save ebx
    push esi                    ; memory: save esi
    mov ecx, outbuf             ; memory: point to buffer
    add ecx, 15                 ; memory: point to end
    xor esi, esi                ; loops: digit counter

itoa_loop:
    xor edx, edx                ; math: clear edx
    mov ebx, 10                 ; math: divisor
    div ebx                     ; math: eax/10
    add dl, '0'                 ; parse: digit to ASCII
    dec ecx                     ; memory: move pointer left
    mov [ecx], dl               ; memory: store digit
    inc esi                     ; loops: count
    test eax, eax               ; logic: done?
    jnz itoa_loop               ; loops: continue

    ; I/O: write number
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    mov edx, esi
    int 0x80

    ; I/O: write newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    pop esi                     ; memory: restore esi
    pop ebx                     ; memory: restore ebx
    ret