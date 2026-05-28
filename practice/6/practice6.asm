; practice6.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .data
    newline        db 10
    str_signed     db "SIGNED: "
    str_signed_l   equ $-str_signed
    str_unsigned   db "UNSIGNED: "
    str_unsigned_l equ $-str_unsigned
    str_lt         db "a < b", 10
    str_lt_l       equ $-str_lt
    str_eq         db "a = b", 10
    str_eq_l       equ $-str_eq
    str_gt         db "a > b", 10
    str_gt_l       equ $-str_gt
    str_max_s      db "max_signed: "
    str_max_s_l    equ $-str_max_s
    str_max_u      db "max_unsigned: "
    str_max_u_l    equ $-str_max_u

SECTION .bss
    buf    resb 64              ; memory: input buffer for both numbers
    outbuf resb 32              ; memory: output buffer for itoa
    val_a  resd 1               ; memory: store value a
    val_b  resd 1               ; memory: store value b

SECTION .text
_start:
    ; I/O: read both numbers at once
    mov eax, 3
    mov ebx, 0
    mov ecx, buf
    mov edx, 63
    int 0x80

    ; parse: atoi first number from buf -> val_a
    mov esi, buf
    call atoi
    mov [val_a], eax

    ; parse: skip to next line
skip_line:
    movzx edx, byte [esi]       ; memory: load char
    cmp dl, 10                  ; logic: newline?
    je skip_done
    cmp dl, 0                   ; logic: null?
    je skip_done
    inc esi                     ; loops: advance
    jmp skip_line

skip_done:
    inc esi                     ; loops: skip newline itself

    ; parse: atoi second number -> val_b
    call atoi
    mov [val_b], eax

    ; I/O: print "SIGNED: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_signed
    mov edx, str_signed_l
    int 0x80

    ; logic: signed comparison
    mov eax, [val_a]
    mov ebx, [val_b]
    cmp eax, ebx
    jl  signed_lt
    je  signed_eq
    jmp signed_gt

signed_lt:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_lt
    mov edx, str_lt_l
    int 0x80
    jmp do_unsigned

signed_eq:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_eq
    mov edx, str_eq_l
    int 0x80
    jmp do_unsigned

signed_gt:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_gt
    mov edx, str_gt_l
    int 0x80

do_unsigned:
    ; I/O: print "UNSIGNED: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_unsigned
    mov edx, str_unsigned_l
    int 0x80

    ; logic: unsigned comparison
    mov eax, [val_a]
    mov ebx, [val_b]
    cmp eax, ebx
    jb  unsigned_lt
    je  unsigned_eq
    jmp unsigned_gt

unsigned_lt:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_lt
    mov edx, str_lt_l
    int 0x80
    jmp do_max_signed

unsigned_eq:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_eq
    mov edx, str_eq_l
    int 0x80
    jmp do_max_signed

unsigned_gt:
    mov eax, 4
    mov ebx, 1
    mov ecx, str_gt
    mov edx, str_gt_l
    int 0x80

do_max_signed:
    ; I/O: print "max_signed: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_max_s
    mov edx, str_max_s_l
    int 0x80

    ; math: max_signed(a,b)
    mov eax, [val_a]
    mov ebx, [val_b]
    cmp eax, ebx                ; logic: signed compare
    jge print_a_signed
    mov eax, ebx

print_a_signed:
    call itoa_print

    ; I/O: print "max_unsigned: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_max_u
    mov edx, str_max_u_l
    int 0x80

    ; math: max_unsigned(a,b)
    mov eax, [val_a]
    mov ebx, [val_b]
    cmp eax, ebx                ; logic: unsigned compare
    jae print_a_unsigned
    mov eax, ebx

print_a_unsigned:
    call itoa_print

    ; I/O: exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; parse: convert signed string at esi to integer in eax
atoi:
    xor eax, eax
    xor ecx, ecx
    movzx edx, byte [esi]
    cmp dl, '-'                 ; logic: check minus sign
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
    imul eax, eax, 10           ; math: shift accumulator
    add eax, edx                ; math: add digit
    inc esi                     ; loops: advance pointer
    jmp atoi_loop

atoi_done:
    test ecx, ecx               ; logic: was negative?
    jz atoi_ret
    neg eax                     ; math: negate

atoi_ret:
    ret

; parse: convert eax to string and print (signed)
itoa_print:
    push ebx
    push esi
    push edi
    xor edi, edi
    test eax, eax               ; logic: check sign
    jns itoa_pos
    neg eax                     ; math: make positive
    mov edi, 1

itoa_pos:
    mov ecx, outbuf
    add ecx, 31
    xor esi, esi

itoa_loop:
    xor edx, edx                ; math: clear edx
    mov ebx, 10
    div ebx                     ; math: eax/10
    add dl, '0'                 ; parse: digit to ASCII
    dec ecx
    mov [ecx], dl               ; memory: store digit
    inc esi
    test eax, eax               ; logic: done?
    jnz itoa_loop

    test edi, edi               ; logic: negative?
    jz itoa_write
    dec ecx
    mov byte [ecx], '-'         ; parse: add minus sign
    inc esi

itoa_write:
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