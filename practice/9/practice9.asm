; practice9.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .data
    newline     db 10
    colon_sp    db ": "
    colon_sp_l  equ $-colon_sp
    hash        db "#"
    sp_open     db " ("
    sp_open_l   equ $-sp_open
    sp_close    db ")", 10
    sp_close_l  equ $-sp_close

SECTION .bss
    buf     resb 32             ; memory: input buffer
    outbuf  resb 16             ; memory: itoa buffer
    freq    resd 10             ; memory: frequency array [0..9]
    lcg_x   resd 1              ; memory: LCG state
    n_val   resd 1              ; memory: n

SECTION .text
_start:
    ; I/O: read n
    mov eax, 3
    mov ebx, 0
    mov ecx, buf
    mov edx, 31
    int 0x80

    ; parse: atoi -> n
    mov esi, buf
    call atoi
    mov [n_val], eax

    ; math: init LCG seed
    mov dword [lcg_x], 42       ; math: initial seed

    ; loops: init freq array to 0
    xor ecx, ecx
init_freq:
    cmp ecx, 10                 ; logic: i < 10?
    jge init_done
    mov dword [freq + ecx*4], 0 ; memory: freq[i] = 0
    inc ecx
    jmp init_freq
init_done:

    ; loops: generate n random numbers and count frequencies
    xor ecx, ecx                ; loops: i = 0
gen_loop:
    cmp ecx, [n_val]            ; logic: i < n?
    jge gen_done

    ; math: LCG x = (1103515245*x + 12345) mod 2^31
    mov eax, [lcg_x]
    mov edx, 1103515245
    imul edx                    ; math: edx:eax = x * 1103515245
    add eax, 12345              ; math: + 12345
    and eax, 0x7FFFFFFF         ; math: mod 2^31
    mov [lcg_x], eax            ; memory: save new x

    ; math: digit = x mod 10
    xor edx, edx
    mov ebx, 10
    div ebx                     ; math: eax/10, edx = x mod 10

    ; memory: freq[digit]++
    inc dword [freq + edx*4]

    inc ecx                     ; loops: i++
    jmp gen_loop

gen_done:
    ; loops: print histogram
    xor ecx, ecx                ; loops: i = 0

print_loop:
    cmp ecx, 10                 ; logic: i < 10?
    jge print_done

    ; I/O: print digit i
    push ecx
    mov eax, ecx
    call itoa_inline

    ; I/O: print ": "
    mov eax, 4
    mov ebx, 1
    mov ecx, colon_sp
    mov edx, colon_sp_l
    int 0x80
    pop ecx
    push ecx

    ; loops: print # chars
    mov edi, [freq + ecx*4]     ; memory: load freq[i]
    push edi
    xor ecx, ecx

hash_loop:
    cmp ecx, edi                ; logic: j < freq[i]?
    jge hash_done
    push ecx
    mov eax, 4
    mov ebx, 1
    mov ecx, hash
    mov edx, 1
    int 0x80
    pop ecx
    inc ecx                     ; loops: j++
    jmp hash_loop

hash_done:
    ; I/O: print " (count)"
    mov eax, 4
    mov ebx, 1
    mov ecx, sp_open
    mov edx, sp_open_l
    int 0x80

    pop edi
    mov eax, edi
    call itoa_inline

    mov eax, 4
    mov ebx, 1
    mov ecx, sp_close
    mov edx, sp_close_l
    int 0x80

    pop ecx
    inc ecx                     ; loops: i++
    jmp print_loop

print_done:
    ; I/O: exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; parse: atoi - convert string at esi to integer in eax
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

; parse: itoa inline (no newline)
itoa_inline:
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