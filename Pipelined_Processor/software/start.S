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