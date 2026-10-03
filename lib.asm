section .text

global exit
global string_length
global print_string
global print_char
global print_newline
global print_uint
global print_int
global string_equals
global read_char
global read_word
global parse_uint
global parse_int
global string_copy

; Terminate the current process with the status code in rdi.
exit:
    mov rax, 60
    syscall

; Return the length of the zero-terminated string in rdi.
string_length:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

; Write the zero-terminated string in rdi to stdout.
print_string:
    push rdi
    call string_length
    pop rsi
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    ret

; Write the low byte of rdi to stdout.
print_char:
    sub rsp, 8
    mov [rsp], dil
    mov rax, 1
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    syscall
    add rsp, 8
    ret

; Write a newline to stdout.
print_newline:
    mov rdi, 10
    jmp print_char

; Write the unsigned integer in rdi in decimal notation.
print_uint:
    sub rsp, 40
    lea rsi, [rsp + 32]
    mov byte [rsi], 0
    mov rax, rdi
    mov r8, 10
    xor rcx, rcx
    test rax, rax
    jnz .divide
    dec rsi
    mov byte [rsi], '0'
    mov rdx, 1
    jmp .write
.divide:
    xor rdx, rdx
    div r8
    add dl, '0'
    dec rsi
    mov [rsi], dl
    inc rcx
    test rax, rax
    jnz .divide
    mov rdx, rcx
.write:
    mov rdi, rsi
    call print_string
    add rsp, 40
    ret

; Write the signed integer in rdi in decimal notation.
print_int:
    test rdi, rdi
    jns .unsigned
    sub rsp, 24
    mov [rsp], rdi
    mov rdi, '-'
    call print_char
    mov rdi, [rsp]
    neg rdi
    call print_uint
    add rsp, 24
    ret
.unsigned:
    sub rsp, 8
    call print_uint
    add rsp, 8
    ret

; Return 1 if the zero-terminated strings in rdi and rsi are equal, else 0.
string_equals:
    xor rax, rax
.loop:
    mov dl, [rdi]
    cmp dl, [rsi]
    jne .done
    test dl, dl
    je .equal
    inc rdi
    inc rsi
    jmp .loop
.equal:
    mov rax, 1
.done:
    ret

; Read one byte from stdin, or return zero on EOF/error.
read_char:
    sub rsp, 8
    xor rax, rax
    xor rdi, rdi
    mov rsi, rsp
    mov rdx, 1
    syscall
    cmp rax, 1
    jne .eof
    movzx rax, byte [rsp]
    jmp .done
.eof:
    xor rax, rax
.done:
    add rsp, 8
    ret

; Read one whitespace-delimited word into rdi (a buffer of rsi bytes).
; Return its address and length in rax/rdx, or zero in rax if it does not fit.
read_word:
    sub rsp, 40
    mov [rsp], rdi
    mov [rsp + 8], rsi
    xor rax, rax
    mov [rsp + 16], rax
    test rsi, rsi
    jz .fail
    mov byte [rdi], 0
.skip_whitespace:
    call read_char
    test rax, rax
    jz .success
    cmp al, ' '
    je .skip_whitespace
    cmp al, 9
    je .skip_whitespace
    cmp al, 10
    je .skip_whitespace
.read_word:
    mov rcx, [rsp + 16]
    mov r8, [rsp + 8]
    lea r9, [rcx + 1]
    cmp r9, r8
    jae .fail
    mov r8, [rsp]
    mov [r8 + rcx], al
    inc rcx
    mov [rsp + 16], rcx
    call read_char
    test rax, rax
    jz .success
    cmp al, ' '
    je .success
    cmp al, 9
    je .success
    cmp al, 10
    jne .read_word
.success:
    mov rdx, [rsp + 16]
    mov rax, [rsp]
    mov byte [rax + rdx], 0
    add rsp, 40
    ret
.fail:
    xor rax, rax
    xor rdx, rdx
    add rsp, 40
    ret

; Parse an unsigned decimal integer at rdi.  Return value in rax and digit count in rdx.
parse_uint:
    xor rax, rax
    xor rdx, rdx
.loop:
    movzx rcx, byte [rdi + rdx]
    cmp rcx, '0'
    jb .done
    cmp rcx, '9'
    ja .done
    imul rax, rax, 10
    sub rcx, '0'
    add rax, rcx
    inc rdx
    jmp .loop
.done:
    ret

; Parse a signed decimal integer at rdi.  Return value in rax and consumed length in rdx.
parse_int:
    xor rax, rax
    xor rdx, rdx
    xor r8, r8
    cmp byte [rdi], '-'
    jne .loop
    mov r8, 1
    inc rdi
.loop:
    movzx rcx, byte [rdi + rdx]
    cmp rcx, '0'
    jb .finish
    cmp rcx, '9'
    ja .finish
    imul rax, rax, 10
    sub rcx, '0'
    add rax, rcx
    inc rdx
    jmp .loop
.finish:
    test rdx, rdx
    jz .failure
    test r8, r8
    jz .done
    neg rax
    inc rdx
.done:
    ret
.failure:
    xor rax, rax
    ret

; Copy rdi to the rsi buffer of rdx bytes, including its terminator.
; Return the string length, or zero if the buffer is too small.
string_copy:
    xor rax, rax
    test rdx, rdx
    jz .fail
.loop:
    mov r8b, [rdi + rax]
    test r8b, r8b
    jz .terminator
    lea rcx, [rax + 1]
    cmp rcx, rdx
    jae .fail
    mov [rsi + rax], r8b
    inc rax
    jmp .loop
.terminator:
    cmp rax, rdx
    jae .fail
    mov byte [rsi + rax], 0
    ret
.fail:
    xor rax, rax
    ret
