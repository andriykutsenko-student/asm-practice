; practice11.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .bss
    inbuf  resb 32              ; memory: input buffer
    linebuf resb 64             ; memory: line buffer for one row

SECTION .text
_start:
    ; I/O: read h from stdin
    mov eax, 3
    mov ebx, 0
    mov ecx, inbuf
    mov edx, 31
    int 0x80

    ; parse: atoi -> h in ebx
    mov esi, inbuf
    call atoi
    mov ebx, eax                ; memory: ebx = h

    ; loops: for row = 1..h
    mov ecx, 1                  ; loops: row = 1

row_loop:
    cmp ecx, ebx                ; logic: row <= h?
    jg row_done

    push ecx
    push ebx

    ; math: spaces = h - row
    mov eax, ebx
    sub eax, ecx                ; math: spaces = h - row
    mov edi, eax                ; memory: edi = spaces count

    ; math: stars = 2*row - 1
    mov esi, ecx
    imul esi, esi, 2
    dec esi                     ; math: stars = 2*row - 1

    ; memory: fill linebuf with spaces then stars then newline
    mov edx, linebuf            ; memory: pointer to linebuf
    xor ecx, ecx                ; loops: i = 0

    ; loops: write spaces
spaces_loop:
    cmp ecx, edi                ; logic: i < spaces?
    jge spaces_done
    mov byte [edx], ' '         ; memory: store space
    inc edx                     ; memory: advance pointer
    inc ecx                     ; loops: i++
    jmp spaces_loop
spaces_done:

    ; loops: write stars
    xor ecx, ecx                ; loops: j = 0
stars_loop:
    cmp ecx, esi                ; logic: j < stars?
    jge stars_done
    mov byte [edx], '*'         ; memory: store star
    inc edx                     ; memory: advance pointer
    inc ecx                     ; loops: j++
    jmp stars_loop
stars_done:

    ; memory: append newline
    mov byte [edx], 10
    inc edx

    ; math: line length = spaces + stars + 1
    mov eax, edi
    add eax, esi
    inc eax                     ; math: +1 for newline

    ; I/O: print_line(linebuf, len)
    push eax
    mov eax, 4
    mov ebx, 1
    mov ecx, linebuf
    pop edx
    int 0x80

    pop ebx
    pop ecx
    inc ecx                     ; loops: row++
    jmp row_loop

row_done:
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