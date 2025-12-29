MEMORY
{
    BOOTROM (rwx) : ORIGIN = 0x00000000, LENGTH = 4K
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
  } > BOOTROM

  /* Read-Only Data */
  .rodata : {
    . = ALIGN(4);
    *(.rodata)
    *(.rodata.*)
    *(.srodata)
    *(.srodata.*)
    . = ALIGN(4);
  } > BOOTROM

  /* Data */
  .data : {
    . = ALIGN(4);
    *(.data)
    *(.data.*)
    *(.sdata)
    . = ALIGN(4);
  } > BOOTROM

  /* BSS */
  .bss : {
    . = ALIGN(4);
    _bss_start = .;
    *(.bss)
    *(.bss.*)
    *(.sbss)
    . = ALIGN(4);
    _bss_end = .;
  } > BOOTROM

  /* Stack Pointer */
  . = ORIGIN(BOOTROM) + LENGTH(BOOTROM);
  _stack_top = .;
  
}