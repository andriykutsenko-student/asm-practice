; practice12.asm
; I/O: int 80h
; blocks: I/O, parse, math/logic, loops, memory

BITS 32
GLOBAL _start

SECTION .data
    newline      db 10
    str_first    db "first: "
    str_first_l  equ $-str_first
    str_count    db "count: "
    str_count_l  equ $-str_count
    str_minus1   db "-1", 10
    str_minus1_l equ $-str_minus1

SECTION .bss
    inbuf    resb 512           ; memory: full input buffer
    textbuf  resb 256           ; memory: text buffer
    patbuf   resb 64            ; memory: pattern buffer
    outbuf   resb 16            ; memory: itoa buffer
    text_len resd 1             ; memory: text length
    pat_len  resd 1             ; memory: pattern length
    max_i    resd 1             ; memory: max search index
    first_pos resd 1            ; memory: first occurrence
    cnt      resd 1             ; memory: count

SECTION .text
_start:
    ; I/O: read all input at once
    mov eax, 3
    mov ebx, 0
    mov ecx, inbuf
    mov edx, 511
    int 0x80

    ; parse: copy first line to textbuf
    mov esi, inbuf
    mov edi, textbuf
    xor ecx, ecx

copy_text:
    movzx eax, byte [esi]       ; memory: load char
    cmp al, 10                  ; logic: newline?
    je copy_text_done
    cmp al, 0
    je copy_text_done
    mov [edi], al               ; memory: store in textbuf
    inc esi
    inc edi
    inc ecx                     ; loops: count
    jmp copy_text

copy_text_done:
    mov byte [edi], 0           ; memory: null terminate
    mov [text_len], ecx         ; memory: save length
    inc esi                     ; loops: skip newline

    ; parse: copy second line to patbuf
    mov edi, patbuf
    xor ecx, ecx

copy_pat:
    movzx eax, byte [esi]       ; memory: load char
    cmp al, 10                  ; logic: newline?
    je copy_pat_done
    cmp al, 0
    je copy_pat_done
    mov [edi], al               ; memory: store in patbuf
    inc esi
    inc edi
    inc ecx                     ; loops: count
    jmp copy_pat

copy_pat_done:
    mov byte [edi], 0           ; memory: null terminate
    mov [pat_len], ecx          ; memory: save length

    ; logic: handle empty pattern
    cmp dword [pat_len], 0
    jne do_search
    mov eax, 4
    mov ebx, 1
    mov ecx, str_first
    mov edx, str_first_l
    int 0x80
    mov eax, 0
    call itoa_print
    mov eax, 4
    mov ebx, 1
    mov ecx, str_count
    mov edx, str_count_l
    int 0x80
    mov eax, 0
    call itoa_print
    jmp exit_prog

do_search:
    ; memory: init results
    mov dword [first_pos], 0xFFFFFFFF
    mov dword [cnt], 0

    ; math: max_i = text_len - pat_len
    mov eax, [text_len]
    sub eax, [pat_len]
    mov [max_i], eax

    ; loops: outer i = 0..max_i
    mov edi, 0

outer_loop:
    mov eax, [max_i]
    cmp edi, eax                ; logic: i <= max_i?
    jg outer_done

    ; loops: inner j = 0..pat_len-1
    xor esi, esi

inner_loop:
    cmp esi, [pat_len]          ; logic: j < pat_len?
    jge inner_match

    ; memory: compare textbuf[i+j] and patbuf[j]
    mov eax, edi
    add eax, esi
    movzx ecx, byte [textbuf + eax]
    movzx edx, byte [patbuf + esi]
    cmp cl, dl                  ; logic: match?
    jne inner_no_match
    inc esi                     ; loops: j++
    jmp inner_loop

inner_match:
    ; logic: found match at i
    cmp dword [first_pos], 0xFFFFFFFF
    jne not_first
    mov [first_pos], edi
not_first:
    inc dword [cnt]             ; math: count++
    add edi, [pat_len]          ; loops: skip match
    jmp outer_loop

inner_no_match:
    inc edi                     ; loops: i++
    jmp outer_loop

outer_done:
    ; I/O: print "first: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_first
    mov edx, str_first_l
    int 0x80

    cmp dword [first_pos], 0xFFFFFFFF
    jne print_first
    mov eax, 4
    mov ebx, 1
    mov ecx, str_minus1
    mov edx, str_minus1_l
    int 0x80
    jmp print_count

print_first:
    mov eax, [first_pos]
    call itoa_print

print_count:
    ; I/O: print "count: "
    mov eax, 4
    mov ebx, 1
    mov ecx, str_count
    mov edx, str_count_l
    int 0x80
    mov eax, [cnt]
    call itoa_print

exit_prog:
    ; I/O: exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

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