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
    xor rcx, rcx
..@string_equals_loop:
    mov dl, [rdi + rcx]
    cmp dl, [rsi + rcx]
    jne ..@string_equals_not_equal
    test dl, dl
    je ..@string_equals_equal
    inc rcx
    jmp ..@string_equals_loop
..@string_equals_equal:
    mov rax, 1
    ret
..@string_equals_not_equal:
    xor rax, rax
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
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    xor r14, r14
    test r13, r13
    jz .fail
    mov byte [r12], 0
.skip_whitespace:
    call read_char
    test rax, rax
    jz .fail
    cmp al, ' '
    je .skip_whitespace
    cmp al, 9
    je .skip_whitespace
    cmp al, 10
    je .skip_whitespace
.read_word:
    lea r8, [r14 + 1]
    cmp r8, r13
    jae .fail
    mov [r12 + r14], al
    inc r14
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
    mov rdx, r14
    mov rax, r12
    mov byte [rax + rdx], 0
    pop r14
    pop r13
    pop r12
    ret
.fail:
    xor rax, rax
    xor rdx, rdx
    pop r14
    pop r13
    pop r12
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
    sub rsp, 24
    xor r8, r8
    cmp byte [rdi], '-'
    je .negative
    cmp byte [rdi], '+'
    jne .parse
    mov r8, 1
    inc rdi
    jmp .parse
.negative:
    mov r8, -1
    inc rdi
.parse:
    mov [rsp], r8
    call parse_uint
    test rdx, rdx
    jz .failure
    cmp qword [rsp], -1
    jne .sign_consumed
    neg rax
.sign_consumed:
    cmp qword [rsp], 0
    je .done
    inc rdx
.done:
    add rsp, 24
    ret
.failure:
    xor rax, rax
    add rsp, 24
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
