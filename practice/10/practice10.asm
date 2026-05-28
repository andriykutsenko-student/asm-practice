; practice10.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .data
    newline        db 10
    space          db " "
    str_bin        db "binary: "
    str_bin_l      equ $-str_bin
    str_pop        db "popcount: "
    str_pop_l      equ $-str_pop
    str_modified   db "modified: "
    str_modified_l equ $-str_modified

SECTION .bss
    buf    resb 32              ; memory: input buffer
    outbuf resb 16              ; memory: itoa buffer
    x_val  resd 1               ; memory: input value x

SECTION .text
_start:
    ; I/O: read x from stdin
    mov eax, 3
    mov ebx, 0
    mov ecx, buf
    mov edx, 31
    int 0x80

    ; parse: atoi -> x
    mov esi, buf
    call atoi
    mov [x_val], eax

    ; I/O: print "binary: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_bin
    mov edx, str_bin_l
    int 0x80

    ; loops: print 32 bits from MSB to LSB grouped by 4
    mov edi, [x_val]            ; memory: load x
    mov ecx, 31                 ; loops: start from bit 31

print_bin_loop:
    ; math: isolate bit at position ecx
    mov eax, edi
    mov cl, cl                  ; loops: cl = bit position
    shr eax, cl                 ; math: shift right by cl
    and eax, 1                  ; math: isolate LSB
    add eax, '0'                ; parse: to ASCII

    ; I/O: print bit
    push ecx
    push edi
    mov [outbuf], al
    mov eax, 4
    mov ebx, 1
    mov ecx, outbuf
    mov edx, 1
    int 0x80
    pop edi
    pop ecx

    ; logic: print space after every 4 bits (at positions 28,24,20,16,12,8,4)
    mov eax, ecx
    and eax, 3                  ; math: ecx mod 4
    cmp eax, 0
    jne no_space
    cmp ecx, 0                  ; logic: no space after last bit
    je no_space
    push ecx
    push edi
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80
    pop edi
    pop ecx

no_space:
    dec ecx                     ; loops: next bit
    cmp ecx, 0
    jge print_bin_loop
    ; print last bit (bit 0) already done when ecx=0 in loop

    ; I/O: newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; math: popcount - count set bits using shr + and 1
    mov edi, [x_val]            ; memory: load x
    xor ebx, ebx                ; math: count = 0
    mov ecx, 32                 ; loops: 32 bits

popcount_loop:
    mov eax, edi
    and eax, 1                  ; math: isolate LSB
    add ebx, eax                ; math: count += bit
    shr edi, 1                  ; math: shift right
    dec ecx                     ; loops: decrement
    jnz popcount_loop

    ; I/O: print "popcount: "
    push ebx
    mov eax, 4
    mov ebx, 1
    mov ecx, str_pop
    mov edx, str_pop_l
    int 0x80
    pop ebx
    mov eax, ebx
    call itoa_print

    ; math: set bits 3 and 7, clear bit 1
    mov eax, [x_val]            ; memory: load x
    or eax, (1 << 3)            ; math: set bit 3
    or eax, (1 << 7)            ; math: set bit 7
    and eax, ~(1 << 1)          ; math: clear bit 1

    ; I/O: print "modified: "
    push eax
    mov eax, 4
    mov ebx, 1
    mov ecx, str_modified
    mov edx, str_modified_l
    int 0x80
    pop eax
    call itoa_print

    ; I/O: exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; parse: atoi - convert string at esi to integer in eax
atoi:
    xor eax, eax
    xor ecx, ecx
    movzx edx, byte [esi]
    cmp dl, '-'                 ; logic: minus?
    jne atoi_loop
    mov ecx, 1
    inc esi
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
    test ecx, ecx               ; logic: negative?
    jz atoi_ret
    neg eax                     ; math: negate
atoi_ret:
    ret

; parse: itoa and print with newline
itoa_print:
    push ebx
    push esi
    push edi
    xor edi, edi
    test eax, eax               ; logic: negative?
    jns itp_pos
    neg eax                     ; math: make positive
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
    mov [ecx], dl               ; memory: store
    inc esi
    test eax, eax
    jnz itp_loop
    test edi, edi               ; logic: add minus?
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