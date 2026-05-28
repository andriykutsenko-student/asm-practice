; practice13.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .data
    newline      db 10
    space        db " "
    str_orig     db "original: "
    str_orig_l   equ $-str_orig
    str_rev      db "reversed: "
    str_rev_l    equ $-str_rev
    str_pal_yes  db "PALINDROME: YES", 10
    str_pal_yes_l equ $-str_pal_yes
    str_pal_no   db "PALINDROME: NO", 10
    str_pal_no_l equ $-str_pal_no

SECTION .bss
    inbuf   resb 2048           ; memory: input buffer
    arr     resd 200            ; memory: original array
    revarr  resd 200            ; memory: reversed array
    outbuf  resb 16             ; memory: itoa buffer
    n_val   resd 1              ; memory: n

SECTION .text
_start:
    ; I/O: read all input
    mov eax, 3
    mov ebx, 0
    mov ecx, inbuf
    mov edx, 2047
    int 0x80

    ; parse: read n from input
    mov esi, inbuf
    call atoi
    mov [n_val], eax
    call skip_token
    call skip_spaces

    ; loops: read n numbers into arr
    xor ecx, ecx

read_loop:
    cmp ecx, [n_val]            ; logic: i < n?
    jge read_done
    push ecx
    call atoi
    pop ecx
    mov [arr + ecx*4], eax      ; memory: store arr[i]
    call skip_token
    call skip_spaces
    inc ecx                     ; loops: i++
    jmp read_loop

read_done:
    ; memory: copy arr to revarr reversed using rep movsd
    ; loops: build reversed array
    mov ecx, 0                  ; loops: i = 0
    mov ebx, [n_val]

reverse_loop:
    cmp ecx, ebx                ; logic: i < n?
    jge reverse_done
    ; math: revarr[i] = arr[n-1-i]
    mov eax, ebx
    dec eax
    sub eax, ecx                ; math: n-1-i
    mov edx, [arr + eax*4]      ; memory: load arr[n-1-i]
    mov [revarr + ecx*4], edx   ; memory: store revarr[i]
    inc ecx                     ; loops: i++
    jmp reverse_loop

reverse_done:
    ; I/O: print "original: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_orig
    mov edx, str_orig_l
    int 0x80

    ; loops: print original array
    xor ecx, ecx
print_orig:
    cmp ecx, [n_val]            ; logic: i < n?
    jge print_orig_done
    push ecx
    mov eax, [arr + ecx*4]      ; memory: load arr[i]
    call itoa_space
    pop ecx
    inc ecx                     ; loops: i++
    jmp print_orig

print_orig_done:
    ; I/O: newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; I/O: print "reversed: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_rev
    mov edx, str_rev_l
    int 0x80

    ; loops: print reversed array
    xor ecx, ecx
print_rev:
    cmp ecx, [n_val]            ; logic: i < n?
    jge print_rev_done
    push ecx
    mov eax, [revarr + ecx*4]   ; memory: load revarr[i]
    call itoa_space
    pop ecx
    inc ecx                     ; loops: i++
    jmp print_rev

print_rev_done:
    ; I/O: newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; logic: check palindrome - compare arr[i] with arr[n-1-i]
    xor ecx, ecx
    mov ebx, [n_val]

pal_loop:
    ; math: only need to check first half
    mov eax, ebx
    shr eax, 1                  ; math: n/2
    cmp ecx, eax                ; logic: i < n/2?
    jge pal_yes

    ; memory: compare arr[i] and arr[n-1-i]
    mov eax, ebx
    dec eax
    sub eax, ecx                ; math: n-1-i
    mov edx, [arr + eax*4]      ; memory: arr[n-1-i]
    mov edi, [arr + ecx*4]      ; memory: arr[i]
    cmp edx, edi                ; logic: equal?
    jne pal_no
    inc ecx                     ; loops: i++
    jmp pal_loop

pal_yes:
    ; I/O: print PALINDROME: YES
    mov eax, 4
    mov ebx, 1
    mov ecx, str_pal_yes
    mov edx, str_pal_yes_l
    int 0x80
    jmp exit_prog

pal_no:
    ; I/O: print PALINDROME: NO
    mov eax, 4
    mov ebx, 1
    mov ecx, str_pal_no
    mov edx, str_pal_no_l
    int 0x80

exit_prog:
    ; I/O: exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; parse: skip current token (digits)
skip_token:
    movzx eax, byte [esi]
    cmp al, '-'
    jne skip_digits
    inc esi
skip_digits:
    movzx eax, byte [esi]
    cmp al, '0'
    jl skip_tok_done
    cmp al, '9'
    jg skip_tok_done
    inc esi
    jmp skip_digits
skip_tok_done:
    ret

; parse: skip spaces and newlines
skip_spaces:
    movzx eax, byte [esi]       ; memory: load char
    cmp al, ' '                 ; logic: space?
    je do_skip
    cmp al, 10                  ; logic: newline?
    je do_skip
    cmp al, 13
    je do_skip
    ret
do_skip:
    inc esi                     ; loops: advance
    jmp skip_spaces

; parse: atoi - convert string at esi to int in eax
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
    cmp dl, ' '                 ; logic: space?
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

; parse: itoa and print with space
itoa_space:
    push ebx
    push esi
    mov ecx, outbuf
    add ecx, 15
    xor esi, esi
its_loop:
    xor edx, edx
    mov ebx, 10
    div ebx                     ; math: eax/10
    add dl, '0'                 ; parse: digit to ASCII
    dec ecx
    mov [ecx], dl               ; memory: store
    inc esi
    test eax, eax
    jnz its_loop
    mov eax, 4
    mov ebx, 1
    mov edx, esi
    int 0x80
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80
    pop esi
    pop ebx
    ret