/* link.ld */
OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{
    /* FLASH  -->  code 4KB */
    FLASH (rx) : ORIGIN =0x00000000, LENGTH = 4K

    /* RAM  -->  data 4KB*/
    RAM (rw) : ORIGIN = 0x00002000, LENGTH = 4K
}

SECTIONS
{
    /* .text code, in Flash*/
    .text :
    {
        *(.text)
    } > FLASH

    /* .data data, in RAM*/
    .data :
    {
        *(.data)
    } > RAM

    /* .bss, uninitialized val, in RAM */
    .bss :
    {
        *(.bss)
    } > RAM
}
