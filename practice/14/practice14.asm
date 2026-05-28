; practice14.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .data
    newline      db 10
    space        db " "
    str_before   db "before: "
    str_before_l equ $-str_before
    str_after    db "after: "
    str_after_l  equ $-str_after
    str_median   db "median: "
    str_median_l equ $-str_median

SECTION .bss
    inbuf   resb 2048           ; memory: input buffer
    arr     resd 100            ; memory: array
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

    ; parse: read n
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
    ; I/O: print "before: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_before
    mov edx, str_before_l
    int 0x80

    ; loops: print original array
    xor ecx, ecx
print_before:
    cmp ecx, [n_val]            ; logic: i < n?
    jge print_before_done
    push ecx
    mov eax, [arr + ecx*4]      ; memory: load arr[i]
    call itoa_space
    pop ecx
    inc ecx
    jmp print_before
print_before_done:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; loops: selection sort
    xor edi, edi                ; loops: i = 0

sort_outer:
    mov eax, [n_val]
    dec eax
    cmp edi, eax                ; logic: i < n-1?
    jge sort_done

    ; logic: find min index in arr[i..n-1]
    mov ebx, edi                ; memory: min_idx = i
    mov ecx, edi
    inc ecx                     ; loops: j = i+1

sort_inner:
    cmp ecx, [n_val]            ; logic: j < n?
    jge sort_inner_done
    mov eax, [arr + ecx*4]      ; memory: arr[j]
    mov edx, [arr + ebx*4]      ; memory: arr[min_idx]
    cmp eax, edx                ; logic: arr[j] < arr[min_idx]?
    jge not_new_min
    mov ebx, ecx                ; memory: min_idx = j
not_new_min:
    inc ecx                     ; loops: j++
    jmp sort_inner

sort_inner_done:
    ; math: swap arr[i] and arr[min_idx]
    cmp ebx, edi                ; logic: min_idx != i?
    je no_swap
    mov eax, [arr + edi*4]      ; memory: tmp = arr[i]
    mov ecx, [arr + ebx*4]      ; memory: arr[min_idx]
    mov [arr + edi*4], ecx      ; memory: arr[i] = arr[min_idx]
    mov [arr + ebx*4], eax      ; memory: arr[min_idx] = tmp
no_swap:
    inc edi                     ; loops: i++
    jmp sort_outer

sort_done:
    ; I/O: print "after: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_after
    mov edx, str_after_l
    int 0x80

    ; loops: print sorted array
    xor ecx, ecx
print_after:
    cmp ecx, [n_val]            ; logic: i < n?
    jge print_after_done
    push ecx
    mov eax, [arr + ecx*4]      ; memory: load arr[i]
    call itoa_space
    pop ecx
    inc ecx
    jmp print_after
print_after_done:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; math: median = arr[n/2] (lower middle for even n)
    mov eax, [n_val]
    shr eax, 1                  ; math: n/2
    mov eax, [arr + eax*4]      ; memory: load median

    ; I/O: print "median: "
    push eax
    mov eax, 4
    mov ebx, 1
    mov ecx, str_median
    mov edx, str_median_l
    int 0x80
    pop eax
    call itoa_print

    ; I/O: exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; parse: skip current token
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
    movzx eax, byte [esi]
    cmp al, ' '
    je do_skip_s
    cmp al, 10
    je do_skip_s
    cmp al, 13
    je do_skip_s
    ret
do_skip_s:
    inc esi
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
    cmp dl, ' '
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