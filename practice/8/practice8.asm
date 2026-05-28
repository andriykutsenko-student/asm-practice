; practice8.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .data
    newline      db 10
    space        db " "
    str_first    db "first: "
    str_first_l  equ $-str_first
    str_count    db "count: "
    str_count_l  equ $-str_count
    str_indices  db "indices: "
    str_indices_l equ $-str_indices
    str_none     db "", 10
    str_none_l   equ $-str_none
    str_minus1   db "-1", 10
    str_minus1_l equ $-str_minus1

SECTION .bss
    inbuf   resb 1024           ; memory: large input buffer
    outbuf  resb 16             ; memory: itoa output buffer
    arr     resd 100            ; memory: array of 100 dwords
    n_val   resd 1              ; memory: n
    target  resd 1              ; memory: target value

SECTION .text
_start:
    ; I/O: read all input at once
    mov eax, 3
    mov ebx, 0
    mov ecx, inbuf
    mov edx, 1023
    int 0x80

    ; parse: read n
    mov esi, inbuf
    call atoi
    mov [n_val], eax

    ; parse: skip to next token
    call skip_token
    call skip_spaces

    ; loops: read n numbers into array
    xor ecx, ecx                ; loops: i = 0

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
    ; parse: read target
    call atoi
    mov [target], eax

    ; logic: linear search - find first index
    xor ecx, ecx                ; loops: i = 0
    mov edi, -1                 ; memory: first_idx = -1
    xor ebx, ebx                ; memory: count = 0

search_loop:
    cmp ecx, [n_val]            ; logic: i < n?
    jge search_done
    mov eax, [arr + ecx*4]      ; memory: load arr[i]
    cmp eax, [target]           ; logic: arr[i] == target?
    jne search_next
    cmp edi, -1                 ; logic: first found?
    jne search_count
    mov edi, ecx                ; memory: save first index

search_count:
    inc ebx                     ; math: count++

search_next:
    inc ecx                     ; loops: i++
    jmp search_loop

search_done:
    ; I/O: print "first: "
    push edi
    push ebx
    mov eax, 4
    mov ebx, 1
    mov ecx, str_first
    mov edx, str_first_l
    int 0x80
    pop ebx
    pop edi

    ; logic: print first index or -1
    cmp edi, -1
    jne print_first
    mov eax, 4
    mov ebx, 1
    mov ecx, str_minus1
    mov edx, str_minus1_l
    int 0x80
    jmp print_count

print_first:
    push ebx
    mov eax, edi
    call itoa_print
    pop ebx

print_count:
    ; I/O: print "count: "
    push ebx
    mov eax, 4
    mov ebx, 1
    mov ecx, str_count
    mov edx, str_count_l
    int 0x80
    pop ebx
    mov eax, ebx
    call itoa_print

    ; I/O: print "indices: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_indices
    mov edx, str_indices_l
    int 0x80

    ; loops: print all indices
    xor ecx, ecx

indices_loop:
    cmp ecx, [n_val]            ; logic: i < n?
    jge indices_done
    mov eax, [arr + ecx*4]      ; memory: load arr[i]
    cmp eax, [target]           ; logic: match?
    jne indices_next
    push ecx
    mov eax, ecx
    call itoa_print_space
    pop ecx

indices_next:
    inc ecx                     ; loops: i++
    jmp indices_loop

indices_done:
    ; I/O: newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; I/O: exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; parse: skip digits/minus of current token
skip_token:
    movzx eax, byte [esi]
    cmp al, '-'
    je .skip_minus
    jmp .skip_digits
.skip_minus:
    inc esi
.skip_digits:
    movzx eax, byte [esi]
    cmp al, '0'
    jl .skip_done
    cmp al, '9'
    jg .skip_done
    inc esi
    jmp .skip_digits
.skip_done:
    ret

; parse: skip spaces and newlines
skip_spaces:
    movzx eax, byte [esi]       ; memory: load char
    cmp al, ' '                 ; logic: space?
    je .do_skip
    cmp al, 10                  ; logic: newline?
    je .do_skip
    cmp al, 13
    je .do_skip
    ret
.do_skip:
    inc esi                     ; loops: advance
    jmp skip_spaces

; parse: atoi - convert string at esi to integer in eax
atoi:
    xor eax, eax
    xor ecx, ecx
    movzx edx, byte [esi]
    cmp dl, '-'                 ; logic: minus sign?
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
    mov [ecx], dl               ; memory: store
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

; parse: itoa and print with space
itoa_print_space:
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