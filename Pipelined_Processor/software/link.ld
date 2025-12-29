OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{
  BRAM (rwx) : ORIGIN = 0x00000000, LENGTH = 16K
}

SECTIONS
{
  . = 0x00000000;

  /* Code */
  .text : {
    *(.text.init)
    *(.text)
    *(.text.*)
    . = ALIGN(4);
  } > BRAM

  /* Read-Only Data */
  .rodata : {
    . = ALIGN(4);
    *(.rodata)
    *(.rodata.*)
    *(.srodata)
    *(.srodata.*)
    . = ALIGN(4);
  } > BRAM

  /* Data */
  .data : {
    . = ALIGN(4);
    *(.data)
    *(.data.*)
    *(.sdata)
    . = ALIGN(4);
  } > BRAM

  /* BSS */
  .bss : {
    . = ALIGN(4);
    _bss_start = .;
    *(.bss)
    *(.bss.*)
    *(.sbss)
    . = ALIGN(4);
    _bss_end = .;
  } > BRAM

  /* Stack Pointer */
  . = ORIGIN(BRAM) + LENGTH(BRAM);
  _stack_top = .;
  
}