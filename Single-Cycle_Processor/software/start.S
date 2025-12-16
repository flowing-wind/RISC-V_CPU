/* start.S */
.section .text
.global _start

_start:
    /* init sp (x2) */
    /* base: 0x2000, 4KB(0x1000) in all */
    li sp, 0x3000

    /* clear fp (x8) */
    li fp, 0

    /* jump to main */
    call main

loop:
    j loop
    