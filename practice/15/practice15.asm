; practice15.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .data
    newline      db 10
    str_fact     db "fact: "
    str_fact_l   equ $-str_fact
    str_calls    db "calls: "
    str_calls_l  equ $-str_calls

SECTION .bss
    buf    resb 32              ; memory: input buffer
    outbuf resb 16              ; memory: itoa buffer
    calls  resd 1               ; memory: global call counter

SECTION .text
_start:
    ; I/O: read n from stdin
    mov eax, 3
    mov ebx, 0
    mov ecx, buf
    mov edx, 31
    int 0x80

    ; parse: atoi -> n in eax
    mov esi, buf
    call atoi

    ; memory: init call counter
    mov dword [calls], 0

    ; logic: call recursive factorial
    call fact                   ; math: result in eax

    ; I/O: print "fact: "
    push eax
    mov eax, 4
    mov ebx, 1
    mov ecx, str_fact
    mov edx, str_fact_l
    int 0x80
    pop eax
    call itoa_print

    ; I/O: print "calls: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_calls
    mov edx, str_calls_l
    int 0x80
    mov eax, [calls]            ; memory: load call count
    call itoa_print

    ; I/O: exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; math: recursive factorial
; input: eax = n
; output: eax = n!
; side effect: increments [calls]
fact:
    ; memory: prologue - save registers
    push ebp
    mov ebp, esp
    push ebx

    ; memory: increment call counter
    inc dword [calls]

    ; logic: base case n <= 1 -> return 1
    cmp eax, 1
    jle fact_base

    ; math: recursive case: fact(n-1) * n
    mov ebx, eax                ; memory: save n in ebx
    dec eax                     ; math: n-1
    call fact                   ; loops: recursive call
    imul eax, ebx               ; math: result * n
    jmp fact_ret

fact_base:
    mov eax, 1                  ; math: fact(0) = fact(1) = 1

fact_ret:
    ; memory: epilogue - restore registers
    pop ebx
    pop ebp
    ret

; parse: atoi - convert string at esi to int in eax
atoi:
    xor eax, eax
atoi_loop:
    movzx edx, byte [esi]       ; memory: load char
    cmp dl, 10                  ; logic: newline?
    je atoi_done
    cmp dl, 13
    je atoi_done
    cmp dl, 0
    je atoi_done
    sub dl, '0'                 ; parse: ASCII to digit
    imul eax, eax, 10           ; math: shift
    add eax, edx                ; math: add digit
    inc esi                     ; loops: advance
    jmp atoi_loop
atoi_done:
    ret

; parse: itoa and print with newline
itoa_print:
    push ebx
    push esi
    push edi
    xor edi, edi
    test eax, eax
    jns itp_pos
    neg eax
    mov edi, 1
itp_pos:
    mov ecx, outbuf
    add ecx, 15
    xor esi, esi
itp_loop:
    xor edx, edx
    mov ebx, 10
    div ebx                     ; math: eax/10
    add dl, '0'                 ; parse: digit to ASCII
    dec ecx
    mov [ecx], dl               ; memory: store digit
    inc esi
    test eax, eax
    jnz itp_loop
    test edi, edi
    jz itp_write
    dec ecx
    mov byte [ecx], '-'
    inc esi
itp_write:
    mov eax, 4
    mov ebx, 1
    mov edx, esi
    int 0x80
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    pop edi
    pop esi
    pop ebx
    ret