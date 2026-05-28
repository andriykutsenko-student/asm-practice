; practice7.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .data
    newline     db 10
    space       db " "
    str_min     db "min: "
    str_min_l   equ $-str_min
    str_idx     db " idx: "
    str_idx_l   equ $-str_idx
    str_max     db "max: "
    str_max_l   equ $-str_max

SECTION .bss
    buf    resb 32              ; memory: input buffer
    outbuf resb 16              ; memory: output buffer for itoa
    arr    resd 50              ; memory: array of 50 dwords

SECTION .text
_start:
    ; I/O: read n from stdin
    mov eax, 3
    mov ebx, 0
    mov ecx, buf
    mov edx, 31
    int 0x80

    ; parse: atoi buf -> eax = n
    mov esi, buf
    call atoi
    mov ebx, eax                ; memory: ebx = n

    ; loops: fill array with formula a[i] = (i*i + 3*i + 7) mod 100
    xor ecx, ecx                ; loops: i = 0

fill_loop:
    cmp ecx, ebx                ; logic: i < n?
    jge fill_done

    mov eax, ecx                ; math: eax = i
    imul eax, ecx               ; math: eax = i*i
    mov edx, ecx
    imul edx, edx, 3            ; math: edx = 3*i
    add eax, edx                ; math: eax = i*i + 3*i
    add eax, 7                  ; math: eax = i*i + 3*i + 7
    xor edx, edx
    mov edi, 100
    div edi                     ; math: mod 100
    ; memory: store arr[i] = edx
    mov [arr + ecx*4], edx

    inc ecx                     ; loops: i++
    jmp fill_loop

fill_done:
    ; loops: print array
    xor ecx, ecx                ; loops: i = 0

print_loop:
    cmp ecx, ebx                ; logic: i < n?
    jge print_done

    push ebx
    push ecx
    mov eax, [arr + ecx*4]      ; memory: load arr[i]
    call itoa_print_space
    pop ecx
    pop ebx

    inc ecx                     ; loops: i++
    jmp print_loop

print_done:
    ; I/O: newline after array
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; logic: find min and its index
    mov eax, [arr]              ; memory: min = arr[0]
    xor edi, edi                ; memory: min_idx = 0
    mov ecx, 1                  ; loops: i = 1
    mov ebx, [n_val]

find_min:
    cmp ecx, [n_val]            ; logic: i < n?
    jge min_done
    mov edx, [arr + ecx*4]      ; memory: load arr[i]
    cmp edx, eax                ; logic: arr[i] < min?
    jge not_min
    mov eax, edx                ; math: update min
    mov edi, ecx                ; memory: update min_idx

not_min:
    inc ecx                     ; loops: i++
    jmp find_min

min_done:
    ; I/O: print "min: "
    push eax
    push edi
    mov eax, 4
    mov ebx, 1
    mov ecx, str_min
    mov edx, str_min_l
    int 0x80
    pop edi
    pop eax
    call itoa_print_inline

    ; I/O: print " idx: "
    push edi
    mov eax, 4
    mov ebx, 1
    mov ecx, str_idx
    mov edx, str_idx_l
    int 0x80
    pop edi
    mov eax, edi
    call itoa_print

    ; logic: find max and its index
    mov eax, [arr]              ; memory: max = arr[0]
    xor edi, edi                ; memory: max_idx = 0
    mov ecx, 1                  ; loops: i = 1

find_max:
    cmp ecx, [n_val]            ; logic: i < n?
    jge max_done
    mov edx, [arr + ecx*4]      ; memory: load arr[i]
    cmp edx, eax                ; logic: arr[i] > max?
    jle not_max
    mov eax, edx                ; math: update max
    mov edi, ecx                ; memory: update max_idx

not_max:
    inc ecx                     ; loops: i++
    jmp find_max

max_done:
    ; I/O: print "max: "
    push eax
    push edi
    mov eax, 4
    mov ebx, 1
    mov ecx, str_max
    mov edx, str_max_l
    int 0x80
    pop edi
    pop eax
    call itoa_print_inline

    ; I/O: print " idx: "
    push edi
    mov eax, 4
    mov ebx, 1
    mov ecx, str_idx
    mov edx, str_idx_l
    int 0x80
    pop edi
    mov eax, edi
    call itoa_print

    ; I/O: exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; parse: atoi - convert string at esi to integer in eax
atoi:
    xor eax, eax
    xor ecx, ecx

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
    ; memory: save n
    mov [n_val], eax
    ret

; parse: itoa and print with space after
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

; parse: itoa inline (no newline)
itoa_print_inline:
    push ebx
    push esi
    mov ecx, outbuf
    add ecx, 15
    xor esi, esi

iti_loop:
    xor edx, edx
    mov ebx, 10
    div ebx                     ; math: eax/10
    add dl, '0'                 ; parse: digit to ASCII
    dec ecx
    mov [ecx], dl               ; memory: store
    inc esi
    test eax, eax
    jnz iti_loop

    mov eax, 4
    mov ebx, 1
    mov edx, esi
    int 0x80

    pop esi
    pop ebx
    ret

; parse: itoa and print with newline
itoa_print:
    push ebx
    push esi
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

    mov eax, 4
    mov ebx, 1
    mov edx, esi
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    pop esi
    pop ebx
    ret

SECTION .bss
    n_val resd 1                ; memory: store n