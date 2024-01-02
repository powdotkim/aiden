KERNEL_MEMORY_HIGH_mask equ 0xFFFF000000000000
KERNEL_MEMORY_HIGH_REAL_address equ 0xFFFF800000000000
KERNEL_MEMORY_HIGH_VIRTUAL_address equ KERNEL_MEMORY_HIGH_REAL_address - KERNEL_MEMORY_HIGH_mask
KERNEL_MEMORY_MAP_SIZE_page equ 0x01
kernel_memory_map_address dq STATIC_EMPTY
kernel_memory_map_address_end dq STATIC_EMPTY

kernel_memory_lock_semaphore db STATIC_FALSE

kernel_memory_alloc_page_internal:
    push rsi
    mov rsi, qword [kernel_memory_map_address]
    call kernel_memory_lock
    test rbp, rbp
    jz .unreserved
    dec rbp
    inc qword [kernel_page_free_count]
    dec qword [kernel_page_reserved_count]
    jns .unreserved
    xchg bx, bx

    nop

    jmp $

.unreserved:
    call kernel_memory_alloc_page
    jc .error
    mov byte [kernel_memory_lock_semaphore], STATIC_FALSE
    add rdi, KERNEL_BASE_address

.error:
    pop rsi
    ret

kernel_memory_alloc_space_internal:
    push rsi
    mov rsi, qword [kernel_memory_map_address]
    call kernel_memory_lock
    call kernel_memory_alloc_space
    jc .error

    sub qword [kernel_page_free_count], rcx
    mov byte [kernel_memory_lock_semaphore], STATIC_FALSE

    add rdi, KERNEL_BASE_address
.error:
    pop rsi
    ret

kernel_memory_lock:
    macro_close kernel_memory_lock_semaphore, 0
    ret

kernel_memory_alloc_page:
    push rcx
    push rsi

    cmp qword [kernel_page_free_count], STATIC_EMPTY
    je .error
    
    dec qword [kernel_page_free_count]
    mov rcx, STATIC_STRUCTURE_BLOCK.link << STATIC_MULTIPLE_BY_8_shift
    xor edi, edi

.search:
    bt qword [rsi], rdi
    jc .found
    
    inc rdi
    cmp rdi, rcx
    jne .search

    xchg bx, bx
    nop
    jmp $

.found:
    btr qword [rsi], rdi
    shl rdi, STATIC_MULTIPLE_BY_PAGE_shift
    jmp .end

.error:
    stc

.end:
    pop rsi
    pop rcx

    ret

kernel_memory_alloc_space:
    push rax
    push rbx
    push rdx
    push rsi
    push rcx

    mov rax, STATIC_MAX_unsigned
    mov rcx, STATIC_STRUCTURE_BLOCK.link << STATIC_MULTIPLE_BY_8_shift

.reload:
    xor edx, edx

.search:
    inc rax
    cmp rax, rcx
    je .error

    bt qword [rsi], rax
    jnc .search

    mov rbx, rax

.check:
    inc rax
    inc rdx

    cmp rdx, qword [rsp]
    je .found

    cmp rax, rcx
    je .error

    bt qword [rsi], rax
    jc .check

    jmp .reload

.error:
    stc
    jmp .end

.found:
    mov rax, rbx

.lock:
    btr qword [rsi], rbx
    inc rbx
    dec rdx
    jnz .lock

    mov rdi, rax
    shl rdi, STATIC_MULTIPLE_BY_PAGE_shift

.end:
    pop rcx
    pop rsi
    pop rdx
    pop rbx
    pop rax
    ret