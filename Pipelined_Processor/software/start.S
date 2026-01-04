.section .text.init
.global _start

_start:
    li x1,  0
    li x2,  0
    li x3,  0
    li x4,  0
    li x5,  0
    li x6,  0
    li x7,  0
    li x8,  0
    li x9,  0
    li x10, 0
    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x18, 0
    li x19, 0
    li x20, 0
    li x21, 0
    li x22, 0
    li x23, 0
    li x24, 0
    li x25, 0
    li x26, 0
    li x27, 0
    li x28, 0
    li x29, 0
    li x30, 0
    li x31, 0

    la sp, _stack_top

    /* Interrupt Init */
    la t0, trap_handler
    csrw mtvec, t0
    /* mie.MEIE */
    li t0, 0x800
    csrs mie, t0
    /* mstatus.MIE */
    li t0, 0x8
    csrs mstatus, t0
    
    /* Clear BSS */
    la a0, _bss_start
    la a1, _bss_end

bss_clear_loop:
    beq a0, a1, bss_clear_done
    sw x0, 0(a0)
    addi a0, a0, 4
    j bss_clear_loop

bss_clear_done:
    call main
    
loop:
    j loop

.align 4
trap_handler:
    addi sp, sp, -128
    sw ra,  0(sp)
    sw t0,  4(sp)
    sw t1,  8(sp)
    sw t2,  12(sp)
    sw a0,  16(sp)
    sw a1,  20(sp)
    sw a2,  24(sp)
    sw a3,  28(sp)
    sw a4,  32(sp)
    sw a5,  36(sp)
    sw a6,  40(sp)
    sw a7,  44(sp)
    sw t3,  48(sp)
    sw t4,  52(sp)
    sw t5,  56(sp)
    sw t6,  60(sp)

    csrr a0, mcause
    li t1, 0x8000000B
    bne a0, t1, trap_exit

    call UART_ISR_Handler

trap_exit:
    lw ra,  0(sp)
    lw t0,  4(sp)
    lw t1,  8(sp)
    lw t2,  12(sp)
    lw a0,  16(sp)
    lw a1,  20(sp)
    lw a2,  24(sp)
    lw a3,  28(sp)
    lw a4,  32(sp)
    lw a5,  36(sp)
    lw a6,  40(sp)
    lw a7,  44(sp)
    lw t3,  48(sp)
    lw t4,  52(sp)
    lw t5,  56(sp)
    lw t6,  60(sp)
    addi sp, sp, 128
    mret
