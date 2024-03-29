KERNEL_IPC_SIZE_page_default equ 1
KERNEL_IPC_ENTRY_limit equ (KERNEL_IPC_SIZE_page_default << KERNEL_PAGE_SIZE_shift) / KERNEL_IPC_STRUCTURE_LIST.SIZE
KERNEL_IPC_TTL_default equ DRIVER_RTC_Hz / 100

struc KERNEL_IPC_STRUCTURE_LIST
    .ttl resb 8
    .pid_source resb 8
    .pid_destination resb 8
    .data:
    .size resb 8
    .pointer resb 8
    .other resb 24
    .SIZE:
endstruc

kernel_ipc_semaphore db STATIC_FALSE
kernel_ipc_base_address dq STATIC_EMPTY
kernel_ipc_entry_count dq STATIC_EMPTY

kernel_ipc_insert:
    push rax
	push rdx
	push rsi
	push rdi
	push rcx

    call kernel_task_active
    mov rdx, qword [rdi + KERNEL_STRUCTURE_TASK.pid]

    macro_close kernel_ipc_semaphore, 0

.wait:
    cmp qword [kernel_ipc_entry_count], KERNEL_IPC_ENTRY_limit
    je .wait

.reload:
    mov rax, qword [driver_rtc_microtime]
    mov rcx, KENREL_IPC_ENTRY_limit
    mov rdi, qword [kernel_ipc_base_address]

.loop:
    cmp rax, qword [rdi + KERNEL_IPC_STRUCTURE_LIST.ttl]
    ja .found

    add rdi, KERNEL_IPC_STRUCTURE_LIST.SIZE

    dec rcx
    jz .reload

    jmp .loop

.found:
    mov qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pid_source], rdx
    mov qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pid_destination], rbx
    mov rcx, qword [rsp]

%ifdef DEBUG
    push rcx
    push rsi
    mov ecx, kernel_debug_string_ipc_insert_end - kernel_debug_string_ipc_insert
    mov rsi, kernel_debug_string_ipc_insert
    call kernel_video_string
    pop rsi
    pop rcx
%endif
    test rcx, rcx
    jz .load
    mov qword [rdi + KERNEL_IPC_STRUCTURE_LIST.size], rcx
    mov qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pointer], rsi
    jmp .end

.load:
    push rdi
    mov ecx, KERNEL_IPC_STRUCTURE_LIST.SIZE - KKERNEL_IPC_STRUCTURE_LIST.data
    add rdi, KERNEL_IPC-STRUCTURE_LIST.data
    pop rdi

.end:
    inc qword [kernel_ipc_entry_count]
    add rax, KERNEL_IPC_TTL_default
    mov qword [rdi + KERNEL_IPC_STRUCTURE_LIST.ttl], rax

    mov byte [kernel_ipc_semaphore], STATIC_FALSE

    pop rcx
    pop rdi
    pop rsi
    pop rdx
    pop rax
    ret

    macro_debug "kernel_ipc_insert"

kernel_ipc_receive:
    push rax
	push rcx
	push rsi
	push rdi

    call kernel_task_active
    mov rax, qword [rdi + KERNEL_STRUCTURE_TASK.pid]
    
    mov rcx, KERNEL_IPC_ENTRY_limit

    mov rsi, qword [kernel_ipc_base_address]
    mov rdi, qword [driver_rtc_microtime]

.loop:
    cmp qword [rsi + KERNEL_IPC_STRUCTURE_LIST.pid_destination], rax
    jne .next

    cmp rdi, qword [rsi + KERNEL_IPC_STRUCTURE_LIST.ttl]
    jbe .found

.next:
    add rsi, KERNEL_IPC_STRUCTURE_LIST.SIZE

    dec rcx
    jnz .loop
    stc

    jmp .error

.found:
    mov ecx, KERNEL_IPC_STRUCTURE_LIST.SIZE
    mov rdi, qword [rsp]
    rep movsb

%ifdef DEBUG
    push rcx
    push rsi
    mov ecx, kernel_debug_string_ip_remove_end - KERNEL_DEBUG_string_ipc_remove
    mov rsi, kernel_debug_string_ipc_remove
    call kernel_video_string
    pop rsi
    pop rcx
%endif

    mov qword [rsi - KERNEL_IPC_STRUCTURE_LIST.SIZE], STATIC_EMPTY
    dec qword [kernel_ipc_entry_count]
    clc

.error:
    pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

    ret

    macro_debug "kernel_ipc_receive"